
#define MELT_TIME_MAX (15 SECONDS) // Melt time at maximum heat capacity (9)
#define MELT_TIME_MIN (1 SECONDS) // Melt time at minimum heat capacity (1)
#define MELT_TIME_SCALE ((MELT_TIME_MAX / MELT_TIME_MIN) ** (1/9)) // Heat capacity scaling (non-linear)
#define MELT_DURATION_HALFLIFE (15 SECONDS) // Melting time halves every X duration. Exposure to higher temperatures => Higher duration

// Effect that takes place when a meltable material is heated
/datum/statusEffect/melting
	id = "melting"
	name = "Melting"
	desc = "I'm melting! Melting! Oh, what a world!"
	icon_state = "melting"
	effect_quality = STATUS_QUALITY_NEGATIVE
	maxDuration = 60 SECONDS
	var/melt_time = 0 // Time until next melting event
	var/melt_time_mult = 1 // Adjust how fast things melt
	var/melt_material_count = 0 // Amount of material that has melted without turning into chunks

	preCheck(atom/A)
		if(isturf(src.owner) && !issimulatedturf(src.owner))
			return FALSE
		return ..()

	onAdd()
		..()
		if(ismob(src.owner))
			melt_time_mult *= 2
		else if(isobj(src.owner))
			if(isitem(src.owner))
				var/obj/item/I = src.owner
				if(I.max_stack == 1)
					melt_time_mult *= 3
			else
				melt_time_mult *= 3
		else if(isturf(src.owner))
			melt_time_mult *= 5
		src.melt_time = src.calc_melt_time()

		if(istype(src.owner, /obj/item/raw_material/ice))
			var/obj/item/raw_material/ice/ice_chunk = src.owner
			ice_chunk.is_melting = TRUE
			ice_chunk.UpdateIcon()
		else
			// Bit of a struggle to get this overlay to look acceptable
			var/image/melt_image = image('icons/obj/items/materials/ice.dmi', icon_state = "overlay_melt")
			melt_image.appearance_flags = PIXEL_SCALE | RESET_COLOR | RESET_ALPHA | KEEP_APART
			melt_image.blend_mode = BLEND_INSET_OVERLAY
			// src.owner.render_target = "*\ref[src.owner]"
			// melt_image.filters += alpha_mask_filter(render_source = src.owner.render_target)
			// src.owner.appearance_flags |= KEEP_TOGETHER
			owner.AddOverlays(melt_image, "status_melting")

	onUpdate(timePassed)
		..()
		if(!owner.material) // Nothing to melt
			owner.delStatus("melting")
			return

		var/melting_point = owner.material.getProperty("melting_point")
		var/temperature = src.get_temperature()
		if(temperature > melting_point)
			var/min_duration = ((temperature - melting_point) / 100 KELVIN) SECONDS + 5 SECONDS
			src.duration = max(src.duration, min_duration) // Keep melting if it is warm enough to melt
		src.melt_time -= timePassed

		if(src.melt_time > 0)
			return
		src.melt_time = src.calc_melt_time()
		if(ismob(src.owner))
			var/mob/M = src.owner
			melt_mob(M)
		else if(isobj(src.owner))
			var/obj/O = src.owner
			melt_obj(O)
		else if(isturf(src.owner))
			var/turf/T = src.owner
			melt_turf(T)

	onChange()
		..()
		// Update the melt time when exposed to heat
		var/new_melt_time = src.calc_melt_time()
		if(new_melt_time < src.melt_time)
			src.melt_time = new_melt_time

	onRemove()
		..()
		if(QDELETED(src.owner))
			return
		if(istype(src.owner, /obj/item/raw_material/ice))
			var/obj/item/raw_material/ice/ice_chunk = src.owner
			ice_chunk.is_melting = FALSE
			ice_chunk.UpdateIcon()
		else
			owner.ClearSpecificOverlays("status_melting")

	proc/get_temperature()
		var/datum/component/temperature_controlled/temperature_comp = src.owner.loc?.GetComponent(/datum/component/temperature_controlled)
		if(temperature_comp)
			return temperature_comp.temperature
		var/turf/T = get_turf(src.owner)
		return T.temperature

	proc/calc_melt_time()
		var/new_melt_time = MELT_TIME_MIN * (MELT_TIME_SCALE ** owner.material.getProperty("heat_capacity"))
		var/duration_scaling = 0.5 ** (src.duration / MELT_DURATION_HALFLIFE)
		new_melt_time *= duration_scaling // Melt faster at higher durations (exposed to higher temps)
		new_melt_time *= owner.material_amt * src.melt_time_mult
		return new_melt_time

	proc/drop_material(var/mat_amt)
		melt_material_count += mat_amt
		mat_amt = round(melt_material_count)
		melt_material_count -= mat_amt
		if(mat_amt <= 0)
			return
		var/turf/T = get_turf(src.owner)
		for (var/obj/item/raw_material/other in T.contents)
			if (src.owner.material.isSameMaterial(other.material))
				other.change_stack_amount(mat_amt)
				chaff.setStatus("melting", src.duration)
				return

		var/obj/item/chaff
		if(src.owner.material.getID() == "ice")
			chaff = new/obj/item/raw_material/ice(T)
		else
			chaff = new/obj/item/raw_material/scrap_metal(T)
			chaff.setMaterial(src.owner.material)
		// chaff.set_loc(T)
		if(mat_amt != 1)
			chaff.set_stack_amount(mat_amt)
		chaff.setStatus("melting", src.duration)

	proc/drop_reagents(var/melt_amt, var/datum/reagents/other = null)
		var/datum/reagents/meltReagents
		if(melt_amt > 0)
			meltReagents = src.owner.material.get_reagents(melt_amt)
			meltReagents.set_reagent_temp(src.owner.material.getProperty("melting_point") + 1 KELVIN, TRUE)
			other?.copy_to(meltReagents, copy_temperature = TRUE)
		else if(other)
			meltReagents = other
		if(!meltReagents)
			return

		var/turf/T = get_turf(src.owner)
		if(meltReagents && meltReagents.total_volume)
			meltReagents.reaction(T, TOUCH, meltReagents.total_volume)
		src.melt_material_count += src.owner.material_amt
		playsound(src.owner, 'sound/misc/splash_1.ogg', 40, TRUE)

	proc/melt_mob(var/mob/owner_mob)
		if(isdead(owner_mob))
			finish_melting()
		else
			owner_mob.TakeDamage("All", 0, 20, 0, DAMAGE_BURN)
			drop_material(2)
			if(prob(50))
				owner_mob.emote("scream")

	proc/melt_obj(var/obj/O)
		drop_reagents(O.material_amt, src.owner.reagents)
		if(!isitem(O))
			drop_material(O.material_amt)
			finish_melting()
			return
		var/obj/item/I = O
		if(istype(I, /obj/item/raw_material) || istype(I, /obj/item/material_piece))
			return
		drop_material(I.material_amt)
		if(I.amount == 1)
			finish_melting()
		else
			I.change_stack_amount(-1)

	proc/melt_turf(var/turf/T)
		if(istype(T, /turf/simulated/floor))
			var/turf/simulated/floor/sim_floor = T
			if(sim_floor.pryable)
				sim_floor.to_plating(TRUE)
				drop_reagents(T.material_amt)
			else
				sim_floor.ReplaceWithSpace()
		else
			drop_reagents(T.material_amt)
			T.ReplaceWithFloor()
		remove_self()

	proc/finish_melting()
		if(istype(src.owner, /obj/storage))
			var/obj/storage/S = src.owner
			if(S.spawn_contents && S.make_my_stuff()) // Make the stuff if the storage has not been opened yet.
				S.spawn_contents = null
		var/turf/T = get_turf(src.owner)
		for(var/atom/movable/AM in src.owner)
			AM.set_loc(T)
			if(!AM.material)
				continue
			var/melting_point = AM.material.getProperty("melting_point")
			if(melting_point && melting_point <= T.temperature)
				AM.setStatus("melting", src.duration)
		qdel(src.owner)

#undef MELT_TIME_MAX
#undef MELT_TIME_MIN
#undef MELT_TIME_SCALE
#undef MELT_DURATION_HALFLIFE

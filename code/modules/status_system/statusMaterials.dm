
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
		src.melt_time = src.calc_melt_time()

		if(istype(src.owner, /obj/item/raw_material/ice))
			var/obj/item/raw_material/ice/ice_chunk = src.owner
			ice_chunk.is_melting = TRUE
			ice_chunk.UpdateIcon()
		else
			// Bit of a struggle to get this overlay to look acceptable
			var/image/melt_image = image('icons/obj/items/materials/ice.dmi', icon_state = "overlay_melt")
			// melt_image.appearance_flags = PIXEL_SCALE | RESET_COLOR | RESET_ALPHA | KEEP_APART
			melt_image.blend_mode = BLEND_INSET_OVERLAY
			src.owner.appearance_flags |= KEEP_TOGETHER
			owner.AddOverlays(melt_image, "status_melting")

	onUpdate(timePassed)
		..()
		if(!owner.material) // Nothing to melt
			owner.delStatus("melting")
			return

		var/melting_point = owner.material.getProperty("melting_point")
		var/turf/T = get_turf(owner)
		if(owner.loc == T && T.temperature > melting_point)
			var/min_duration = ((T.temperature - melting_point) / 100 KELVIN) SECONDS + 5 SECONDS
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
		else if(T == src.owner) // isTurf(src.owner)
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

	proc/calc_melt_time()
		var/new_melt_time = MELT_TIME_MIN * (MELT_TIME_SCALE ** owner.material.getProperty("heat_capacity"))
		var/duration_scaling = 0.5 ** (src.duration / MELT_DURATION_HALFLIFE)
		new_melt_time *= duration_scaling // Melt faster at higher durations (exposed to higher temps)
		new_melt_time *= owner.material_amt * src.melt_time_mult
		return new_melt_time

	proc/melt_mob(var/mob/owner_mob)
		owner_mob.TakeDamage("All", 0, 20, 0, DAMAGE_BURN)
		var/obj/item/raw_material/ice/new_ice = new(get_turf(owner_mob))
		new_ice.change_stack_amount(1)
		new_ice.setStatus("melting", src.duration)
		playsound(owner_mob, 'sound/misc/splash_1.ogg', 50, TRUE)
		if(prob(50))
			owner_mob.emote("scream")

	proc/melt_obj(var/obj/O)
		var/datum/reagents/meltReagents = O.material.convert_reagents(O.material_amt)
		var/turf/T = get_turf(O)
		if(meltReagents && meltReagents.total_volume && T)
			meltReagents.reaction(T, TOUCH, meltReagents.total_volume)
		src.melt_material_count += O.material_amt
		playsound(O, 'sound/misc/splash_1.ogg', 50, TRUE)
		if(!isitem(O))
			if(src.melt_material_count >= 1)
				var/obj/item/raw_material/ice/new_ice = new(get_turf(src.owner))
				if(src.melt_material_count >= 2)
					new_ice.change_stack_amount(floor(src.melt_material_count) - 1)
				new_ice.setStatus("melting", src.duration)
			finish_melting()
			return
		var/obj/item/I = O
		if(src.melt_material_count >= 1 && !istype(I, /obj/item/raw_material) && !istype(I, /obj/item/material_piece))
			var/obj/item/raw_material/ice/new_ice = new(get_turf(src.owner))
			if(src.melt_material_count >= 2)
				new_ice.change_stack_amount(floor(src.melt_material_count) - 1)
			new_ice.setStatus("melting", src.duration)
			src.melt_material_count = src.melt_material_count - floor(src.melt_material_count)
		if(I.amount == 1)
			finish_melting()
		else
			I.change_stack_amount(-1)

	proc/melt_turf(var/turf/T)
		if(istype(T, /turf/simulated/floor))
			var/turf/simulated/floor/sim_floor = T
			sim_floor.pry_tile()
			if(sim_floor.intact)
				sim_floor.to_plating(TRUE)
			else
				sim_floor.ReplaceWithSpace()
		else
			T.ReplaceWithFloor()

	proc/finish_melting()
		if(istype(src.owner, /obj/storage))
			var/obj/storage/S = src.owner
			if(S.spawn_contents && S.make_my_stuff()) //Make the stuff when the locker is first opened.
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

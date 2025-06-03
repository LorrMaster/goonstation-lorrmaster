
#define MELT_TIME_MAX 30 SECONDS // Melt time at maximum heat capacity (9)
#define MELT_TIME_MIN 2 SECONDS // Melt time at minimum heat capacity (1)
#define MELT_TIME_SCALE ((MELT_TIME_MAX / MELT_TIME_MIN) ** (1/9)) // Heat capacity scale (non-linear)
#define MELT_MULT_DURATION 0.5 // Melt faster at maximum status effect duration

// Effect that takes place when a meltable material is heated
/datum/statusEffect/melting
	id = "melting"
	name = "Melting"
	desc = "I'm melting! Melting! Oh, what a world!"
	icon_state = "patho_oxy_speed"
	effect_quality = STATUS_QUALITY_NEGATIVE
	maxDuration = 600
	var/mob/owner_mob = null // owner if they are a mob
	var/melt_time = 5 SECONDS // Time until next melting event
	var/melt_time_mult = 1 // Adjust how fast things melt
	var/melt_material_count = 0 // Amount of material that has melted without turning into chunks

	onAdd()
		..()
		if(ismob(src.owner))
			src.owner_mob = src.owner
		else if(istype(src.owner, /obj/item/raw_material/ice))
			var/obj/item/raw_material/ice/ice_chunk = src.owner
			ice_chunk.is_melting = TRUE
			ice_chunk.UpdateIcon()
			return
		else
			melt_time_mult *= 2
		// Bit of a struggle to get this overlay to look acceptable
		var/image/melt_image = image('icons/obj/items/materials/ice.dmi', icon_state = "overlay_melt")
		melt_image.appearance_flags = PIXEL_SCALE | RESET_COLOR | RESET_ALPHA | KEEP_APART
		melt_image.blend_mode = BLEND_INSET_OVERLAY
		owner.AddOverlays(melt_image, "status_melting")

	onUpdate(timePassed)
		..()
		if(!owner.material) // Assume that there is a material for now
			owner.delStatus("melting")
			return

		var/melting_point = owner.material.getProperty("melting_point")
		var/turf/T = get_turf(owner)
		if(owner.loc == T && T.temperature > melting_point)
			src.duration = max(src.duration, 5 SECONDS) // Keep melting if it is warm enough to melt
		src.melt_time -= timePassed

		if(src.melt_time > 0)
			return
		src.melt_time = src.calc_melt_time()
		if(src.owner_mob)
			melt_mob()
		else if(isturf(src.owner))
			melt_turf(T)
		else if(isobj(src.owner))
			var/obj/O = src.owner
			melt_obj(O)

	onRemove()
		..()
		if(QDELETED(src.owner))
			return
		if(istype(src.owner, /obj/item/raw_material/ice))
			src.owner.UpdateIcon()
		else
			owner.ClearSpecificOverlays("status_melting")

	proc/melt_mob()
		src.owner_mob.TakeDamage("All", 0, 20, 0, DAMAGE_BURN)
		var/obj/item/raw_material/ice/new_ice = new(get_turf(src.owner_mob))
		new_ice.change_stack_amount(1)
		new_ice.setStatus("melting", src.duration)
		playsound(src.owner_mob, 'sound/misc/splash_1.ogg', 50, TRUE)
		if(prob(50))
			src.owner_mob.emote("scream")

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

	proc/calc_melt_time()
		var/new_melt_time = MELT_TIME_MIN * (MELT_TIME_SCALE ** owner.material.getProperty("heat_capacity"))
		new_melt_time *= owner.material_amt
		return new_melt_time

#undef MELT_TIME_MAX
#undef MELT_TIME_MIN
#undef MELT_TIME_SCALE
#undef MELT_MULT_DURATION

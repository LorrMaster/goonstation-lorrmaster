/atom
	var/tmp/list/fingerprints_full = null
	var/tmp/fingerprintslast = null
	var/tmp/blood_DNA = null
	var/tmp/blood_type = null

	// -------------------- New Stuff -----------
	var/datum/forensic_holder/forensic_holder = new()

/atom/movable
	var/tracked_blood = null // list(bDNA, btype, color, count)

/atom/proc/on_forensic_scan(var/datum/forensic_scan_builder2/scan_builder)
	if(src.reagents)
		src.reagents.forensic_scan_reagents(scan_builder)
	return
/atom/proc/add_evidence(var/datum/forensic_data/data, var/category = FORENSIC_GROUP_NOTE)
	if(src.forensic_holder)
		src.forensic_holder.add_evidence(data, category)
/atom/proc/add_fingerprint(mob/living/M, admin_only = FALSE, is_fake = FALSE, ignore_gloves = FALSE, ignore_sleuth = FALSE)
	if (!ismob(M) || isnull(M.key))
		return
	var/mob/living/carbon/human/H = M
	if(!H.limbs) // I don't think this should ever be the case?
		return

	var/datum/forensic_data/fingerprint/fp = new()
	// istype(H.r_hand, /obj/item/magtractor)
	if(H.hand == 0 && H.limbs.r_arm)
		if(isitemlimb(H.limbs.r_arm))
			return
		else
			fp.print = H.limbs.r_arm.limb_print
	else if(H.hand == 1 && H.limbs.l_arm)
		if(isitemlimb(H.limbs.l_arm))
			return
		else
			fp.print = H.limbs.l_arm.limb_print
	else
		return
	if(!fp.print)
		fp.print = H.bioHolder.fingerprint_default
		boutput(world, "Fingerprint not found.")

	if(H.gloves && !ignore_gloves)
		fp.glove_print = H.gloves.fiber_id
		fp.print_mask = H.gloves.fiber_mask
	ADD_FLAG(fp.flags, REMOVABLE_CLEANING)
	if(is_fake)
		ADD_FLAG(fp.flags, IS_JUNK)
	src.forensic_holder.last_fingerprint = fp.print
	src.forensic_holder.add_evidence(fp, FORENSIC_GROUP_FINGERPRINT, admin_only)
	if(M.mind && !ignore_sleuth)
		var/datum/forensic_data/basic/color_data = new(M.mind.color)
		ADD_FLAG(color_data.flags, REMOVABLE_CLEANING)
		src.forensic_holder.add_evidence(color_data, FORENSIC_GROUP_SLEUTH_COLOR)

/atom/proc/get_last_fingerprint()
	if(src.forensic_holder?.last_fingerprint)
		return src.forensic_holder.last_fingerprint.id
	return "?????"

/atom/proc/apply_blood(var/datum/bioHolder/source = null, var/blood_color = "#FFFFFF")
	if(!src.forensic_holder)
		return
	if(source)
		var/datum/forensic_id/dna_id = source.dna_signature
		var/datum/forensic_data/dna/dna_data = new(dna_id, DNA_FORM_BLOOD)
		src.forensic_holder.add_evidence(dna_data, FORENSIC_GROUP_DNA)
		src.forensic_holder.is_stained = TRUE
		src.forensic_holder.stain_color = blood_color
	if(isitem(src))
		apply_stain_effect(blood_color)
		var/datum/spreader_track/T = new()

		T.track_color = blood_color
		if(source)
			T.dna_signature = source.dna_signature
		src.forensic_holder.spreader = T

	/*
		else if (istype(src, /turf/simulated))
			if (istype(source, /mob/living))
				var/mob/living/L = source
				bleed(L, amount, 5, rand(1,3), src)
	*/

/atom/proc/apply_stain_effect(var/stain_color)
	if (isitem(src))
		var/obj/item/I = src
		var/image/blood_overlay = image('icons/obj/decals/blood/blood.dmi', "itemblood")
		blood_overlay.appearance_flags = PIXEL_SCALE | RESET_COLOR
		blood_overlay.color = stain_color
		blood_overlay.alpha = min(blood_overlay.alpha, 200)
		blood_overlay.blend_mode = BLEND_INSET_OVERLAY
		I.appearance_flags |= KEEP_TOGETHER
		I.UpdateOverlays(blood_overlay, "blood_splatter")
		if (istype(I, /obj/item/clothing))
			var/obj/item/clothing/C = src
			C.add_stain(/datum/stain/blood)

/atom/proc/clean_forensic()
	if(src.forensic_holder)
		if(src.forensic_holder.is_stained)
			src.forensic_holder.stain_color = null
			src.forensic_holder.is_stained = FALSE
		src.forensic_holder.remove_evidence(REMOVABLE_CLEANING)
	SEND_SIGNAL(src, COMSIG_ATOM_CLEANED)

/obj/clean_forensic()
	src.forensic_holder.spreader = null
	if(isitem(src))
		var/obj/item/I = src
		if(I.forensic_holder.is_stained)
			I.UpdateOverlays(null, "blood_splatter")
		if(istype(I, /obj/item/clothing))
			var/obj/item/clothing/C = I
			C.clean_stains()
			if (ishuman(src.loc))
				var/mob/living/carbon/human/H = src.loc
				H.set_clothing_icon_dirty()
	else if (istype(src, /obj/decal/cleanable) || istype(src, /obj/reagent_dispensers/cleanable))
		qdel(src)
	..()

/turf/clean_forensic()
	var/turf/T = get_turf(src)
	for (var/obj/decal/cleanable/mess in T)
		qdel(mess)
	T.messy = 0
	..()

/mob/clean_forensic()
	if (isobserver(src) || isintangible(src)) // Just in case.
		return
	src.remove_filter(list("paint_color", "paint_pattern")) //wash off any paint
	..()

/mob/living/clean_forensic()
	if(ishuman(src))
		var/mob/living/carbon/human/H = src
		var/list/gear_to_clean = list(H.r_hand, H.l_hand, H.head, H.wear_mask, H.w_uniform, H.wear_suit, H.belt, H.gloves, H.glasses, H.shoes, H.wear_id, H.back)
		// if (isnull(src.gloves))
		// 	gear_to_clean += src.r_hand
		// 	gear_to_clean += src.l_hand
		for (var/obj/item/check in gear_to_clean)
			check.clean_forensic()
		if (H.makeup || H.spiders)
			H.makeup = null
			H.makeup_color = null
			H.spiders = null
			H.set_body_icon_dirty()
		if (H.bioHolder.HasEffect("noir")) // Noir effect alters M.color, so reapply
			animate_fade_grayscale(H, 0)

	src.set_clothing_icon_dirty()
	src.tracked_blood = null
	..()

/atom/movable/proc/track_blood()
	return
/* needs adjustment so let's stick with mobs for now
/obj/track_blood()
	if (!islist(src.tracked_blood))
		return
	var/obj/decal/cleanable/blood/dynamic/B = locate(/obj/decal/cleanable/blood/dynamic) in get_turf(src)
	var/blood_color_to_pass = src.tracked_blood["color"] ? src.tracked_blood["color"] : DEFAULT_BLOOD_COLOR

	if (!B)
		B = make_cleanable( /obj/decal/cleanable/blood/dynamic(get_turf(src))
	B.add_volume(blood_color_to_pass, 1, src.tracked_blood, "smear3", src.last_move)

	src.tracked_blood["count"] --
	if (src.tracked_blood["count"] <= 0)
		src.tracked_blood = null
	return

/obj/item/track_blood()
	if (!islist(src.tracked_blood))
		return
	var/obj/decal/cleanable/blood/dynamic/B = locate(/obj/decal/cleanable/blood/dynamic) in get_turf(src)
	var/blood_color_to_pass = src.tracked_blood["color"] ? src.tracked_blood["color"] : DEFAULT_BLOOD_COLOR

	if (!B)
		B = make_cleanable( /obj/decal/cleanable/blood/dynamic(get_turf(src))
	var/Istate = src.w_class > 4 ? "3" : src.w_class > 2 ? "2" : "1"
	B.add_volume(blood_color_to_pass, 1, src.tracked_blood, Istate, src.last_move)

	src.tracked_blood["count"] --
	if (src.tracked_blood["count"] <= 0)
		src.tracked_blood = null
	return
*/
/mob/living/track_blood()
	if (!islist(src.tracked_blood))
		return
	if (HAS_ATOM_PROPERTY(src, PROP_MOB_BLOOD_TRACKING_ALWAYS) && (tracked_blood["count"] > 0))
		return
	if (HAS_ATOM_PROPERTY(src, PROP_ATOM_FLOATING))
		return
	var/turf/T = get_turf(src)
	if(istype_exact(T, /turf/space)) //can't smear blood on space
		return
	var/obj/decal/cleanable/blood/dynamic/tracks/B = null
	if (T.messy > 0)
		B = locate(/obj/decal/cleanable/blood/dynamic) in T

	var/blood_color_to_pass = src.tracked_blood["color"] ? src.tracked_blood["color"] : DEFAULT_BLOOD_COLOR

	if (!B)
		if (T.active_liquid)
			return
		B = make_cleanable(/obj/decal/cleanable/blood/dynamic/tracks, get_turf(src))
		if(isnull(src.tracked_blood))
			return
		B.set_sample_reagent_custom(src.tracked_blood["sample_reagent"], 0)

	var/list/states = src.get_step_image_states()

	if (states[1] || states[2])
		if (states[1])
			B.add_volume(blood_color_to_pass, src.tracked_blood["sample_reagent"], 0.5, 0.5, src.tracked_blood, states[1], src.last_move, 0)
		if (states[2])
			B.add_volume(blood_color_to_pass, src.tracked_blood["sample_reagent"], 0.5, 0.5, src.tracked_blood, states[2], src.last_move, 0)
	else
		B.add_volume(blood_color_to_pass, src.tracked_blood["sample_reagent"], 1, 1, src.tracked_blood, "smear2", src.last_move, 0)

	if(B.forensic_holder)
		if(ishuman(src))
			var/mob/living/carbon/human/H = src
			var/datum/forensic_data/multi/f_print = H.get_footprints(TIME)
			B.add_evidence(f_print, FORENSIC_GROUP_TRACKS)

	if (src.tracked_blood && isnum(src.tracked_blood["count"])) // mirror from below
		src.tracked_blood["count"] --
		if (src.tracked_blood["count"] <= 0)
			src.tracked_blood = null
			src.set_clothing_icon_dirty()
			return
	else
		src.tracked_blood = null
		src.set_clothing_icon_dirty()
		return

/mob/living/proc/get_step_image_states()
	return list("footprints[rand(1,2)]", null)

/mob/living/carbon/human/get_step_image_states()
	return src.limbs ? list(istype(src.limbs.l_leg) ? src.limbs.l_leg.step_image_state : null, istype(src.limbs.r_leg) ? src.limbs.r_leg.step_image_state : null) : list(null, null)

/mob/living/silicon/robot/get_step_image_states()
	return list(istype(src.part_leg_l) ? src.part_leg_l.step_image_state : null, istype(src.part_leg_r) ? src.part_leg_r.step_image_state : null)

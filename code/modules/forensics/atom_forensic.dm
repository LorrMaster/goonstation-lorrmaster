/atom
	var/tmp/list/fingerprints_full = null
	var/tmp/blood_DNA = null
	var/tmp/blood_type = null

	// -------------------- New Stuff -----------
	var/datum/forensic_holder/forensic_holder = new()
	var/tmp/fingerprintslast = null // keeping this for now, since the forensic_holder might be shared (like with the Bible)

/atom/proc/on_forensic_scan(var/datum/forensic_scan_builder/scan_builder)
	if(src.reagents)
		src.reagents.forensic_scan_reagents(scan_builder)

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
	src.fingerprintslast = M.key
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
	if(is_fake)
		ADD_FLAG(fp.flags, IS_JUNK)
	src.forensic_holder.add_evidence(fp, FORENSIC_GROUP_FINGERPRINT, admin_only)
	if(M.mind && !ignore_sleuth)
		var/datum/forensic_data/basic/color_data = new(M.mind.color, flags = REMOVABLE_CLEANING)
		src.forensic_holder.add_evidence(color_data, FORENSIC_GROUP_SLEUTH_COLOR)

/atom/proc/apply_blood(var/datum/bioHolder/source = null, var/blood_color = "#FFFFFF")
	if(!src.forensic_holder)
		return
	if(source)
		var/datum/forensic_id/dna_id = source.dna_signature
		var/datum/forensic_data/dna/dna_data = new(dna_id, DNA_FORM_BLOOD)
		src.forensic_holder.add_evidence(dna_data, FORENSIC_GROUP_DNA)

	/*
		else if (istype(src, /turf/simulated))
			if (istype(source, /mob/living))
				var/mob/living/L = source
				bleed(L, amount, 5, rand(1,3), src)
	*/

/atom/proc/clean_forensic()
	SEND_SIGNAL(src, COMSIG_ATOM_CLEANED)

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
	..()

/mob/living/proc/get_step_image_states()
	return list("footprints[rand(1,2)]", null)

/mob/living/carbon/human/get_step_image_states()
	return src.limbs ? list(istype(src.limbs.l_leg) ? src.limbs.l_leg.step_image_state : null, istype(src.limbs.r_leg) ? src.limbs.r_leg.step_image_state : null) : list(null, null)

/mob/living/silicon/robot/get_step_image_states()
	return list(istype(src.part_leg_l) ? src.part_leg_l.step_image_state : null, istype(src.part_leg_r) ? src.part_leg_r.step_image_state : null)

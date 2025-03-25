// i love enums
#define EVIDENCE_PLANT 0
#define EVIDENCE_READ 1
#define EVIDENCE_SCAN 2

/obj/item/device/fingerprinter
	name = "fingerprinter M2"
	desc = "A grey-market tool used for scanning and planting forensic evidence."
	icon_state = "reagentscan" // slightly sneaky. slightly.
	is_syndicate = TRUE
	w_class = W_CLASS_TINY
	var/mode = EVIDENCE_SCAN
	HELP_MESSAGE_OVERRIDE({"Toggle modes by using the fingerprinter in hand.
							Use <b>"Scan"</b> mode to scan a target for forensic evidence.
							Use <b>"Read"</b> mode to copy forensic evidence into the database."
							Use <b>"Plant"</b> mode to plant a piece of evidence onto a target."})
	var/list/list/datum/forensic_data/stored_leads = new()

	New()
		. = ..()
		RegisterSignal(src, COMSIG_ITEM_ATTACKBY_PRE, PROC_REF(pre_attackby)) // use this instead of afterattack so we're silent
		src.create_inventory_counter()
		src.update_text()

	attack_self(mob/user)
		. = ..()
		if (src.mode == EVIDENCE_PLANT)
			src.mode = EVIDENCE_SCAN
		else if(src.mode == EVIDENCE_READ)
			src.mode = EVIDENCE_PLANT
		else
			src.mode = EVIDENCE_READ
		src.update_text()

	proc/pre_attackby(obj/item/source, atom/target, mob/user)
		if (src.mode == EVIDENCE_PLANT)
			src.evidence_plant(user, target)
		else if(src.mode == EVIDENCE_READ)
			src.evidence_read(user, target)
		else
			src.evidence_scan(user, target)
		return TRUE // suppress attackby

	proc/evidence_scan(var/mob/user, var/atom/A)
		if (BOUNDS_DIST(A, user) > 0 || istype(A, /obj/ability_button)) // Scanning for fingerprints over the camera network is fun, but doesn't really make sense (Convair880).
			return
		if(!A.forensic_holder)
			return
		var/datum/forensic_scan_builder/scan = scan_forensic(A, user, FALSE)
		if(!scan)
			return
		var/last_scan = scan.build_report()
		boutput(user, last_scan)
		return

	proc/evidence_read(var/mob/user, var/atom/A)
		var/datum/forensic_scan_builder/scan = scan_forensic(A, user, FALSE, ignore_text = TRUE)
		if(!scan)
			return
		var/list/headers = scan.header_list
		// headers["Read all"] = "Read all"
		if(headers.len == 0)
			boutput(user, "No forensic evidence detected.")
		var/h_selected = tgui_input_list(user, "Select an evidence category", "Fingerprinter", headers)
		if (!h_selected)
			return
		// if(h_selected == "Read all")
		// 	return

		var/list/datum/forensic_data/data_list = scan.data_list[h_selected]
		var/list/datum/forensic_data/optionslist = new()
		for(var/i=1; i<= data_list.len; i++)
			var/txt = data_list[i].get_text()
			optionslist[txt] = data_list[i]
		var/d_selected = tgui_input_list(user, "Select evidence to copy:", "Fingerprinter", optionslist)
		var/datum/forensic_data/data = optionslist[d_selected]
		if (!data)
			return
		var/datum/forensic_data/f_data = data.get_copy()
		f_data.flags |= IS_JUNK
		if(!src.stored_leads[h_selected])
			src.stored_leads[h_selected] = new()
		src.stored_leads[h_selected] += f_data
		if(f_data.category == FORENSIC_GROUP_NONE)
			boutput(world, "Error: Category missing")

	proc/evidence_plant(mob/user, atom/target)
		// Plant the evidence
		if(src.stored_leads.len == 0)
			boutput(user, "No forensic data stored.")
		if(ishuman(target))
			var/mob/living/carbon/human/H = target
			var/new_target = evidence_plant_human(user, H)
			if(isatom(new_target))
				target = new_target
		if(!target)
			return
		var/l_selected = tgui_input_list(user, "Select an evidence category", "Fingerprinter", src.stored_leads)
		if (!l_selected)
			return
		var/list/datum/forensic_data/data_list = src.stored_leads[l_selected]
		var/list/datum/forensic_data/optionslist = new()
		for(var/i=1; i<= data_list.len; i++)
			var/txt = data_list[i].get_text()
			optionslist[txt] = data_list[i]
		var/d_selected = tgui_input_list(user, "Select evidence to copy:", "Fingerprinter", optionslist)
		var/datum/forensic_data/data = optionslist[d_selected]
		if (!data)
			return
		var/datum/forensic_data/f_data = data.get_copy()
		target.add_evidence(f_data, f_data.category)

	proc/evidence_plant_human(mob/user, mob/living/carbon/human/H) // Human forensics are made up of muliple items. Choose one.
		var/list/target_groups = new()
		var/list/atom/clothing_list = new()
		var/list/atom/body_parts_list = new()
		var/list/atom/organ_list = new()
		if(H.head) clothing_list["[H.head.name]"] = H.head
		if(H.wear_mask) clothing_list["[H.wear_mask.name]"] = H.wear_mask
		if(H.w_uniform) clothing_list["[H.w_uniform.name]"] = H.w_uniform
		if(H.wear_suit) clothing_list["[H.wear_suit.name]"] = H.wear_suit
		if(H.shoes) clothing_list["[H.shoes.name]"] = H.shoes
		if(H.gloves) clothing_list["[H.gloves.name]"] = H.gloves
		if(H.glasses) clothing_list["[H.glasses.name]"] = H.glasses
		if(H.ears) clothing_list["[H.ears.name]"] = H.ears
		if(H.wear_id) clothing_list["[H.wear_id.name]"] = H.wear_id
		if(H.back) clothing_list["[H.back.name]"] = H.back
		if(H.limbs?.r_arm) clothing_list["[H.limbs.r_arm.name]"] = H.limbs.r_arm
		if(H.limbs?.l_arm) clothing_list["[H.limbs.l_arm.name]"] = H.limbs.l_arm
		if(H.limbs?.r_leg) clothing_list["[H.limbs.r_leg.name]"] = H.limbs.r_leg
		if(H.limbs?.l_leg) clothing_list["[H.limbs.l_leg.name]"] = H.limbs.l_leg
		if(H.organHolder?.head) clothing_list["[H.organHolder.head.name]"] = H.organHolder.head
		if(H.organHolder?.chest) clothing_list["[H.organHolder.chest.name]"] = H.organHolder.chest
		if(H.organHolder?.butt)
			clothing_list["[H.organHolder.butt.name]"] = H.organHolder.butt
			organ_list["[H.organHolder.butt.name]"] = H.organHolder.butt

		if(H.organHolder)
			for (var/i in H.organHolder.organ_list)
				if (H.organHolder.organ_list[i])
					if(isatom(i))
						var/atom/A = i
						organ_list[A.name] += A

		var/atom/default_target = H.get_default_forensics_target()
		if(default_target) target_groups["[default_target.name]"] = default_target
		if(clothing_list.len > 0) target_groups["Clothing"] = clothing_list
		if(body_parts_list.len > 0) target_groups["Body Parts"] = body_parts_list
		if(organ_list.len > 0) target_groups["Organs"] = organ_list

		var/A_selected = tgui_input_list(user, "Select a target", "Fingerprinter", target_groups)
		if (!A_selected)
			return null
		if(isatom(A_selected))
			return A_selected
		var/list/atom/B_list = A_selected
		var/B_selected = tgui_input_list(user, "Select a target", "Fingerprinter", B_list)
		if (!B_selected || !isatom(B_selected))
			return null
		return B_selected

	proc/update_text()
		if (src.mode == EVIDENCE_READ)
			src.inventory_counter.update_text("<span style='color:#00ff00;font-size:0.7em;-dm-text-outline: 1px #000000'>READ</span>")
		else if (src.mode == EVIDENCE_PLANT)
			src.inventory_counter.update_text("<span style='color:#00ff00;font-size:0.7em;-dm-text-outline: 1px #000000'>PLANT</span>")
		else
			src.inventory_counter.update_text("<span style='color:#00ff00;font-size:0.7em;-dm-text-outline: 1px #000000'>SCAN</span>")

#undef EVIDENCE_PLANT
#undef EVIDENCE_READ
#undef EVIDENCE_SCAN

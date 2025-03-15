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
		var/datum/forensic_scan_builder2/scan = scan_forensic(A, user, FALSE)
		if(!scan)
			return
		var/last_scan = scan.build_report() // Moved to scanprocs.dm to cut down on code duplication (Convair880).
		boutput(user, last_scan)
		return

	proc/evidence_read(var/mob/user, var/atom/A)
		var/datum/forensic_scan_builder2/scan = scan_forensic(A, user, FALSE, ignore_text = TRUE)
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

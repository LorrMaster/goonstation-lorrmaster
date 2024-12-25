

// usr.visible_message(SPAN_ALERT("[scan_text]"))

datum/forensic_holder
	var/list/datum/forensic_group/evidence_list = new/list() // Forensic evidence is stored here
	var/list/datum/forensic_group/hidden_list = new/list() // Evidence that is only visible to admins
	var/timestamp_mult = 1.0 // Changes this item's timestamp accuracy. Lower the better.

	var/cannot_clean = FALSE // If true, prevents cleaning reagents from removing evidence
	var/is_stained = FALSE // Used to activate blood/stained overlay visuals
	var/stain_color = "#FFFFFF" // What color is the stain if it exists

	proc/scan_display(var/atom/A as turf|obj|mob, var/obj/item/device/detective_scanner/scanner = null)
		// Get all the evidence and put together the text of a forensic scan
		if(!A)
			return "No evidence found."
		var/datum/forensic_scan_builder/scan_builder = new()
		A.on_forensic_scan(scan_builder)
		if(evidence_list.len == 0 && scan_builder.scan_list.len == 0)
			return "No evidence found."

		for(var/i=1, i<= src.evidence_list.len, i++) // Add all the text to its correct list
			var/datum/forensic_group/ev_group = src.evidence_list[i]
			scan_builder.add_scan_text(ev_group.scan_text(scanner), ev_group.get_header())
		return scan_builder.assemble_scan()

	proc/get_group(var/category = FORENSIC_GROUP_NOTE, var/hidden = FALSE)
		// No longer needed. Change this to a dictionary lookup
		var/list/datum/forensic_group/E_list
		if(hidden)
			E_list = src.hidden_list
		else
			E_list = src.evidence_list
		var/datum/forensic_group/group = null
		for(var/i=1, i<= E_list.len, i++)
			if(E_list[i].category == category)
				group = E_list[i]
				break
		return group

	proc/remove_group(var/category = FORENSIC_GROUP_NONE)
		for(var/i=1, i<= src.evidence_list.len, i++)
			if(src.evidence_list[i].category == category)
				src.evidence_list.Cut(i, i+1)
				return

	proc/add_evidence(var/datum/forensic_data/data, var/category = FORENSIC_GROUP_NOTE, var/admin_only = FALSE)
		var/list/datum/forensic_group/E_list
		if(admin_only)
			E_list = src.hidden_list
		else
			E_list = src.evidence_list
		var/datum/forensic_group/group = get_group(category, admin_only)
		if(!group)
			group = forensic_group_create(category)
			E_list += group
		group.apply_evidence(data)

	proc/clean_evidence(var/removal_flags)
		if(cannot_clean || evidence_list.len == 0)
			return
		return



datum/forensic_scan_builder // Used to build the text for forensic scans
	var/list/datum/forensic_scan_holder/scan_list = new/list() // seperate text into their headers
	var/list/datum/forensic_holder/area_list = new/list() // additional sections to include in scan (worn gloves, pod interior, etc)
	var/list/area_header_list = new/list() // What the additional sections should be called
	var/is_admin = FALSE // Is this being analysed via admin commands?

	proc/add_scan_text(var/scan_text, var/header = "Notes", var/area = null)
		if(!scan_text)
			return
		var/datum/forensic_scan_holder/text_holder = null
		for(var/k=1, k<= src.scan_list.len, k++)
			if(cmptextEx(header, src.scan_list[k].header))
				text_holder = src.scan_list[k]
				break
		if(!text_holder)
			src.scan_list += new/datum/forensic_scan_holder(scan_text, header)
		else if(!text_holder.scan_text)
			text_holder.scan_text = scan_text // This should never happen, I think?
			usr.visible_message(SPAN_ALERT("The thing happened in forensic_holder. This is not an error."))
		else
			text_holder.scan_text += scan_text

	proc/additional_holder(var/list/datum/forensic_holder/area, var/area_header)
		// Used to scan more than one object at once, or seperate the scanned object into multiple regions
		// Examples: Scan worn gloves, fingerprint inside vs outside a pod, idk... scan every Bible at once?
		if(!area || !area_header) // Can probably do something with this case later. Ignore it for now.
			return
		src.area_list += area
		src.area_header_list += area_header

	proc/assemble_scan() // Put it all together
		var/scan_text_final = ""
		var/original_len = src.scan_list.len
		for(var/i=1, i<= original_len, i++)
			var/h = 1
			for(var/k=2, k<= src.scan_list.len, k++)
				if(!src.scan_list[k].get_order(src.scan_list[h].header))
					h = k
			scan_text_final += "<li>" + SPAN_NOTICE(src.scan_list[h].header) + ": </li>" + src.scan_list[h].scan_text
			src.scan_list.Cut(h, h+1)
		return scan_text_final

datum/forensic_scan_holder // Just used by forensic_scan_builder to store text for each header
	var/scan_text = ""
	var/header = null

	New(var/text, var/header)
		..()
		src.scan_text = text
		src.header = header

	proc/get_order(var/header_B) // Should this evidence be placed above or below this category?
		var/asc_dir = sorttext(src.header, header_B)
		if(asc_dir == 0)
			return TRUE // text is the same
		var/override_order = get_override_order(src.header) - get_override_order(header_B)
		if(override_order > 0)
			return TRUE
		else if(override_order < 0)
			return FALSE
		else
			return (asc_dir < 0) // Just sort alphabetically if an order is not specified

	proc/get_override_order(var/header_text) // For sorting headers non-alphabetically
		switch(header)
			if(HEADER_NOTES)
				return 10
			if(HEADER_FINGERPRINTS)
				return 200
			if(HEADER_DNA)
				return 180
			else
				return 100


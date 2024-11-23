

// usr.visible_message(SPAN_ALERT("[scan_text]"))

datum/forensic_holder
	var/list/datum/forensic_group/evidence_list = new/list()
	// var/forensics_blood_color = null

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
			scan_builder.add_scan_text(ev_group.scan_text(scanner), ev_group.category, ev_group.area)
		return scan_builder.assemble_scan()

	proc/add_evidence(var/datum/forensic_data/data, var/category = FORENSIC_CATEGORY_NOTE, var/area = null)
		var/datum/forensic_group/basic_list/group = null
		for(var/i=1, i<= evidence_list.len, i++)
			if(evidence_list[i].category == category && evidence_list[i].area == area)
				group = evidence_list[i]
				group.apply_evidence(data)
				return
		group = new()
		group.category = category
		group.area = area
		group.apply_evidence(data)
		evidence_list += group

	proc/add_fingerprint(var/datum/forensic_data/fingerprint/data, var/category = FORENSIC_CATEGORY_NOTE, var/area = null)
		var/datum/forensic_group/fingerprints/group = null
		for(var/i=1, i<= evidence_list.len, i++)
			if(evidence_list[i].category == category && evidence_list[i].area == area)
				group = evidence_list[i]
				group.apply_evidence(data)
				return
		group = new()
		group.apply_evidence(data)
		evidence_list += group

	proc/add_dna(var/datum/forensic_data/dna/data, var/area = null)
		var/datum/forensic_group/fingerprints/group = null
		for(var/i=1, i<= evidence_list.len, i++)
			if(evidence_list[i].category == FORENSIC_CATEGORY_DNA && evidence_list[i].area == area)
				group = evidence_list[i]
				group.apply_evidence(data)
				return

datum/forensic_scan_builder // Used to build the text for forensic scans
	var/list/datum/forensic_scan_holder/scan_list = new/list() // seperate text into categories to organize later

	proc/add_scan_text(var/scan_text, var/category = FORENSIC_CATEGORY_NOTE, var/area = null)
		if(!scan_text)
			return
		var/datum/forensic_scan_holder/scan_header = null
		for(var/k=1, k<= src.scan_list.len, k++)
			if(area == src.scan_list[k].area && category == src.scan_list[k].category)
				scan_header = src.scan_list[k]
				break
		if(!scan_header)
			scan_header = new()
			scan_header.area = area
			scan_header.category = category
			scan_header.scan_text = scan_text
			src.scan_list += scan_header
		else if(!scan_header.scan_text)
			scan_header.scan_text = scan_text
		else
			scan_header.scan_text += scan_text

	proc/assemble_scan() // Put it all together
		var/scan_text_final = ""
		for(var/i=1, i<= src.scan_list.len, i++)
			scan_text_final += get_header(src.scan_list[i].category) + src.scan_list[i].scan_text
		return scan_text_final

	proc/get_header(var/category)
		switch(category)
			if(FORENSIC_CATEGORY_NOTE)
				return SPAN_NOTICE("<li><b>Notes:</b></li>")
			if(FORENSIC_CATEGORY_FINGERPRINT)
				return SPAN_NOTICE("<li><b>Fingerprints:</b></li>")
			if(FORENSIC_CATEGORY_DNA)
				return SPAN_NOTICE("<li><b>DNA:</b></li>")
			if(FORENSIC_CATEGORY_SCAN)
				return SPAN_NOTICE("<li><b>Scanner Particles:</b></li>")
			if(FORENSIC_CATEGORY_COMPUTER_LOG)
				return SPAN_NOTICE("<li><b>Access Logs:</b></li>")
			else
				return SPAN_ALERT("<li><b>Header 404: Contact coder</b></li>")

datum/forensic_scan_holder // Just used by forensic_scan_builder
	var/scan_text = ""
	var/area = null
	var/category = FORENSIC_CATEGORY_NOTE

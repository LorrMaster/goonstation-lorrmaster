
#define FORENSIC_CATEGORY_NOTE 1
#define FORENSIC_CATEGORY_FINGERPRINT 2
#define FORENSIC_CATEGORY_DNA 3
#define FORENSIC_CATEGORY_SOURCE 4
#define FORENSIC_CATEGORY_SCAN 5
#define FORENSIC_CATEGORY_COMPUTER_LOG 6
// usr.visible_message(SPAN_ALERT("[scan_text]"))

datum/forensic_holder
	var/list/datum/forensic_group/evidence_list = new/list()
	var/forensics_blood_color = null

	proc/scan_display(var/atom/A as turf|obj|mob, var/emagged = FALSE)
		if(!evidence_list || !A)
			return "No evidence found."
		if(evidence_list.len == 0)
			return "No evidence found."
		var/list/datum/forensic_scan_holder/scan_holder = new/list() // seperate text into categories to organize later

		// Add all the text to its correct list
		for(var/i=1, i<= evidence_list.len, i++)
			var/datum/forensic_scan_holder/scan_header = null
			var/datum/forensic_group/ev_group = evidence_list[i]
			for(var/k=1, k< scan_holder.len, k++)
				if(ev_group.area == scan_holder[k].area && ev_group.category == scan_holder[k].category)
					scan_header = scan_holder[k]
					break
			var/ev_text = ev_group.scan_text(emagged)
			if(!scan_header)
				scan_header = new()
				scan_header.area = ev_group.area
				scan_header.category = ev_group.category
				scan_header.scan_text = ev_text
				scan_holder += scan_header
			else if(!scan_header.scan_text)
				scan_header.scan_text = ev_text
			else
				scan_header.scan_text += ev_text
		// Put it all together
		var/scan_text_final = ""
		for(var/i=1, i<= scan_holder.len, i++)
			scan_text_final += scan_holder[i].scan_text
		if(!scan_text_final)
			return "Dev Error 7305"
		if(length(scan_text_final) == 0)
			return "Dev Error 1720"
		return scan_text_final

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

datum/forensic_scan_holder
	var/scan_text = ""
	var/area = null
	var/category = FORENSIC_CATEGORY_FINGERPRINT

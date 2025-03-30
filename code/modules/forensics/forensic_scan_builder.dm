// Collect visible data from a scan, then assemble that scan into a text report
/datum/forensic_scan_builder
	var/datum/forensic_holder/holder
	var/datum/forensic_scan_builder/chain_scan = null // An additional scan to assemble after this one if it exists
	var/report_title = ""
	var/list/list/datum/forensic_data/data_list = new() // Collected forensic data (from the POV of the scanner)
	var/list/header_list = new() // List of headers (should probably loop through /list/list/data_list instead)

	var/base_accuracy = -1 // How accurate the time estimates are, or negative if not included by default
	var/is_admin = FALSE // Is this being analysed via admin commands?
	var/ignore_text = FALSE // Only collect actual forensic data (used for the fingerprinter)
	var/list/abridged_headers = list(HEADER_FINGERPRINTS, HEADER_DNA, HEADER_NOTES)

	var/filter_dna = null // Used to ignore the DNA of the mob you are scanning (unless it is blood DNA)
	var/filter_fingerprint_L = null // Used to ignore gloves / fingerprints from the player you are scanning
	var/filter_fingerprint_R = null
	var/filter_gloves = null

	New(var/atom/target, var/accuracy = -1, var/is_admin = FALSE, var/ignore_text = FALSE)
		src.holder = target?.forensic_holder
		src.report_title = "Forensic Analysis of \the [target]"
		src.base_accuracy = accuracy
		src.is_admin = is_admin
		src.ignore_text = ignore_text
		/*
		if(isitem(target))
			var/obj/item/I = target
			if(I.contraband)
				src.add_text("Contraband level [SPAN_ALERT(I.contraband)]", HEADER_NOTES)
		*/
		..()

	proc/add_data(var/datum/forensic_data/f_data, var/header = "Notes", var/category = FORENSIC_GROUP_NOTE)
		if(!data_list[header])
			data_list[header] = new()
		if(f_data)
			data_list[header] += f_data
		header_list[header] = header

	proc/add_text(var/scan_text, var/header = "Notes")
		if(ignore_text)
			return
		var/datum/forensic_data/text/t_data = new(scan_text)
		t_data.time_start = 0
		t_data.time_end = 0
		if(!data_list[header])
			data_list[header] = new()
		if(t_data)
			data_list[header] += t_data
		header_list[header] = header

	proc/add_holder(var/datum/forensic_holder/new_holder, var/title = null) // Use this to scan multiple items or regions
		if(!src.chain_scan)
			src.chain_scan = new(new_holder)
			if(title)
				src.chain_scan.report_title = title
		else
			chain_scan.add_holder(new_holder, title)
	proc/replace_holder(var/datum/forensic_holder/new_holder)
		src.holder = new_holder
	proc/replace_scan_target(var/atom/new_target)
		src.holder = new_target.forensic_holder
		new_target.on_forensic_scan(new_target)

	proc/include_abridged(var/header) // Include a header in abridged scans
		src.abridged_headers += header

	proc/collect_data() // Collect all the data associated with the scan
		holder.add_data_builder(src)
		if(src.chain_scan)
			src.chain_scan.collect_data()

	proc/build_report(var/is_abridged = FALSE, var/print_hyperlink = "") // Turn the data into a text report.
		var/list/h_list = src.header_list.Copy()
		var/list/abridged_list = new()
		for(var/i = 1; i<= length(h_list); i++)
			abridged_list[h_list[i]] = is_abridged && !src.abridged_headers.Find(h_list[i])
		var/report_text = ""
		// Pick a header. Turn all data under that header into text (if not abridged)
		var/h_count = length(h_list)
		for(var/i = 1; i<= h_count; i++)
			var/header = choose_header(h_list, abridged_list)
			var/section_text = ""
			if(is_abridged && abridged_list[header])
				var/readings = "readings"
				if(length(src.data_list[header]) == 1)
					readings = "reading"
				section_text = SPAN_HINT("<li>[header]: [length(src.data_list[header])] [readings]</li>")
			else
				section_text = SPAN_HINT("<li>[header]</li>") + data_to_text(src.data_list[header], is_abridged)
			report_text = report_text + section_text
		if(!report_text)
			report_text = "No evidence detected."
		//if(!is_abridged)
		//	report_text = "<li>[TIME]<li>" + [report_text]
		report_text = SPAN_SUCCESS("<li><b>[src.report_title]</b>[print_hyperlink]</li>") + report_text

		if(src.chain_scan)
			report_text += src.chain_scan.build_report(is_abridged)
		return report_text

	proc/data_to_text(var/list/datum/forensic_data/d_list, var/is_abridged = FALSE)
		var/text = ""
		for(var/i=1; i<= d_list.len; i++)
			var/d_text = d_list[i].get_text()
			if(d_list[i].accuracy_mult >= 0)
				d_text += " [d_list[i].get_time_estimate(d_list[i].accuracy_mult)]"
			if(!is_abridged && d_text)
				d_text = "<ul style='padding-left: 15px;'>[d_text]</ul>"
			if(d_text)
				text += "<li>[d_text]</li>"
		return text

	proc/choose_header(var/list/h_list, var/list/abridged_list)
		var/h_index = 1
		var/h_priority = header_priority(h_list[1], abridged_list[h_list[1]])
		for(var/i = 2; i<= length(h_list); i++)
			var/priority = header_priority(h_list[i], abridged_list[h_list[i]])
			if(priority < h_priority)
				h_index = i
				h_priority = priority
		var/header = h_list[h_index]
		h_list.Cut(h_index, h_index + 1)
		return header

	proc/header_priority(var/header, var/h_abridged)
		if(h_abridged)
			return 100
		switch(header)
			if(HEADER_FINGERPRINTS)
				return 20
			if(HEADER_DNA)
				return 30
			if(HEADER_SCANNER)
				return 60
			if(HEADER_NOTES)
				return 80
			else
				return 50


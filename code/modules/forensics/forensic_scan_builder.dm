// Data collected from a scan that can be assembled into a text report
/datum/forensic_scan_builder2
	var/datum/forensic_holder/holder
	var/datum/forensic_scan_builder2/chain_scan = null // Scan to assemble after this one
	var/report_title = ""
	var/list/list/datum/forensic_data/data_list = new()
	var/list/header_list = new()
	var/base_accuracy = -1 // How accurate the time estimates are, or negative if not included by default
	var/is_admin = FALSE // Is this being analysed via admin commands?

	New(var/atom/target, var/accuracy = -1, var/is_admin = FALSE)
		src.holder = target?.forensic_holder
		src.report_title = "Forensic Analysis of \the [target]"
		src.base_accuracy = accuracy
		src.is_admin = is_admin
		..()

	proc/add_data(var/datum/forensic_data/f_data, var/header = "Notes")
		if(!data_list[header])
			data_list[header] = new()
		if(f_data)
			data_list[header] += f_data
		header_list[header] = header

	proc/add_text(var/scan_text, var/header = "Notes")
		var/datum/forensic_data/text/t_data = new(scan_text)
		if(!data_list[header])
			data_list[header] = new()
		if(t_data)
			data_list[header] += t_data
		header_list[header] = header

	proc/add_holder(var/datum/forensic_holder/new_holder, var/title = null)
		if(!src.chain_scan)
			src.chain_scan = new(new_holder)
			if(title)
				src.chain_scan.report_title = title
		else
			chain_scan.add_holder(new_holder, title)

	proc/collect_data() // Collect all the data associated with the scan
		holder.add_data_builder(src)
		if(src.chain_scan)
			src.chain_scan.collect_data()

	proc/build_report() // Turn the data into a text report
		var/list/h_list = src.header_list.Copy()
		var/report_text = SPAN_BOLD(SPAN_SUCCESS("<li>[src.report_title]</li>"))
		// Pick a header. Turn all data under that header into text
		var/h_count = h_list.len
		for(var/i = 1; i<= h_count; i++)
			var/header = choose_header(h_list)
			report_text += SPAN_HINT("<li>[header]</li>") + data_to_text(data_list[header])
		if(src.chain_scan)
			report_text += src.chain_scan.build_report()
		return report_text

	proc/data_to_text(var/list/datum/forensic_data/d_list)
		var/text = ""
		for(var/i=1; i<= d_list.len; i++)
			var/d_text = d_list[i].get_text()
			if(d_list[i].accuracy_mult >= 0)
				d_text += " [d_list[i].get_time_estimate(d_list[i].accuracy_mult)]"
			if(d_text)
				text += "<li>[d_text]</li>"
		return text

	proc/choose_header(var/list/h_list)
		var/h_index = 1
		var/h_priority = header_priority(h_list[1])
		for(var/i = 2; i<= h_list.len; i++)
			var/priority = header_priority(h_list[i])
			if(h_priority < priority)
				h_index = i
				h_priority = priority
		var/header = h_list[h_index]
		h_list.Cut(h_index, h_index + 1)
		return header

	proc/header_priority(var/header)
		switch(header)
			if(HEADER_FINGERPRINTS)
				return 100
			if(HEADER_DNA)
				return 90
			if(HEADER_SCANNER)
				return 80
			if(HEADER_NOTES)
				return 20
			else
				return 50

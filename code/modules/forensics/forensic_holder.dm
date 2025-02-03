
// boutput(world, "Area Rest: [area_headers.len]")

// The forensic holder stores all the forensic evidence associated with whatever it is attached to
// The holder contains forensic groups, which are responsible for managing a specific type of evidence that may exist
// Forensic data within the groups represent an individual fingerprint, blood sample, bullet hole, or whatever else you want to store
datum/forensic_holder
	var/list/datum/forensic_group/evidence_list = new/list() // Forensic evidence is stored here
	var/list/datum/forensic_group/hidden_list = new/list() // Evidence that is only visible to admins (can probably be merged with above)
	var/datum/spreader_track/spreader = null // My lazy way of storing info for footprints
	var/accuracy_mult = 1.0 // Changes this item's timestamp accuracy. Lower the better.

	var/removal_flags_ignore = 0 // These ways of removing evidence have no power here
	var/no_fingerprints = FALSE // If true, figerprints are not allowed
	var/is_stained = FALSE // Used to activate blood/stained overlay visuals. Might want to move somewhere else
	var/stain_color = null // What color is the stain if it exists.

	proc/get_scan_text(var/datum/forensic_scan_builder/scan_builder)
		// Get all the evidence and put together the text of a forensic scan
		var/list/datum/forensic_group/ev_list = src.evidence_list
		if(scan_builder.is_admin)
			ev_list = src.hidden_list
		var/prev_accuracy = scan_builder.base_accuracy
		scan_builder.base_accuracy *= src.accuracy_mult
		for(var/i=1, i<= ev_list.len, i++) // Add all the text to its correct list
			var/datum/forensic_group/ev_group = ev_list[i]
			scan_builder.add_scan_text(ev_group.get_text(scan_builder), ev_group.get_header(), src, multi_line = TRUE)
		scan_builder.base_accuracy = prev_accuracy

	proc/get_group(var/category = FORENSIC_GROUP_NOTE, var/hidden = FALSE)
		// Should I change this to a dictionary lookup?
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

	proc/cut_group(var/category)
		for(var/i=1, i<= src.evidence_list.len, i++)
			if(src.evidence_list[i].category == category)
				src.evidence_list.Cut(i, i+1)
				return

	proc/add_evidence(var/datum/forensic_data/data, var/category = FORENSIC_GROUP_NOTE, var/admin_only = FALSE)
		if(!HAS_FLAG(data.flags, IS_JUNK))
			var/datum/forensic_group/h_group = get_group(category, TRUE)
			if(!h_group)
				h_group = forensic_group_create(category)
				src.hidden_list += h_group
			h_group.apply_evidence(data)
		if(!admin_only)
			var/datum/forensic_group/group = get_group(category, FALSE)
			if(!group)
				group = forensic_group_create(category)
				src.evidence_list += group
			group.apply_evidence(data)

	proc/remove_evidence(var/removal_flags) // Remove evidence marked with a flag. Should work with multiple flags as well.
		removal_flags = removal_flags & (~src.removal_flags_ignore)
		if(removal_flags == 0 || src.evidence_list.len == 0)
			return
		// Iterate backwards since groups can be removed
		for(var/i=src.evidence_list.len; i>= 1; i--)
			src.evidence_list[i].remove_evidence(src, removal_flags)
		return
	proc/remove_group(var/category, var/removal_flags = REMOVABLE_ALL)
		for(var/i=1, i<= src.evidence_list.len, i++)
			if(src.evidence_list[i].category == category)
				src.evidence_list[i].remove_evidence(src, removal_flags)
				return
	proc/move_evidence(var/datum/forensic_holder/target, var/move_flags = ~0)
		// TODO for merging two holders together
		return
	proc/copy_evidence(var/datum/forensic_holder/target, var/copy_flags = ~0)
		// TODO for when one thing becomes two things
		// copy_datum_vars()
		return
	proc/is_tracking() // Is this object spreading blood?
		return src.spreader != null
	proc/track_blood(turf/T, var/datum/forensic_data/multi/tracks = null)
		src.spreader.create_track(T, tracks)
		if(src.spreader.tracks_left == 0)
			qdel(src.spreader)
			src.spreader = null
	// proc/add_tracked_blood(var/b_dna, var/b_type, var/b_color, var/b_count, var/sample_reagent)
	proc/get_last_adminprint()
		// Return the key of the last player that placed a fingerprint on this object. Meant for admin use.
		var/datum/forensic_group/group = get_group(FORENSIC_GROUP_ADMINPRINT)
		if(!istype(group, /datum/forensic_group/adminprint))
			boutput(world, "Error: wrong type with FORENSIC_GROUP_ADMINPRINT")
			return null
		var/datum/forensic_group/adminprint/a_group = group
		return a_group.last_print.client


datum/forensic_scan_builder // Used to gather up all the evidence and assemble the text for forensic scans
	var/list/datum/forensic_header_data/scan_list = new/list() // seperate text into their headers
	var/list/datum/forensic_holder/area_list = new/list() // additional sections to include in scan (worn gloves, pod interior, etc)
	var/list/area_header_list = new/list() // What the additional sections should be called
	var/datum/forensic_holder/current_area = null // The current area that the builder is collecting evidence from
	var/obj/item/device/detective_scanner/scanner = null // The scanner being used, if there is one
	var/base_accuracy = -1 // How accurate the time estimates are, or negative if not included by default
	var/is_admin = FALSE // Is this being analysed via admin commands?

	proc/compile_scan(var/atom/scanned_atom)
		if(!scanned_atom)
			return
		src.current_area = scanned_atom.forensic_holder
		src.area_list += scanned_atom.forensic_holder
		src.area_header_list += SPAN_BOLD(SPAN_SUCCESS("Forensic Analysis of [scanned_atom]:"))
		scanned_atom.on_forensic_scan(src)
		for(var/i=1; i<= src.area_list.len; i++)
			src.current_area = src.area_list[i]
			src.current_area.get_scan_text(src)
		return assemble_scan()

	proc/add_scan_text(var/scan_text, var/header = "Notes", var/datum/forensic_holder/area = null, var/multi_line = FALSE)
		if(!scan_text)
			return
		if(!area)
			area = src.current_area
		if(!multi_line)
			scan_text = "<li>[scan_text]</li>"
		var/datum/forensic_header_data/text_holder = null
		for(var/k=1, k<= src.scan_list.len, k++)
			if(cmptextEx(header, src.scan_list[k].header) && src.scan_list[k].holder == area)
				text_holder = src.scan_list[k]
				break
		if(!text_holder)
			src.scan_list += new/datum/forensic_header_data(area, scan_text, header)
		else
			text_holder.scan_text += scan_text

	proc/assemble_scan() // Take all the scanned text and assemble them into a single report
		var/final_text = ""
		for(var/i=1; i<= src.area_list.len; i++)
			var/area_text = assemble_scan_area(src.area_list[i])
			final_text += "<li>[SPAN_SUCCESS(src.area_header_list[i])]</li>" + area_text
		return final_text

	proc/assemble_scan_area(var/datum/forensic_holder/area) //
		var/list/datum/forensic_header_data/area_headers = new/list() // Collect all the headers for this forensic_holder
		for(var/i=src.scan_list.len, i>= 1, i--)
			if(src.scan_list[i].holder == area)
				area_headers += src.scan_list[i]
				src.scan_list.Cut(i, i+1)
		var/area_text_final = ""
		var/original_len = area_headers.len
		for(var/i=1, i<= original_len, i++)
			var/h = 1
			for(var/k=2, k<= area_headers.len, k++)
				if(!area_headers[k].get_order(area_headers[h].header))
					h = k
			area_text_final += "[SPAN_NOTICE(area_headers[h].header)]:" + area_headers[h].scan_text
			area_headers.Cut(h, h+1)
		if(!area_text_final)
			area_text_final = "No evidence detected."
		return area_text_final

	proc/add_target(var/atom/target = null, var/area_header = null, var/datum/forensic_holder/area = null)
		// Used to scan more than one target, or seperate the scanned target into multiple regions
		// Examples: Scan worn gloves, fingerprints inside vs outside a pod, etc
		if(!target && (!area || !area_header))
			return
		if(!area)
			area = target.forensic_holder
		if(!area_header)
			area_header = "\The [target] analysis:"
		src.area_list += area
		src.area_header_list += area_header
		if(target) // New target can add evidence to the forensics builder directly. Optional.
			var/prev_area = src.current_area
			src.current_area = area
			target.on_forensic_scan(src)
			src.current_area = prev_area

datum/forensic_header_data // Just used by forensic_scan_builder to store text for each header seperately
	var/datum/forensic_holder/holder // The forensic_holder that this text is from
	var/scan_text = ""
	var/header = null

	New(var/holder, var/text, var/header)
		..()
		src.holder = holder
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

datum/spreader_track // Hopefully temp way for forensic holder to create tracks while walking.
	var/tracked_blood = null
	var/track_color = "#FFFFFFFF"
	var/datum/forensic_id/dna_signature = null
	var/tracks_left = 5
	var/static/datum/forensic_id/drag_machine_print = new("=====")
	var/static/datum/forensic_id/drag_item_print = new("-----")

	// Wishlist: Attach tracks to floor tiles


	proc/create_track(turf/T, var/datum/forensic_data/multi/footprint = null)
		if(istype_exact(T, /turf/space)) //can't smear blood on space
			return
		var/obj/decal/cleanable/blood/dynamic/tracks/B = null
		if (T.messy > 0)
			B = locate(/obj/decal/cleanable/blood/dynamic) in T
		if (!B)
			if (T.active_liquid)
				return
			B = make_cleanable(/obj/decal/cleanable/blood/dynamic/tracks, T)
		if(B.forensic_holder)
			if(footprint)
				B.add_evidence(footprint, FORENSIC_GROUP_TRACKS)
			else
				var/datum/forensic_data/multi/drag_print = new(src.drag_machine_print, src.drag_machine_print)
				B.add_evidence(drag_print, FORENSIC_GROUP_TRACKS)
			if(dna_signature)
				var/datum/forensic_data/dna/dna_data = new(dna_signature, DNA_FORM_BLOOD, TIME)
				B.add_evidence(dna_data, FORENSIC_GROUP_DNA)

		tracks_left--
		return

		/*
		var/list/states = src.get_step_image_states()

		if (states[1] || states[2])
			if (states[1])
				B.add_volume(src.stain_color, src.tracked_blood["sample_reagent"], 0.5, 0.5, src.tracked_blood, states[1], T, 0)
			if (states[2])
				B.add_volume(src.stain_color, src.tracked_blood["sample_reagent"], 0.5, 0.5, src.tracked_blood, states[2], T, 0)
		else
			B.add_volume(src.stain_color, src.tracked_blood["sample_reagent"], 1, 1, src.tracked_blood, "smear2", T, 0)
		*/

/mob/var/static/datum/forensic_id/drag_mob_print = new("~~~~~")

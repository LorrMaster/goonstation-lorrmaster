
// boutput(world, "Area Rest: [area_headers.len]")

// The forensic holder stores all the forensic evidence associated with whatever it is attached to
// The holder contains forensic groups, which are responsible for managing a specific type of evidence that may exist
// Forensic data within the groups represent an individual fingerprint, blood sample, bullet hole, or whatever else you want to store
datum/forensic_holder
	var/list/datum/forensic_group/evidence_list = new/list() // Forensic evidence is stored here
	var/list/datum/forensic_group/hidden_list = new/list() // Evidence that is only visible to admins
	var/accuracy_mult = 1.0 // Multiplier for this item's timestamp accuracy. Lower the better.
	var/last_ckey = null
	var/datum/spreader_track/spreader = null // My lazy way of storing info for footprints

	var/removal_flags_ignore = 0 // These ways of removing evidence have no power here
	var/suppress_scans = FALSE // If true, then this will block attempts to scan it
	var/is_stained = FALSE // Used to activate blood/stained overlay visuals. Might want to move somewhere else
	var/stain_color = null // What color is the stain if it exists.

	proc/add_data_builder(var/datum/forensic_scan_builder/scan_builder)
		// Get all the evidence and put together the text of a forensic scan
		var/list/datum/forensic_group/ev_list = src.evidence_list
		if(scan_builder.is_admin)
			ev_list = src.hidden_list
		var/prev_accuracy = scan_builder.base_accuracy
		scan_builder.base_accuracy *= src.accuracy_mult
		for(var/i=1, i<= ev_list.len, i++) // Add all the text to its correct list
			var/datum/forensic_group/ev_group = ev_list[i]
			ev_group.get_scan_evidence(scan_builder)
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
		data.category = category
		if(!HAS_FLAG(data.flags, IS_JUNK))
			var/datum/forensic_group/h_group = get_group(category, TRUE)
			if(!h_group)
				h_group = forensic_group_create(category)
				src.hidden_list += h_group
			h_group.apply_evidence(data.get_copy())
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

	proc/copy_evidence(var/datum/forensic_holder/target, var/copy_flags = ~0) // Copy evidence from this holder to another
		for (var/i=1; i<= length(src.evidence_list); i++)
			var/list/datum/forensic_data/f_data_list = src.evidence_list[i].get_evidence_list(TRUE)
			for(var/k=1; k<= length(f_data_list); k++)
				target.add_evidence(f_data_list[k].get_copy(), src.evidence_list[i].category)

	proc/is_tracking() // Is this object spreading blood?
		return src.spreader != null
	proc/track_blood(turf/T, var/datum/forensic_data/multi/tracks = null)
		src.spreader.create_track(T, tracks)
		if(src.spreader.tracks_left == 0)
			qdel(src.spreader)
			src.spreader = null
	// proc/add_tracked_blood(var/b_dna, var/b_type, var/b_color, var/b_count, var/sample_reagent)

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

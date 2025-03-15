
/*
Forensic Holder -> All the different types of forensics on an object
Forensic Group -> All the fingerprints on an object
Forensic Data -> A fingerprint
*/

#define FINGERPRINTS_MAX 7
#define FINGERPRINTS_COOLDOWN 10

ABSTRACT_TYPE(/datum/forensic_group)
/datum/forensic_group
	// Photographic Analysis, Audio Analysis

	var/category = FORENSIC_GROUP_NONE // An identifier for the group type. Must be unique for each group.
	var/group_flags = 0 // Flags associated with the whole group. If EVIDENCE_REMOVABLE_CLEANING is true,
						// then evidence in that group may (or may not!) be removable via cleaning
	var/group_accuracy = 1

	proc/apply_evidence(var/datum/forensic_data/data) // Add a piece of evidence to this group
		return
	proc/get_evidence_list(var/include_trace = FALSE)
		return null
	proc/get_scan_evidence(var/datum/forensic_scan_builder2/scan_builder)
		return
	proc/get_header() // The label that this evidence will be displayed under for scans
		return SPAN_ALERT("Error: Forensic scan header not found")
	proc/remove_evidence(var/datum/forensic_holder/parent, var/removal_flags)
		return
	proc/matching_flags(var/flags_A, var/flags_B)
		return (flags_A & !IS_JUNK) == (flags_B & !IS_JUNK)

/datum/forensic_group/notes
	category = FORENSIC_GROUP_NOTE
	group_flags = REMOVABLE_CLEANING | REMOVABLE_DATA
	var/list/datum/forensic_data/basic/notes_list = new/list()

	apply_evidence(var/datum/forensic_data/data)
		if(istype(data, /datum/forensic_data/basic))
			var/datum/forensic_data/basic/E = data
			apply_basic(E)

	get_evidence_list(var/include_trace = FALSE)
		return src.notes_list

	get_scan_evidence(var/datum/forensic_scan_builder2/scan_builder)
		var/scan_accuracy = src.group_accuracy * scan_builder.base_accuracy
		for(var/i=1, i<= src.notes_list.len; i++)
			var/datum/forensic_data/f_data = src.notes_list[i].get_copy()
			f_data.accuracy_mult *= scan_accuracy
			scan_builder.add_data(f_data, get_header(), src.category)

	get_header()
		return HEADER_NOTES

	remove_evidence(var/datum/forensic_holder/parent, var/removal_flags)
		for(var/i=1, i<= src.notes_list.len; i++)
			if(src.notes_list[i].should_remove(removal_flags))
				src.notes_list.Cut(i, i+1)

	proc/apply_basic(var/datum/forensic_data/basic/E)
		for(var/i=1, i<= notes_list.len; i++)
			if(E.evidence == src.notes_list[i].evidence && matching_flags(E.flags, src.notes_list[i].flags))
				notes_list[i].time_end = TIME
				return
		src.notes_list += E

/datum/forensic_group/basic_list
	var/list/datum/forensic_data/basic/evidence_list = new/list()

	apply_evidence(var/datum/forensic_data/data)
		if(!istype(data, /datum/forensic_data/basic))
			return
		var/datum/forensic_data/basic/E = data

		var/oldest = 1
		for(var/i=1, i<= evidence_list.len; i++)
			if(E.evidence == src.evidence_list[i].evidence)
				evidence_list[i].time_end = TIME
				return
			if(evidence_list[i].time_end < evidence_list[oldest].time_end)
				oldest = i
		if(src.evidence_list.len < 7)
			src.evidence_list += E
		else
			var/datum/D = src.evidence_list[oldest]
			src.evidence_list[oldest] = E
			qdel(D)

	get_evidence_list(var/include_trace = FALSE)
		return src.evidence_list

	remove_evidence(var/datum/forensic_holder/parent, var/removal_flags)
		for(var/i=1, i<= src.evidence_list.len; i++)
			if(src.evidence_list[i].should_remove(removal_flags))
				src.evidence_list.Cut(i, i+1)

	get_scan_evidence(var/datum/forensic_scan_builder2/scan_builder)
		var/scan_accuracy = src.group_accuracy * scan_builder.base_accuracy
		for(var/i=1, i<= src.evidence_list.len; i++)
			var/datum/forensic_data/f_data = src.evidence_list[i].get_copy()
			f_data.accuracy_mult *= scan_accuracy
			scan_builder.add_data(f_data, get_header(), src.category)

/datum/forensic_group/basic_list/scanner
	category = FORENSIC_GROUP_SCAN
	group_flags = REMOVABLE_CLEANING
	group_accuracy = 0.75

	get_header()
		return HEADER_SCANNER

/datum/forensic_group/basic_list/damage // Evidence of wounds / general damage & destruction
	category = FORENSIC_GROUP_DAMAGE
	group_flags = REMOVABLE_ALL
	group_accuracy = 1
	// Trace evidence: ???

	remove_evidence(var/datum/forensic_holder/parent, var/removal_flags)
		for(var/i=1, i<= src.evidence_list.len; i++)
			if(src.evidence_list[i].should_remove(removal_flags))
				ADD_FLAG(src.evidence_list[i].flags, IS_TRACE) // Mark as trace instead of outright removing for now
	get_header()
		return HEADER_DAMAGE

/datum/forensic_group/basic_list/sleuth_color
	category = FORENSIC_GROUP_SLEUTH_COLOR
	group_flags = REMOVABLE_CLEANING

	get_evidence_list(var/include_trace = FALSE)
		return null
	get_header()
		return "Sleuth"
	get_scan_evidence(var/datum/forensic_scan_builder2/scan_builder)
		return
	proc/get_sleuth_text(var/atom/A)
		var/data_text = ""
		var/sleuth_accuracy = 0.35
		for(var/i=1, i<= src.evidence_list.len; i++)
			var/color = src.evidence_list[i].evidence.id
			var/time_since = TIME - src.evidence_list[i].time_end
			var/time = src.evidence_list[i].get_time_estimate(sleuth_accuracy)
			var/c_text
			if(i == 1)
				var/list/intensity_list = list("faintly","acutely","strongly","mildly","kind","trace")
				var/list/time_since_list = list(0, rand(4,6), rand(8,12), rand(27,33), rand(41,49), rand(55,65))
				var/intensity = get_intensity(intensity_list, time_since_list, time_since)
				c_text = "\The [A] smells [intensity] of a [color]."
			else
				var/list/intensity_list = list("a faint","an acute","a strong","a mild","kind of a","a trace")
				var/list/time_since_list = list(0, rand(4,6), rand(8,12), rand(27,33), rand(41,49), rand(55,65))
				var/intensity = get_intensity(intensity_list, time_since_list, time_since)
				var/scent = pick("scent", "hint", "taste", "aroma", "fragrance")
				var/detect = pick("detect","notice","note","find","pick up","smell","locate","track","discover","acertain","inhale","sense")
				c_text = "You also [detect] [intensity] [scent] of [color]."
			data_text += "<li>[SPAN_NOTICE(c_text)] [time]</li>"
		return data_text
	proc/get_intensity(var/list/intensity_list, var/list/time_since_list, var/time_since)
		for(var/i=2, i<= intensity_list.len; i++)
			if(time_since < time_since_list[i] MINUTES)
				return intensity_list[i]
		return intensity_list[1]

/datum/forensic_group/multi_list // Two or three pieces of evidence grouped together
	var/list/datum/forensic_data/multi/evidence_list = new/list()

	apply_evidence(var/datum/forensic_data/data)
		if(!istype(data, /datum/forensic_data/multi))
			return
		var/datum/forensic_data/multi/E = data

		var/oldest = 1
		for(var/i=1, i<= evidence_list.len; i++)
			if(src.evidence_list[i].is_same(E))
				evidence_list[i].time_end = TIME
				return
			if(evidence_list[i].time_end < evidence_list[oldest].time_end)
				oldest = i
		if(src.evidence_list.len < 7)
			src.evidence_list += E
		else
			var/datum/D = src.evidence_list[oldest]
			src.evidence_list[oldest] = E
			qdel(D)

	get_evidence_list(var/include_trace = FALSE)
		return src.evidence_list

	remove_evidence(var/datum/forensic_holder/parent, var/removal_flags)
		for(var/i=1, i<= src.evidence_list.len; i++)
			if(src.evidence_list[i].should_remove(removal_flags))
				src.evidence_list.Cut(i, i+1)

	get_scan_evidence(var/datum/forensic_scan_builder2/scan_builder)
		var/scan_accuracy = src.group_accuracy * scan_builder.base_accuracy
		for(var/i=1, i<= src.evidence_list.len; i++)
			var/datum/forensic_data/f_data = src.evidence_list[i].get_copy()
			f_data.accuracy_mult *= scan_accuracy
			scan_builder.add_data(f_data, get_header(), src.category)

/datum/forensic_group/multi_list/footprints
	category = FORENSIC_GROUP_TRACKS
	group_flags = REMOVABLE_CLEANING

	get_header()
		return "Footprints"

/datum/forensic_group/multi_list/retinas
	category = FORENSIC_GROUP_RETINA
	group_flags = REMOVABLE_DATA
	group_accuracy = 0

	get_header()
		return "Retina Scans"

/datum/forensic_group/multi_list/log_health_floor // Floor health scanner stores footprints & dna from scanned patients
	category = FORENSIC_GROUP_HEALTH_FLOOR
	group_flags = REMOVABLE_DATA
	group_accuracy = 0

	get_header()
		return @"Scan Log: DNA | Footprints"

/datum/forensic_group/multi_list/log_health_analyzer // Health analyzer stores retina & dna from scanned patients
	category = FORENSIC_GROUP_HEALTH_ANALYZER
	group_flags = REMOVABLE_DATA
	group_accuracy = 0

	get_header()
		return @"Scan Log: DNA | Retina Scan"

/datum/forensic_group/fingerprints
	category = FORENSIC_GROUP_FINGERPRINT
	group_flags = REMOVABLE_CLEANING
	group_accuracy = 1.25
	var/list/datum/forensic_data/fingerprint/prints_list = list()
	var/iodine_time = 0
	var/silver_nitrate_time = 0

	apply_evidence(var/datum/forensic_data/data)
		if(!istype(data, /datum/forensic_data/fingerprint))
			return
		var/datum/forensic_data/fingerprint/fp = data

		var/oldest = 1
		for(var/i=1, i<= src.prints_list.len; i++)
			if(src.prints_list[i].is_same(fp))
				return
			if(src.prints_list[i].time_end < src.prints_list[oldest].time_end)
				oldest = i

		if(src.prints_list.len < FINGERPRINTS_MAX)
			src.prints_list += fp
		else
			var/datum/D = src.prints_list[oldest]
			src.prints_list[oldest] = fp
			qdel(D)

	get_evidence_list(var/include_trace = FALSE)
		return src.prints_list

	remove_evidence(var/datum/forensic_holder/parent, var/removal_flags)
		if(HAS_ANY_FLAGS((src.group_flags & REMOVABLE_ALL), removal_flags))
			prints_list = null
			parent.cut_group(category)

	get_scan_evidence(var/datum/forensic_scan_builder2/scan_builder)
		var/scan_accuracy = src.group_accuracy * scan_builder.base_accuracy
		if(iodine_time > TIME)
			scan_accuracy *= 0.7
		for(var/i=1, i<= src.prints_list.len; i++)
			var/datum/forensic_data/fingerprint/f_data = src.prints_list[i].get_copy()
			var/filtered = (f_data.print == scan_builder.filter_fingerprint_R) && f_data.print && !f_data.glove_print
			filtered = filtered || (f_data.print == scan_builder.filter_fingerprint_L) && f_data.print && !f_data.glove_print
			filtered = filtered || (f_data.print == null && f_data.glove_print == scan_builder.filter_gloves)
			if(!filtered)
				f_data.accuracy_mult *= scan_accuracy
				if(silver_nitrate_time <= TIME && f_data.print_mask && !scan_builder.is_admin)
					f_data.print = null
				scan_builder.add_data(f_data, get_header(), src.category)

	get_header()
		return HEADER_FINGERPRINTS

/datum/forensic_group/dna // blood and other forms of DNA evidence
	category = FORENSIC_GROUP_DNA
	group_flags = REMOVABLE_CLEANING
	var/list/datum/forensic_data/dna/dna_list = list()
	var/list/datum/forensic_data/dna/dna_trace_list = list() // Blood evidence that requires luminol to detect
	var/luminol_time = 0 // Time when the luminol was will stop being effective, or zero if not applied

	apply_evidence(var/datum/forensic_data/data)
		if(!istype(data, /datum/forensic_data/dna))
			return
		var/datum/forensic_data/dna/E = data
		var/list/datum/forensic_data/dna/ev_list = null
		if(HAS_FLAG(data.flags, IS_TRACE))
			ev_list = dna_trace_list
		else
			ev_list = dna_list

		var/oldest = 1
		for(var/i=1, i<= ev_list.len; i++)
			if(ev_list[i].is_same(E))
				ev_list[i].time_end = TIME
				return
			if(ev_list[i].time_end < ev_list[oldest].time_end)
				oldest = i
		if(ev_list.len < 7)
			ev_list += E
		else
			var/datum/D = ev_list[oldest]
			ev_list[oldest] = E
			qdel(D)

	get_evidence_list(var/include_trace = FALSE)
		if(include_trace)
			return src.dna_list + src.dna_trace_list
		return src.dna_list

	remove_evidence(var/datum/forensic_holder/parent, var/removal_flags)
		if(!HAS_ANY_FLAGS((src.group_flags & REMOVABLE_ALL), removal_flags))
			return
		for(var/i=src.dna_list.len, i>= 1; i--)
			var/datum/forensic_data/dna/E = src.dna_list[i]
			src.dna_list.Cut(i, i+1)
			if(E.form == DNA_FORM_BLOOD)
				ADD_FLAG(E.flags, IS_TRACE)
				apply_evidence(E) // reapply this blood evidence as trace evidence
		if(dna_list.len == 0 && dna_trace_list.len == 0)
			parent.cut_group(category)

	get_scan_evidence(var/datum/forensic_scan_builder2/scan_builder)
		var/scan_accuracy = src.group_accuracy * scan_builder.base_accuracy
		for(var/i=1, i<= src.dna_list.len; i++)
			var/datum/forensic_data/f_data = src.dna_list[i].get_copy()
			f_data.accuracy_mult *= scan_accuracy
			scan_builder.add_data(f_data, get_header(), src.category)
		if(luminol_time > TIME)
			for(var/i=1, i<= src.dna_trace_list.len; i++)
				var/datum/forensic_data/f_data = src.dna_trace_list[i].get_copy()
				f_data.accuracy_mult *= scan_accuracy * 2
				scan_builder.add_data(f_data, get_header(), src.category)

	get_header()
		return HEADER_DNA

	proc/contains_blood(var/include_trace = FALSE)
		for(var/i=1; i<= src.dna_list.len; i++)
			if(src.dna_list[i].form == DNA_FORM_BLOOD)
				return TRUE
		if(include_trace == FALSE)
			return FALSE
		for(var/i=1; i<= src.dna_trace_list.len; i++)
			if(src.dna_trace_list[i].form == DNA_FORM_BLOOD)
				return TRUE
		return FALSE



// Need a scanner proc to handle item-specific notes
// Mob fingerprints/DNA, source ID, safe hints

/*
Forensic Holder -> All the different types of forensics on an object
Forensic Group -> All the fingerprints on an object / area
Forensic Data -> A fingerprint
*/

#define FINGERPRINTS_MAX 7
#define FINGERPRINTS_COOLDOWN 10

ABSTRACT_TYPE(/datum/forensic_group)

datum/forensic_group
	var/category = FORENSIC_CATEGORY_NOTE
	var/removable = TRUE
	var/area = null // Some objects might have additional types of evidence for specific areas (inside vs outside a pod)

	proc/apply_evidence(var/datum/forensic_data/data)
		return
	proc/scan_text(var/obj/item/device/detective_scanner/scanner)
		return ""

datum/forensic_group/basic_list
	var/list/datum/forensic_data/basic/evidence_list = new/list()
	var/datum/forensic_data/basic/last = null

	apply_evidence(var/datum/forensic_data/data)
		var/datum/forensic_data/basic/E = data
		if(!src.last)
			src.evidence_list += E
			src.last = E
			return
		else if(src.last.evidence == E.evidence)
			src.last.timestamp = TIME
			return
		var/oldest = 1 // Might as well find the oldest print while we're at it
		for(var/i=1, i<= evidence_list.len; i++)
			if(E.evidence == evidence_list[i].evidence)
				evidence_list[i].timestamp = TIME
				src.last = evidence_list[i]
				return
			if(evidence_list[i].timestamp < evidence_list[oldest].timestamp)
				oldest = i
		if(src.evidence_list.len < 7)
			src.evidence_list += E
			src.last = E
		else
			var/datum/D = src.evidence_list[oldest]
			src.evidence_list[oldest] = E
			src.last = E
			qdel(D)
	scan_text(var/obj/item/device/detective_scanner/scanner)
		var/data_text = ""
		for(var/i=1, i<= src.evidence_list.len; i++)
			data_text += "<li>" + src.evidence_list[i].scan_display(0) + "</li>"
		return data_text

datum/forensic_group/fingerprints
	category = FORENSIC_CATEGORY_FINGERPRINT
	var/list/datum/forensic_data/fingerprint/prints_list = list()
	var/datum/forensic_data/fingerprint/last = null

	apply_evidence(var/datum/forensic_data/data)
		var/datum/forensic_data/fingerprint/fp = data
		if(!src.last)
			src.prints_list += fp
			src.last = fp
			return
		else if(fp.print == src.last.print && fp.glove_print == src.last.glove_print)
			src.last.timestamp = TIME
			return

		// Check to see if the fp already exists here
		var/oldest = 1 // Might as well find the oldest print while we're at it
		for(var/i=1, i<= src.prints_list.len; i++)
			if(fp.print == prints_list[i].print && fp.glove_print == src.prints_list[i].glove_print)
				src.prints_list[i].timestamp = TIME
				src.last = prints_list[i]
				return
			if(src.prints_list[i].timestamp < src.prints_list[oldest].timestamp)
				oldest = i

		if(src.prints_list.len < FINGERPRINTS_MAX)
			src.prints_list += fp
			src.last = fp
		else
			var/datum/D = src.prints_list[oldest]
			src.prints_list[oldest] = fp
			src.last = fp
			qdel(D)

	scan_text(var/obj/item/device/detective_scanner/scanner)
		var/fp_text = ""
		for(var/i=1, i<= prints_list.len; i++)
			fp_text += "<li>" + prints_list[i].scan_display(scanner, 0) + "</li>"
		return fp_text



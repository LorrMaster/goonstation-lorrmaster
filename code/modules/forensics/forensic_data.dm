#define FORENSIC_CHARS_UP "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
#define FORENSIC_CHARS_LOW "abcdefghijklmnopqrstuvwxyz"
#define FORENSIC_CHARS_NUM "1234567890"
#define FORENSIC_CHARS_DNA "CGAT"
#define FORENSIC_CHARS_ALL (FORENSIC_CHARS_UP + FORENSIC_CHARS_LOW + FORENSIC_CHARS_NUM)

// -----| Forensic ID & Display |-----

datum/forensic_id // Basically just a way to store forensic text by reference
	var/id = null

	New(var/id_text = null)
		..()
		id = id_text

	proc/build_id(var/id_length, var/character_list = FORENSIC_CHARS_ALL)
		var/new_id = ""
		var/len = length(character_list)
		for(var/i=1, i<= id_length, i++)
			new_id += character_list[rand(1, len)]
		return new_id

	proc/build_scanner_id(var/scanner_prefix)
		// prefix examples: FRNSIC-XXXXX | REAGNT-XXXXX | ATMOS-XXXXX | DEVICE-XXXXX | HEALTH-XXXXX |
		//					TRNSPRT-XXXXX | RCD-XXXXX | PDA-XXXXX | APRAISE-XXXXX | GENE-XXXXX
		if(!scanner_prefix)
			scanner_prefix = "UNKNOWN"
		var/scanner_id = build_id(5, FORENSIC_CHARS_NUM)
		src.id = (scanner_prefix + "-" + scanner_id)

	proc/build_fingerprint_id(var/has_adermatoglyphia = FALSE)
		if(has_adermatoglyphia)
			return null // genetic condition where you do not have fingerprints
		var/fp = ""
		for(var/i=1, i<= 5, i++)
			if(i != 1)
				fp += "-"
			fp += build_id(5, FORENSIC_CHARS_LOW)
		src.id = fp

datum/forensic_display // Store how the forensic text should be displayed... by reference!
	var/display_text = null

	New(var/id_text = null)
		..()
		display_text = id_text

// -----| Forensic Data |-----

// DNA: blood, hair, tissue, bone

//
ABSTRACT_TYPE(/datum/forensic_data)
datum/forensic_data
	var/timestamp = 0 // What time the evidence was applied, or 0 if not relavent

	proc/get_evidence()
		return null
	proc/scan_display(var/timestamp_type)
		return ""

datum/forensic_data/basic // Evidence that can just be stored as a single ID
	var/datum/forensic_id/evidence = null
	var/datum/forensic_display/display = null

	var/static/datum/forensic_display/disp_empty = new("@F")

	New(var/datum/forensic_id/id = null, var/datum/forensic_display/disp = disp_empty, var/tstamp = 0)
		..()
		src.evidence = id
		src.display = disp
		src.timestamp = tstamp
	get_evidence()
		return evidence.id
	scan_display(var/timestamp_type)
		var/scan_text = replacetext(display.display_text, "@F", evidence.id)
		var/time_text = null
		if(timestamp == 0)
			time_text = ""
		else
			time_text = "TTTTT"
		scan_text = replacetext(scan_text, "@T", time_text)
		return scan_text

datum/forensic_data/fingerprint // An individual fingerprint applied to an item
	var/datum/forensic_id/print = null // The original fingerprint
	var/datum/forensic_id/glove_print = null // The glove fibres & ID
	var/datum/forensic_id/print_mask = null // The mask that the gloves apply to the print
	// (insulative fibers: xxxxxx) | (black fibers: xxxxxx) | ()
	// xxxxx-xxxxx-xxxxx-xxxxx-xxxxx
	// ...??-??a??-?g?...

	get_evidence() // return the fingerprint + glove id
		if(!glove_print)
			return print.id
		var/fingerprint_text = get_print()
		if(!fingerprint_text)
			return glove_print.id
		return fingerprint_text + " " + glove_print.id
	scan_display(var/timestamp_type)
		usr.visible_message(SPAN_ALERT("F: [print.id]"))
		var/fp = get_print()
		if(!glove_print)
			return fp
		return fp + " (insulative fibers - Glove ID: xxxxxxx)"


	proc/get_print() // return the fingerprint, which could be obscured by gloves
		// MASK:	~~~~/-=--##-/~~
		// 		/: Ignore everything outside of brackets
		// 		-: Value is hidden (replaced with a dash)
		// 		=: Value is shown
		// 		#: Value is randomized
		if(!print_mask)
			return print.id
		else if(!print)
			return ""
		var/final_print = print.id
		var/start_index = 0
		var/end_index = length(print)
		var/k = 1
		for(var/i=1, i<=length(print_mask) && k<=length(print), i++)
			switch(print_mask[i])
				if("?")
					final_print[k] = "?"
				if("#")
					// randomize
				if("/")
					if(start_index == 0)
						start_index = k
					else
						end_index = k+1
						break
				if("-")
					final_print[k] = "-"
			k++
		if(!final_print)
			return "Dev Error 5274"
		final_print = copytext(final_print, start_index, end_index)
		if(start_index != 1 || end_index != length(print))
			final_print = "..." + final_print + "..."
		return final_print;

datum/forensic_data/dna
	var/datum/forensic_id/print = null
	var/datum/forensic_display/display = null
	var/decomposition = 0

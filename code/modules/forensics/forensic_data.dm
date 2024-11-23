
#define FINGERPRINT_BUNCH_SIZE 5 // Number of characters between each "-"
#define FINGERPRINT_LENGTH 25 // Must be a multiple of FINGERPRINT_DASH
#define FINGERPRINT_BUNCH_COUNT (FINGERPRINT_LENGTH / FINGERPRINT_BUNCH_SIZE)

// -----| Forensic ID & Display |-----

datum/forensic_id // Basically just a way to store forensic text by reference
	var/id = null

	New(var/length = 0, var/chars = null, var/id_prefix = "", var/id_suffix = "", var/length = 0)
		..()
		if(length == 0)
			src.id = id_prefix + id_suffix
		else
			var/scanner_id = build_id(length, chars)
			src.id = (id_prefix + scanner_id + id_suffix)

	proc/build_id(var/id_length, var/character_list = FORENSIC_CHARS_ALL)
		var/new_id = ""
		var/len = length(character_list)
		for(var/i=1, i<= id_length, i++)
			new_id += character_list[rand(1, len)]
		return new_id

	proc/build_fingerprint_id(var/has_adermatoglyphia = FALSE)
		if(has_adermatoglyphia)
			return null // genetic condition where you do not have fingerprints
		var/fp = ""
		for(var/i=1, i<= FINGERPRINT_BUNCH_COUNT, i++)
			if(i != 1)
				fp += "-"
			fp += build_id(FINGERPRINT_BUNCH_SIZE, FORENSIC_CHARS_FP)
		src.id = fp
	proc/build_glove_mask(var/peek_range = 0, var/peek_count = 0)
		// 000?? ?xx?? ??000 00000 00000 ==> "...?? ?xx?? ??..."
		// peek_range: number of values & question marks
		// peek_count: number of values to reveal
		if(peek_range == 0 || peek_count == 0)
			return null
		if(peek_range > FINGERPRINT_LENGTH)
			peek_range = FINGERPRINT_LENGTH
		if(peek_count > peek_range)
			peek_count = peek_range

		// Why is this empty???
		var/mask = ""
		var/hide_count = FINGERPRINT_LENGTH - peek_range
		var/peek_start = rand(0, hide_count) + 1
		for(var/i=1, i< peek_start, i++)
			mask += "0"
		for(var/i=peek_start, i< peek_range + peek_start, i++)
			mask += "?"
		if(peek_count == 1)
			var/index = rand(1,peek_range) - 1
			mask = replacetext(mask, "?", "x", peek_start + index, peek_start + index + 1)
		else
			var/list/rand_list = new/list()
			for(var/i=0, i< peek_range, i++)
				rand_list += i
			for(var/i=1, i<= peek_count, i++)
				var/index = rand(1, rand_list.len)
				mask = replacetext(mask, "?", "x", peek_start + rand_list[index], peek_start + rand_list[index] + 1)
				rand_list.Cut(index)
		for(var/i=peek_range + peek_start, i<= FINGERPRINT_LENGTH, i++)
			mask += "0"
		src.id = mask

	proc/build_dna()
		return "F849-K912-P912-V982-M002"



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
	proc/scan_display(var/obj/item/device/detective_scanner/scanner, var/timestamp_type)
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
	scan_display(var/obj/item/device/detective_scanner/scanner, var/timestamp_type)
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
	// 000?? ?xx?? ??000 00000 00000
	// ...??-??a??-?g?...

	get_evidence() // return the fingerprint + glove id
		if(!glove_print)
			return print.id
		var/fingerprint_text = get_print()
		if(!fingerprint_text)
			return glove_print.id
		return fingerprint_text + " " + glove_print.id
	scan_display(var/obj/item/device/detective_scanner/scanner, var/timestamp_type)
		var/fp = get_print()
		if(!glove_print)
			return fp
		return fp + " (Glove ID: [glove_print.id])"


	proc/get_print() // return the fingerprint, which could be obscured by gloves
		if(!print)
			return ""
		else if(!print_mask)
			return print.id
		var/final_print = "..."
		var/bunch_char = 0
		var/bunch_num = 0
		var/last_shown = FALSE // Used for inserting the hyphens
		for(var/i=1, i<= FINGERPRINT_LENGTH, i++)
			switch(copytext(print_mask.id, i, i+1))
				if("?")
					if(last_shown && bunch_char == 0)
						final_print += "-"
					final_print += "?"
					last_shown = TRUE
				if("x")
					if(last_shown && bunch_char == 0)
						final_print += "-"
					final_print += copytext(print.id, i + bunch_num, i + bunch_num + 1)
					last_shown = TRUE
				else
					last_shown = FALSE
			bunch_char++
			if(bunch_char >= FINGERPRINT_BUNCH_SIZE)
				bunch_char = 0
				bunch_num++
		return final_print + "...";

datum/forensic_data/dna
	var/datum/forensic_id/print = null
	var/datum/forensic_id/form = null
	var/datum/forensic_display/display = null
	var/decomposition = 0

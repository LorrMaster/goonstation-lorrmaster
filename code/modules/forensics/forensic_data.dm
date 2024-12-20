
#define FINGERPRINT_BUNCH_SIZE 5 // Number of characters between each "-"
#define FINGERPRINT_BUNCH_COUNT 5
#define FINGERPRINT_LENGTH FINGERPRINT_BUNCH_SIZE * FINGERPRINT_BUNCH_COUNT

#define DNA_BUNCH_SIZE 5
#define DNA_BUNCH_COUNT 4
#define DNA_LENGTH DNA_BUNCH_SIZE * DNA_BUNCH_COUNT

// -----| Forensic ID & Display |-----

datum/forensic_id // Mainly a way to store forensic text by reference
	var/id = null

	New(var/length = 0, var/list/char_list = null, var/id_prefix = "", var/id_suffix = "")
		..()
		if(length == 0 || !char_list)
			src.id = id_prefix + id_suffix
		else
			var/scanner_id = build_id(length, char_list)
			src.id = (id_prefix + scanner_id + id_suffix)

	proc/build_id(var/id_length, var/list/char_list = CHAR_LIST_NUM)
		var/new_id = ""
		for(var/i=1, i<= id_length, i++)
			new_id += char_list[rand(1, char_list.len)]
		return new_id

	proc/build_id_fingerprint(var/has_adermatoglyphia = FALSE)
		var/fp = ""
		if(!has_adermatoglyphia)
			fp += build_id(FINGERPRINT_BUNCH_SIZE, CHAR_LIST_FINGERPRINT)
			for(var/i=1, i<= FINGERPRINT_BUNCH_COUNT - 1, i++)
				fp += "-" + build_id(FINGERPRINT_BUNCH_SIZE, CHAR_LIST_FINGERPRINT)
		else
			// has_adermatoglyphia ==> condition where you do not have fingerprints
			var/no_fp_bunch = ""
			for(var/i=1, i<= FINGERPRINT_BUNCH_SIZE, i++)
				no_fp_bunch += "O"
			fp += no_fp_bunch
			for(var/i=1, i<= FINGERPRINT_BUNCH_COUNT - 1, i++)
				fp += "-" + no_fp_bunch
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

	proc/build_id_dna()
		// GAD53-JDA09-HAW23-TAS29 -hair- (23-34 mins ago)
		var/dna_id = ""
		for(var/i=1, i<= DNA_BUNCH_COUNT, i++)
			if(i != 1)
				dna_id += "-"
			dna_id += build_id(3, CHAR_LIST_UPPER_LIMIT) + build_id(DNA_BUNCH_SIZE - 3, CHAR_LIST_NUM)
		src.id = dna_id

	proc/build_id_footprint(var/list/pattern)
		// The footprint pattern determines which symbols are swapped with what
		// l = letter, s = symbol, h = high heels, other = no change
		var/list/letters_list = CHAR_LIST_LOWER
		var/list/symbols_list = CHAR_LIST_SYMBOLS
		var/final_id = ""
		for(var/i=1, i< pattern.len, i++)
			var/char = copytext(pattern, i, i+1)
			switch(char)
				if("l")
					final_id += letters_list[rand(1, letters_list.len)]
				if("s")
					final_id += symbols_list[rand(1, symbols_list.len)]
				if("h") // high heels
					var/list/heel_list = list("o","+","#","a","c","n","u","=","v","x","z","e","<",">")
					final_id += heel_list[rand(1, heel_list.len)]
				else
					final_id += char
		src.id = final_id

	proc/build_id_retina(var/list/outer_L, var/list/outer_R, var/list/center_list, var/outer_count = 2)
		// ([O>] [<O])
		var/retina = ""
		for(var/i=1, i<= outer_count, i++)
			var/out_char = rand(1, outer_L.len)
			retina += outer_L[out_char]
		retina += center_list[rand(1, center_list.len)]
		for(var/i=1, i<= outer_count, i++)
			var/out_char = rand(1, outer_R.len)
			retina += outer_R[out_char]
		src.id = retina
	proc/get_retina_mirror()
		// Returns a mirrored version of the text.
		// Used for retina symmetry
		var/retina = src.id
		if(!retina)
			return ""
		var/mirror = ""
		for(var/i=length(retina), i>=1, i--)
			var/char = copytext(retina, i, i+1)
			switch(char)
				if(@"(")
					char = @")"
				if(@")")
					char = @"("
				if(@"[")
					char = @"]"
				if(@"]")
					char = @"["
				if(@"{")
					char = @"}"
				if(@"}")
					char = @"{"
				if(@"<")
					char = @">"
				if(@">")
					char = @"<"
				if(@"/")
					char = @"\"
				if(@"\")
					char = @"/"
			mirror += char
		return mirror

datum/forensic_display // Store how the forensic text should be displayed... by reference! Might be unnecessary.
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
	// Note: change timestamp to time_start & time_end. Should be more accurate & interesting.
	var/flags = 0

	proc/scan_display(var/obj/item/device/detective_scanner/scanner, var/timestamp_type)
		return ""

datum/forensic_data/basic // Evidence that can just be stored as a single ID. Flags not included.
	var/static/datum/forensic_display/disp_empty = new("@F")
	var/datum/forensic_id/evidence = null
	var/datum/forensic_display/display = null

	New(var/datum/forensic_id/id, var/datum/forensic_display/disp = disp_empty, var/tstamp = 0)
		..()
		src.evidence = id
		src.display = disp
		src.timestamp = tstamp
	scan_display(var/obj/item/device/detective_scanner/scanner, var/timestamp_type)
		// Ignore: if(timestamp == 0)
		// Exact: [80 mins ago]
		// Inexact: [30-40 mins ago]
		// If difference < 1 min, then exact
		// Timestamps require detective training?

		var/scan_text = replacetext(display.display_text, "@F", evidence.id)
		var/time_text = null
		if(timestamp == 0)
			time_text = ""
		else
			time_text = "TTTTT"
		scan_text = replacetext(scan_text, "@T", time_text) // Change this to just add a timestamp at the end
		return scan_text

datum/forensic_data/double // Two different pieces of evidence that are linked together. Flags not included.
	var/static/datum/forensic_display/disp_double = new("@A | @B")
	var/static/datum/forensic_id/retina_empty = new("_____")
	var/datum/forensic_display/display = null // @A, @B
	var/datum/forensic_id/evidence_A = null
	var/datum/forensic_id/evidence_B = null

	New(var/datum/forensic_id/idA, var/datum/forensic_id/idB, var/datum/forensic_display/disp = disp_double, var/tstamp = 0)
		..()
		src.evidence_A = idA
		src.evidence_B = idB
		src.display = disp
		src.timestamp = tstamp
	scan_display(var/obj/item/device/detective_scanner/scanner, var/timestamp_type)
		var/scan_text = replacetext(display.display_text, "@A", evidence_A.id)
		scan_text = replacetext(scan_text, "@B", evidence_B.id)
		return scan_text
	proc/is_same(datum/forensic_data/double/other)
		return src.evidence_A == other.evidence_A && src.evidence_B == other.evidence_B

datum/forensic_data/fingerprint // An individual fingerprint applied to an item
	flags = REMOVABLE_CLEANING
	var/datum/forensic_id/print = null // The original fingerprint
	var/datum/forensic_id/glove_print = null // The glove fibres & ID
	var/datum/forensic_id/print_mask = null // The mask that the gloves apply to the print
	// (xxxxxx : insulative fibers) | (xxxxxx : black fibers)
	// xxxxx-xxaxx-xgxxx-xxxxx-xxxxx
	// 000?? ??x?? ?x?00 00000 00000
	// ...????a???g?...

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
		// var/last_shown = FALSE // Used for inserting the hyphens
		for(var/i=1, i<= FINGERPRINT_LENGTH, i++)
			switch(copytext(print_mask.id, i, i+1))
				if("?")
					final_print += "?"
				if("x")
					final_print += copytext(print.id, i + bunch_num, i + bunch_num + 1)
			bunch_char++
			if(bunch_char >= FINGERPRINT_BUNCH_SIZE)
				bunch_char = 0
				bunch_num++
		return final_print + "...";

	proc/is_same(datum/forensic_data/fingerprint/other)
		return src.print == other.print && src.glove_print == other.glove_print

datum/forensic_data/dna
	// var/static/datum/forensic_id/form_blood = new("(blood)")
	// var/static/datum/forensic_id/form_hair = new("(hair)")
	// var/static/datum/forensic_id/form_tissue = new("(tissue)")
	// var/static/datum/forensic_id/form_bone = new("(bone)")
	// var/static/datum/forensic_id/form_saliva = new("(saliva)")
	flags = REMOVABLE_CLEANING
	var/datum/forensic_id/pattern = null
	var/form = DNA_FORM_NONE // Where did the DNA come from? Use DNA_FORM_NONE if not relevant
	// var/decomp_stage = DECOMP_STAGE_NO_ROT

	New(var/datum/forensic_id/dna, var/form = DNA_FORM_NONE)
		..()
		src.pattern = dna
		src.form = form

	scan_display(var/obj/item/device/detective_scanner/scanner, var/timestamp_type)
		switch(src.form)
			if(DNA_FORM_NONE)
				return pattern.id
			if(DNA_FORM_BLOOD)
				return pattern.id + " (blood)"
			if(DNA_FORM_HAIR)
				return pattern.id + " (hair)"
			if(DNA_FORM_TISSUE)
				return pattern.id + " (tissue)"
			if(DNA_FORM_BONE)
				return pattern.id + " (bone)"
			if(DNA_FORM_SALIVA)
				return pattern.id + " (saliva)"
			else
				return pattern.id

	proc/is_equal(datum/forensic_data/dna/other)
		return src.pattern == other.pattern && src.form == other.form

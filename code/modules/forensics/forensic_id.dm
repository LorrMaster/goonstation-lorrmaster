#define FINGERPRINT_BUNCH_SIZE 4 // Number of characters between each "-"
#define FINGERPRINT_BUNCH_COUNT 4
#define FINGERPRINT_LENGTH FINGERPRINT_BUNCH_SIZE * FINGERPRINT_BUNCH_COUNT
#define DNA_BUNCH_SIZE 5
#define DNA_BUNCH_COUNT 4
#define DNA_LENGTH DNA_BUNCH_SIZE * DNA_BUNCH_COUNT

// -----| Forensic ID |-----
datum/forensic_id // A piece of forensic evidence to be passed around and referenced
	// Important Note: If you want to change an object's ID, you have to create a new ID
	// Editing an ID will change all the previous pieces of evidence that reference that ID
	// Unless if you are doing time travel, in which case you can do as you please.
	var/id = null

	New(var/id_prefix = "", var/id_suffix = "", var/length = 0, var/list/char_list = null)
		..()
		if(length == 0 || !char_list)
			src.id = id_prefix + id_suffix
		else
			src.id = id_prefix + build_id(length, char_list) + id_suffix

/datum/forensic_id/proc/build_id(var/id_length, var/list/char_list = CHAR_LIST_NUM)
	// Take a list of characters and build a random id with them
	var/new_id = ""
	for(var/i=1, i<= id_length, i++)
		new_id += pick(char_list)
	return new_id

/datum/forensic_id/proc/build_id_fingerprint(var/char_list = CHAR_LIST_FINGERPRINT, var/has_adermatoglyphia = FALSE)
	var/fp = ""
	if(!has_adermatoglyphia)
		fp += build_id(FINGERPRINT_BUNCH_SIZE, char_list)
		for(var/i=1, i<= FINGERPRINT_BUNCH_COUNT - 1, i++)
			fp += "-" + build_id(FINGERPRINT_BUNCH_SIZE, char_list)
	else
		// has_adermatoglyphia ==> condition where you do not have fingerprints
		var/no_fp_bunch = ""
		for(var/i=1, i<= FINGERPRINT_BUNCH_SIZE, i++)
			no_fp_bunch += "O"
		fp += no_fp_bunch
		for(var/i=1, i<= FINGERPRINT_BUNCH_COUNT - 1, i++)
			fp += "-" + no_fp_bunch
	src.id = fp

/datum/forensic_id/proc/build_id_dna()
	// Gad53-Jda09-Haw23-Tas29
	var/dna_id = ""
	for(var/i=1, i<= DNA_BUNCH_COUNT, i++)
		if(i != 1)
			dna_id += "-"
		dna_id += build_id(1, CHAR_LIST_UPPER_LIMIT) + build_id(2, CHAR_LIST_LOWER_LIMIT) + build_id(DNA_BUNCH_SIZE - 3, CHAR_LIST_NUM)
	src.id = dna_id

/datum/forensic_id/proc/build_id_footprint(var/pattern)
	// The footprint pattern determines which symbols are swapped with what
	// l = letter, s = symbol, h = high heels, other = no change
	var/final_id = ""
	for(var/i=1, i<= length(pattern), i++)
		var/char = copytext(pattern, i, i+1)
		switch(char)
			if("l")
				final_id += pick(CHAR_LIST_LOWER)
			if("s")
				final_id += pick(CHAR_LIST_SYMBOLS)
			if("n")
				final_id += pick(CHAR_LIST_NUM)
			if("h") // high heels
				final_id += pick("o","+","#","a","c","n","u","=","v","x","z","e")
			else
				final_id += char
	src.id = final_id

/datum/forensic_id/proc/build_id_retina(var/list/outer_L, var/list/outer_R, var/list/center_list, var/outer_count = 2)
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
/datum/forensic_id/proc/get_retina_mirror()
	// Returns a mirrored version of the text. Ex: |[o}) --> ({o]|
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


// -----| Forensic Display |-----

datum/forensic_display // Store how the forensic text should be displayed... by reference! Might be unnecessary.
	var/display_text = null

	New(var/id_text = null)
		..()
		display_text = id_text

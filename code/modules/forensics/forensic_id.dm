#define FINGERPRINT_BUNCH_SIZE 4 // Number of characters between each "-"
#define FINGERPRINT_BUNCH_COUNT 4
#define FINGERPRINT_LENGTH FINGERPRINT_BUNCH_SIZE * FINGERPRINT_BUNCH_COUNT
#define DNA_BUNCH_SIZE 5
#define DNA_BUNCH_COUNT 4
#define DNA_LENGTH DNA_BUNCH_SIZE * DNA_BUNCH_COUNT

// Store forensic_ids into a dictionary to prevent *very small* chances of duplicates
// Can also use to get the datum from the ID text
var/global/list/id_scanners_all = new()
var/global/list/id_fingerprints_all = new()
var/global/list/id_gloves_all = new()
var/global/list/id_dna_all = new()
var/global/list/id_footprints_all = new()
var/global/list/id_bites_all = new()
var/global/list/id_retina_all = new()

// -----| Forensic ID |-----
/datum/forensic_id // A piece of forensic evidence to be passed around and referenced
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

	proc/register_id(var/list/reg_list)
		if(reg_list[src.id])
			return reg_list[src.id]
		reg_list[src.id] = src
		return src

/datum/forensic_id/proc/build_id(var/id_length, var/list/char_list = CHAR_LIST_NUM)
	// Take a list of characters and build a random id with them
	var/list/new_id_list = new()
	for(var/i=1, i<= id_length, i++)
		new_id_list += pick(char_list)
	return list2text(new_id_list)

/datum/forensic_id/proc/build_id_norepeat(var/id_length, var/list/char_list = CHAR_LIST_NUM)
	// Take a list of characters and build a random id with them without using repitition
	if(id_length > char_list.len)
		id_length = char_list.len
	var/current_len = char_list.len
	var/list/new_id_list = new()
	for(var/i=1, i<= id_length, i++)
		var/pick_index = rand(1, current_len)
		new_id_list += char_list[pick_index]
		char_list[pick_index] = char_list[current_len]
		current_len--
	return list2text(new_id_list)

/datum/forensic_id/proc/build_id_fingerprint(var/list/char_list = CHAR_LIST_FINGERPRINT)
	if(char_list.len < FINGERPRINT_LENGTH)
		boutput(world, "Error: Not enough characters for fingerprint")
		return null
	var/base_fp = build_id_norepeat(16, char_list)
	var/b_size = FINGERPRINT_BUNCH_SIZE
	var/final_fp = copytext(base_fp, 1, b_size + 1)
	for(var/i=1; i< FINGERPRINT_BUNCH_COUNT; i++)
		final_fp += "-[copytext(base_fp, (b_size*i)+1, (b_size*(i+1))+1)]"
	// boutput(world, "-[final_fp]-")
	src.id = final_fp

/datum/forensic_id/proc/build_id_fingerprint_old(var/list/char_list = CHAR_LIST_FINGERPRINT, var/has_adermatoglyphia = FALSE)
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
	var/list/id_list = new()
	for(var/i=1, i<= length(pattern), i++)
		var/char = copytext(pattern, i, i+1)
		switch(char)
			if("l")
				id_list += pick(CHAR_LIST_LOWER)
			if("s")
				id_list += pick(CHAR_LIST_SYMBOLS)
			if("n")
				id_list += pick(CHAR_LIST_NUM)
			if("h") // high heels
				id_list += pick("o","+","#","a","c","n","u","=","v","x","z","e")
			else
				id_list += char
	src.id = list2text(id_list)

/datum/forensic_id/proc/build_id_bite()
	// OUCH! It bit me!
	var/final_id = build_id(4, CHAR_LIST_BITE)
	final_id += reverse_text(final_id)
	var/asym_rand = rand()
	if(asym_rand >= 0.4)
		var/rand_index = rand(1,length(final_id))
		final_id = splicetext(final_id, rand_index, rand_index+1, pick(CHAR_LIST_BITE))
	if(asym_rand >= 0.8)
		var/rand_index = rand(1,length(final_id))
		final_id = splicetext(final_id, rand_index, rand_index+1, pick(CHAR_LIST_BITE))
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

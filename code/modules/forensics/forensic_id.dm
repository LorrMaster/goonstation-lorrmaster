#define FINGERPRINT_BUNCH_SIZE 4 // Number of characters between each "-"
#define FINGERPRINT_BUNCH_COUNT 4
#define FINGERPRINT_LENGTH FINGERPRINT_BUNCH_SIZE * FINGERPRINT_BUNCH_COUNT
#define DNA_BUNCH_SIZE 5
#define DNA_BUNCH_COUNT 4
#define DNA_LENGTH DNA_BUNCH_SIZE * DNA_BUNCH_COUNT

// Store forensic_ids into a dictionary to prevent *very small* chances of duplicates
// Can also use to get the datum from the ID text
var/global/list/datum/forensic_id/registered_id_list = new()

/proc/register_id(var/id_text, var/list/reg_list = registered_id_list) // Check if the ID already exists and return it or create a new ID
	if(reg_list[id_text])
		return reg_list[id_text]
	var/datum/forensic_id/new_id = new()
	new_id.id = id_text
	reg_list[id_text] = new_id
	return new_id

// -----| Forensic ID |-----
/datum/forensic_id // A piece of forensic evidence to be passed around and referenced
	// Important Note: If you want to change an object's ID, you have to create a new ID
	// Editing an ID will change all the previous pieces of evidence that reference that ID
	// Unless if you are doing time travel, in which case you can do as you please.
	var/id = null

	New(var/id_text = "")
		if(id_text)
			src.id = id_text
			registered_id_list[id_text] = src
		..()


// -----------------------------------------

/proc/build_id(var/length, var/list/char_list = CHAR_LIST_NUM, var/prefix = "", var/suffix = "") // Create a random string using the given characters
	var/list/new_id_list = new()
	for(var/i=1, i<= length, i++)
		new_id_list += pick(char_list)
	return prefix + list2text(new_id_list) + suffix

/proc/build_id_norepeat(var/id_length, var/list/char_list = CHAR_LIST_NUM) // build_id without repeatition
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

/proc/build_id_pattern(var/pattern, var/prefix = "", var/suffix = "") // Input a type of pattern to create
	// L = uppercase letter, l = lowercase letter, s = symbol, n = number, other = no change
	var/list/id_list = new()
	for(var/i=1, i<= length(pattern), i++)
		var/char = copytext(pattern, i, i+1)
		switch(char)
			if("L")
				id_list += pick(CHAR_LIST_UPPER_LIMIT)
			if("l")
				id_list += pick(CHAR_LIST_LOWER_LIMIT)
			if("s")
				id_list += pick(CHAR_LIST_SYMBOLS)
			if("n")
				id_list += pick(CHAR_LIST_NUM)
			else
				id_list += char
	return prefix + list2text(id_list) + suffix

/proc/build_id_mirrored(var/length, var/char_list, var/asym_count = 0)
	var/final_id = build_id(4, char_list)
	final_id += reverse_text(final_id)
	for(var/i=0; i< asym_count; i++)
		var/rand_index = rand(1,length(final_id))
		final_id = splicetext(final_id, rand_index, rand_index+1, pick(char_list))
	return final_id

/proc/build_id_separated(var/text, var/bunch_size, var/separation_text = "-") // Build an ID with hyphens
	var/final_text = copytext(text, 1, bunch_size + 1)
	var/bunch_count = floor(length(text) / bunch_size)
	for(var/i=1; i<= bunch_count - 1; i++)
		var/pos = (i * bunch_size) + 1
		final_text += separation_text + copytext(text, pos, pos + bunch_size)
	return final_text

/proc/build_id_retina(var/list/outer_L, var/list/outer_R, var/list/center_list, var/outer_count = 2)
	// ([O>] [<O])
	var/retina = ""
	for(var/i=1, i<= outer_count, i++)
		var/out_char = rand(1, outer_L.len)
		retina += outer_L[out_char]
	retina += center_list[rand(1, center_list.len)]
	for(var/i=1, i<= outer_count, i++)
		var/out_char = rand(1, outer_R.len)
		retina += outer_R[out_char]
	return retina

/proc/get_retina_mirror(var/retina)
	// Returns a mirrored version of the text. Ex: |[o}) --> ({o]|
	// Used for retina symmetry
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

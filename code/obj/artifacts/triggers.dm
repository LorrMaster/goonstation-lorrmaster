// TRIGGERS

// Maximum number of 5-letter words language artifacts will check in a sentence. Here to prevent abuse.
#define ARTIFACT_LANGUAGE_SENTENCE_CHECK 3

ABSTRACT_TYPE(/datum/artifact_trigger/)
/datum/artifact_trigger
	var/type_name = "bad artifact code"
	var/stimulus_required = null
	var/do_amount_check = 1
	var/stimulus_amount = null
	var/stimulus_type = ">="
	var/hint_range = 0
	var/hint_prob = 33
	var/used = 1

	/// This artifact...
	proc/get_knowledge_desc()
		return

/datum/artifact_trigger/carbon_touch
	// touched by a carbon lifeform
	type_name = "Carbon Touch"
	stimulus_required = "carbtouch"
	do_amount_check = 0

	proc/get_knowledge_desc(var/obj/artifact)
		switch(artifact.artifact.artiappear.name)
			if("ancient")
				return "has a hand scanner designed for organics."
			if("eldritch")
				return "is just waiting for some poor soul to touch it."
			if("martian")
				return "likes being pet."
			if("wizard")
				return "activates when in contact with living energy."
		return "is activated when touched by a carbon-based lifeform."

/datum/artifact_trigger/silicon_touch
	// touched by a silicon lifeform
	type_name = "Silicon Touch"
	stimulus_required = "silitouch"
	do_amount_check = 0

	get_knowledge_desc(var/obj/artifact)
		switch(artifact.artifact.artiappear.name)
			if("ancient")
				return "has a socket designed for silicons."
			if("eldritch")
				return "really hates robots."
			if("martian")
				return "likes being around robots."
			if("wizard")
				return "responds to contact with inorganic constructs."
		return "is activated when touched by a silicon."

/datum/artifact_trigger/force
	type_name = "Physical Force"
	stimulus_required = "force"
	hint_range = 20
	hint_prob = 75

	New()
		..()
		stimulus_amount = rand(3,30)

	get_knowledge_desc(var/obj/artifact)
		switch(artifact.artifact.artiappear.name)
			if("ancient")
				return "."
			if("eldritch")
				return "."
			if("martian")
				return "."
			if("wizard")
				return "."
		return "is activated when hit."

/datum/artifact_trigger/heat
	type_name = "Heat"
	stimulus_required = "heat"
	hint_range = 20

	New()
		..()
		stimulus_amount = rand(320,400)

	get_knowledge_desc(var/obj/artifact)
		switch(artifact.artifact.artiappear.name)
			if("ancient")
				return "is rugged enough to operate at temperatures above [src.stimulus_amount] kelvin."
			if("eldritch")
				return "prefers the warm temperatures of the underworld."
			if("martian")
				return "has tissue specialized to operate in heated environments."
			if("wizard")
				return "."
		return "is activated when heated to around [round(src.stimulus_amount, 10)] kelvin."

/datum/artifact_trigger/cold
	type_name = "Cold"
	stimulus_required = "heat"
	stimulus_type = "<="
	hint_range = 20

	New()
		..()
		stimulus_amount = rand(200,300)

	get_knowledge_desc(var/obj/artifact)
		switch(artifact.artifact.artiappear.name)
			if("ancient")
				return "it can handle temperatures below [src.stimulus_amount] kelvin."
			if("eldritch")
				return "seems to be waiting for Hell to freeze over."
			if("martian")
				return "very clearly prefers the cooler Martian temperatures."
			if("wizard")
				return "."
		return "is activated when cooled to about [round(src.stimulus_amount, 10)] kelvin."

/datum/artifact_trigger/radiation
	type_name = "Radiation"
	stimulus_required = "radiate"
	hint_range = 2
	hint_prob = 75

	New()
		..()
		stimulus_type = pick(">=","<=")
		stimulus_amount = rand(1,10)

	get_knowledge_desc(var/obj/artifact)
		switch(artifact.artifact.artiappear.name)
			if("ancient")
				return "has instruments for detecting high levels of radiation."
			if("eldritch")
				return "."
			if("martian")
				return "."
			if("wizard")
				return "."
		return " is activated when irradiated."

/datum/artifact_trigger/electric
	type_name = "Electricity"
	stimulus_required = "elec"
	hint_range = 500
	hint_prob = 66

	New()
		..()
		stimulus_type = pick(">=","<=")
		stimulus_amount = rand(5,5000)

	get_knowledge_desc(var/obj/artifact)
		switch(artifact.artifact.artiappear.name)
			if("ancient")
				return "."
			if("eldritch")
				return "."
			if("martian")
				return "is clearly sensitive to electricity."
			if("wizard")
				return "."
		return "is activated when electricuted."

/datum/artifact_trigger/reagent
	type_name = "Chemicals"
	stimulus_required = "reagent"
	// can just use the above var as the required reagent field really
	stimulus_type = ">="
	hint_range = 50
	hint_prob = 100
	used = 0

	New()
		..()
		stimulus_amount = rand(10,100)

	get_knowledge_desc()
		return "is activated when exposed to [src.stimulus_amount]."

/datum/artifact_trigger/reagent/blood
	type_name = "Blood"
	stimulus_required = "blood"
	used = 0

/datum/artifact_trigger/data
	// touched by something that contains data (circuit board, disks) etc.
	type_name = "Data"
	stimulus_required = "data"
	do_amount_check = 0

	get_knowledge_desc(var/obj/artifact)
		switch(artifact.artifact.artiappear.name)
			if("ancient")
				return "is constantly scanning for data."
			if("eldritch")
				return "despises being exposed to any kind of hard data."
			if("martian")
				return "seems to really like finding new sources of data."
			if("wizard")
				return "is attuned to respond to data."
		return "is activated by reading data."

/datum/artifact_trigger/language
	type_name = "Language"
	stimulus_required = "language"
	hint_prob = 0 // uses custom way of giving hint
	do_amount_check = FALSE
	var/picked_word = "" //! The word that was initially picked.
	var/num_vowels = 0 //! number of vowels in picked word.
	var/list/positions = list() //! positions of vowels in picked word.
	// list of all valid words
	var/static/word_dict = null
	var/static/list/vowels = list("a", "e", "i", "o", "u")

	New(obj/artifact)
		..()
		if (!src.word_dict)
			// need to account for words with no vowels
			src.word_dict = dd_file2list("strings/letter_words_5.txt", " ")
		src.picked_word = pick(src.word_dict)
		for (var/i = 1 to 5)
			if (src.picked_word[i] in src.vowels)
				src.positions += "v" // vowel
				src.num_vowels += 1
			else
				src.positions += "c" // consonant

		if (artifact)
			artifact.ensure_listen_tree()
			artifact.listen_tree.AddListenInput(LISTEN_INPUT_OUTLOUD_RANGE_2)
			artifact.listen_tree.AddListenEffect(LISTEN_EFFECT_ARTIFACT_TRIGGER)

	get_knowledge_desc(var/obj/artifact)
		switch(artifact.artifact.artiappear.name)
			if("ancient")
				return "has a data stream outputting the word \"[src.picked_word]\" on repeat."
			if("eldritch")
				return "does not want to hear the word \"[src.picked_word]\", or anything that sounds like \"[src.picked_word]\", ever again."
			if("martian")
				return "has tissue that pulses with [src.picked_word]-ness."
			if("wizard")
				return "has runes with the word \"[src.picked_word]\"."
		return " is activated by the keyword [src.picked_word]."

	proc/speech_act(text)
		if (!text)
			return
		var/text_cleaned = ckey(text)
		if (length(text_cleaned) == 5)
			return speech_act_word(text_cleaned)

		var/list/ignore_characters = list(".",",","!","?","(",")","*","%","$","#","/",";",":","\"","'","_","+","=","&")
		for(var/char in ignore_characters)
			text = replacetext(text, char, " ")
		return speech_act_sentence(text)

	proc/speech_act_word(var/text)
		if (!(text in src.word_dict))
			return "error"
		var/input_vowels = 0
		var/correct_vowels = 0
		var/misplaced_vowels = 0
		for (var/i = 1 to 5)
			if (text[i] in src.vowels)
				input_vowels += 1
				if (src.positions[i] == "v")
					correct_vowels += 1

		if (input_vowels > src.num_vowels)
			return " emits a [SPAN_BOLD("grumpy")] chime."
		if (correct_vowels == src.num_vowels)
			return "correct"
		misplaced_vowels = input_vowels - correct_vowels

		var/correct_vowel_msg = "[correct_vowels == 1 ? "a <b>high</b> chime" : "a series of [correct_vowels] <b>high</b> chimes"]"
		var/misplaced_vowel_msg = "[misplaced_vowels == 1 ? "a <b>low</b> chime" : "a series of [misplaced_vowels] <b>low</b> chimes"]"

		if (correct_vowels > 0 && misplaced_vowels > 0)
			return " emits [correct_vowel_msg] and [misplaced_vowel_msg]."
		if (correct_vowels > 0)
			return " emits [correct_vowel_msg]."
		return " emits [misplaced_vowel_msg]."

	proc/speech_act_sentence(var/text)
		if (!text)
			return
		var/list/words = splittext(text, " ")

		var/check_count = 0
		for(var/word in words)
			word = ckey(word)
			if((length(word) == 6 && copytext(word, 6, 7) == "s") || (length(word) == 7 && copytext(word, 6, 8) == "es"))
				word = copytext(word, 1, 6) // Assume that the word is plural
			else if(length(word) != 5)
				continue
			check_count++;
			var/result_word = speech_act_word(word)
			if(result_word == "correct")
				return "correct"
			if(check_count == ARTIFACT_LANGUAGE_SENTENCE_CHECK)
				return "hint"
		return "hint"

#undef ARTIFACT_LANGUAGE_SENTENCE_CHECK

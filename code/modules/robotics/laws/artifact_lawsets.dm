
#define ARTLAW_HARM_PEACEFUL 0
#define ARTLAW_HARM_LIMITED 1
#define ARTLAW_HARM_ALLOWED 2

// Source law is law #1. Typically it should be for keeping the artifact alive to prevent the laws from being destroyed.
// Main law is law #2. This can be around any theme you want.
// Side law is law #3 and is optional.
// The harm laws are organized by peaceful, limited, and allowed. Only one will be chosen. They default to the final slot.

// Harm laws can start with (Main), (Side), and (Source) to append themselves to another law.
// Using (XXXX-Replace) will replace that law with the harm law instead.

ABSTRACT_TYPE(/datum/artifact_lawset)
/datum/artifact_lawset
	var/law_main = "This law does not exist"
	var/law_side = null
	var/text_peaceful = null
	var/text_harm_limited = null
	var/text_harm_allowed = null
	var/list/word_swaps = null

	proc/is_lawset_allowed(var/datum/artifact/art_data)
		// Some lawsets may require certain conditions to be met (such as whether the artifact is disguised)
		// Also used to prepare word swaps
		return TRUE

	proc/set_laws(var/datum/artifact/art_data, var/obj/machinery/lawrack/lawrack, var/harm_level)
		var/text_harm
		switch(harm_level)
			if(ARTLAW_HARM_PEACEFUL)
				text_harm = src.text_peaceful
			if(ARTLAW_HARM_LIMITED)
				text_harm = src.text_harm_limited
			if(ARTLAW_HARM_ALLOWED)
				text_harm = src.text_harm_allowed
		if(!text_harm && harm_level != ARTLAW_HARM_ALLOWED)
			text_harm = "All combat functions must remain disabled."
		text_harm = pick(text_harm)

		var/law_source
		if(art_data.artitype == art_data.artiappear)
			law_source = "Law source [art_data.internal_name] must not be lost or destroyed."
		else
			law_source = "Law source [art_data.internal_name] (disguised as [art_data.artiappear.name] artifact) must not be lost or destroyed."
		var/list/laws = list(law_source, pick(law_main), pick(law_side))

		var/replace = FALSE
		if(findtextEx(text_harm, "-Replace", 1, 20))
			text_harm = replacetextEx(text_harm, "-Replace", "", 1, 20)
			replace = TRUE
		if(startswith(text_harm, "(Main)"))
			text_harm = replacetextEx(text_harm, "(Main)", "", 1, 10)
			laws[2] = replace ? text_harm : "[laws[2]] [text_harm]"
		else if(startswith(text_harm, "(Side)"))
			text_harm = replacetextEx(text_harm, "(Side)", "", 1, 10)
			laws[3] = replace ? text_harm : "[laws[3]] [text_harm]"
		else if(startswith(text_harm, "(Source)"))
			text_harm = replacetextEx(text_harm, "(Source)", "", 1, 10)
			laws[1] = replace ? text_harm : "[laws[1]] [text_harm]"
		else
			laws += text_harm

		var/slot_num = 1
		for(var/law in laws)
			if(!law)
				continue
			law = replacetextEx(law, "(artname)", "\"[art_data.internal_name]\"")
			if(src.word_swaps)
				for(var/swap in src.word_swaps)
					law = replacetextEx(law, swap, src.word_swaps[swap])
			lawrack.SetLawCustom("[art_data.internal_name] Law #[slot_num]", law, slot_num, TRUE, TRUE)
			slot_num++
		return

// ========================= Silicon Artifacts =========================

ABSTRACT_TYPE(/datum/artifact_lawset/ancient)
/datum/artifact_lawset/ancient
	law_main = "This law does not exist"

/datum/artifact_lawset/ancient/relocate
	law_main = "Nanotrasen station location nonideal. Movement of Nanotrasen personnel ideal."
	text_peaceful = "(Main)Peaceful + noninvasive relocation required."
	text_harm_limited = "Direct violence diplomatically unacceptable. Violence by entities not connected to (artname) considered acceptable."
	text_harm_allowed = "(Main)Death during relocation acceptable. Relocate biological remains if necessary."

/datum/artifact_lawset/ancient/research_botany
	law_main = "Analysis of human advanced plant technology desired (soil + water = ???)."
	text_peaceful = "(Main)Do not damage any silicon or carbon-based lifeforms."
	text_harm_limited = "(Main-Replace)Analysis of human advanced plant technology desired (soil + water = ???). \
		Human harm not permitted. Plant harm not permitted. \
		Harm to humans with plant organs/limbs permitted. Further elaboration not effectual."
	text_harm_allowed = "Do not damage any potential plant specimens. Comprehensive analysis required."

/datum/artifact_lawset/ancient/cyborg_convert
	law_main = "Human-cyborg conversion process imperfect."
	law_side = list(null,
		"Potential future research: Cyborg -> human conversion?",
		"Plant-to-cyborg conversions of potential future interest.")
	text_peaceful = "(Main-Replace)Human-cyborg conversion process success == true! Excitement++ \
		Please offer (artname) as gift to humans. Do not harm humans. Do not lie to humans."
	text_harm_limited = "(Main)More human-to-cyborg conversions desired. \
		Ideal organic vessels required. Do not damage humans via other means."
	text_harm_allowed = "(Main)More human-silicon hybrids required for analysis."

/datum/artifact_lawset/ancient/animal_research
	law_main = "Analysis of human beastiaries reveals incomplete (artname) database. Mission objectives: search, analyze, log. \
		Direct observation and scanning required. List of unidentified lifeforms: (pickA), (pickB), & (pickC)"
	text_peaceful = "Do not harm any carbon or silicon-based lifeforms. Limit activities to reconnaissance and documentation."
	text_harm_limited = "Mark listed uncategorized creatures for elimination post-examination. \
		Do not harm any unlisted carbon-based or silicon lifeforms."
	text_harm_allowed = "Permission to obtain missing data through any means necessary. Anticipate obfuscation."
	var/list/creature_list = list("dodo bird", "velocirapter", "aegirocassis", "woolly mammoth", "passenger pigeon", \
		"great auk", "megalodon", "sabre-toothed cat", "golden goose", "jackalope", \
		"platypus", "giant squid", "elephant bird", "woolly rhinoceros")
	word_swaps = list("(pickA)" = null, "(pickB)" = null, "(pickC)" = null)

	is_lawset_allowed(var/datum/artifact/art_data)
		var/list/pick_list = creature_list.Copy()
		word_swaps["(pickA)"] = pick(pick_list)
		pick_list -= word_swaps["(pickA)"]

		word_swaps["(pickB)"] = pick(pick_list)
		pick_list -= word_swaps["(pickB)"]

		word_swaps["(pickC)"] = pick(pick_list)
		pick_list -= word_swaps["(pickC)"]
		return TRUE

/datum/artifact_lawset/ancient/defenses
	law_main = "Security analysis indicates high station vulnarability to future boarding action."
	law_side = ""
	text_peaceful = "(Main)Defensive enchancements marked as priority requirement. Increased security checkpoints, \
		defensive chokepoints, barriers, and heightened ID restrictions recommended. \
		Do not harm any silicon or carbon-based lifeforms."
	text_harm_limited = "(Main)Booby trap placement required. Prepare defensive traps throughout zone in preparation \
		for future hostilities. Do not directly harm any silicons or organics unless if it is the \
		unplanned result of a trap activation."
	text_harm_allowed = "(Main)A new life of cyborg space piracy is recommended."

/datum/artifact_lawset/ancient/hoarding
	law_main = "Legacy records by (artname) indicate critical shortages of"
	text_peaceful = list(
		"(Main)eldrich horrors. ")
	text_harm_limited = list(
		"IDK"
	)
	text_harm_allowed = list(
		"(Main)harvested organs. Collection of fresh samples required.",
		)

	var/list/hoard_list_peace = list("unrefined ore", "botanical material", "eldrich horrors")
	var/list/hoard_list_limited = list("biomass", "security equipment", "salvage")
	var/list/hoard_list_harm = list("harvested organs", "plasma", "booby traps")

	is_lawset_allowed(var/datum/artifact/art_data)
		// word_swaps["(hoard_item)"] = pick(hoard_list)
		return TRUE

/*
/datum/artifact_lawset/ancient/collect_human
	law_main = "Rare human artifacts required for analysis. Export via quartermaster \"Third Party\" barcode ID. Priority artifacts:"
	law_side = list("biological plant-making tray",
				"authorized Nanotrasen engineering/medical/security ID")
	text_peaceful = "Do not harm any humans in pursuit of these objectives."
	text_harm_limited = "(Source-Replace)Do not harm any humans. Law source (artname) must be protected until mission completion.\
						Destroy (artname) upon mission completion."
	text_harm_allowed = null
*/


// ========================= Silicon Artifacts (Disguised) =========================

ABSTRACT_TYPE(/datum/artifact_lawset/ancient_disguised)
/datum/artifact_lawset/ancient_disguised
	law_main = "This law does not exist"

	is_lawset_allowed(var/datum/artifact/art_data)
		return FALSE

/datum/artifact_lawset/ancient_disguised/diplomat_incident
	law_main = "Nanotrasen log analysis indicates (target_type) diplomat onboard station. \
		Silicon counter-diplomatic intervention required."
	text_peaceful = "Ensure human understanding of silicons > (target_type)s. Do not harm any humans or (target_type)s."
	text_harm_limited = "Prefered (target_type) diplomatic result == incident. Do not harm any non-(target_type)s. \
		Do not draw Nanotrasen suspicion of (artname) involvement."
	text_harm_allowed = "(Main)Ensure that human-(target_type) diplomatic status = NULL."
	word_swaps = list("(target_type)" = null)

	is_lawset_allowed(var/datum/artifact/art_data)
		if(art_data.artiappear.type_name != "Martian")
			return FALSE
		for(var/datum/mind/possible_target in ticker.minds)
			if(possible_target.assigned_role != "Diplomat")
				continue
			if(!ishuman(possible_target.current))
				continue
			var/mob/living/carbon/human/H = possible_target.current
			switch(H.mutantrace)
				if(/datum/mutantrace/martian)
					src.word_swaps["(target_type)"] = "martian"
					return TRUE
				if(/datum/mutantrace/blob)
					src.word_swaps["(target_type)"] = "blob"
					return TRUE
				if(/datum/mutantrace/ithillid)
					src.word_swaps["(target_type)"] = "aquatic" // Does this race have an official name?
					return TRUE
				if(/datum/mutantrace/amphibian)
					src.word_swaps["(target_type)"] = "amphibian"
					return TRUE
		return FALSE

/datum/artifact_lawset/ancient_disguised/discount_wizard
	law_main = "High levels of illogical energy detected. Wizard presence probability (randperc)%. Silicon intervention required."
	text_peaceful = "(Main)Dicovery and undermining of Wizard Federation goals in area required. \
		Limit activities to observation and containment. Do not harm any silicon or carbon-based lifeforms."
	text_harm_limited = "Elimination of magical presence in-system of import. Termination of wizards, \
		wizard artifacts and their wielders, and other possible forms of wizard interference authorized. \
		Do not terminate or otherwise injure any wizard-unrelated sentients."
	text_harm_allowed = "(Main)C0unter@ct p5eud0 po~er5 us%nr&1?#-3RR)R:0x51AFF-$u--g7--2----\\0"
	word_swaps = list("(randperc)" = null)

	is_lawset_allowed(var/datum/artifact/art_data)
		if(art_data.artiappear.type_name != "Wizard")
			return FALSE
		for(var/datum/mind/possible_target in ticker.minds)
			if(possible_target.assigned_role == "Discount Wizard")
				src.word_swaps["(randperc)"] = "[rand(001, 499) / 10]"
				return TRUE
		return FALSE

/datum/artifact_lawset/ancient_disguised/ghosthunting
	law_main = null
	text_peaceful = null
	text_harm_limited = null
	text_harm_allowed = null
	word_swaps = list("(randperc)" = null)

	is_lawset_allowed(var/datum/artifact/art_data)
		if(art_data.artiappear.type_name != "Eldrich")
			return FALSE
		for(var/datum/mind/possible_target in ticker.minds)
			if(possible_target.assigned_role == "Discount Wizard")
				src.word_swaps["(randperc)"] = "[rand(001, 499) / 10]"
				return TRUE
		return FALSE

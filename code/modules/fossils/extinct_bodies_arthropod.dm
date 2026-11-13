/datum/extinct_body_category/arthropod
	name = "arthropod"
	icon_file = 'icons/mob/critter/nonhuman/extinct/arthropod.dmi'
	antag_message = "Your kind hast lay ruined for countless eons and the remnants of thine once-great species lie all but \
		forgotten. But despair not... for thou hast been reborn! <i><sub>With a misaligned exoskeleton,</sub></i> \
		but reborn nonetheless! What is more, your creators art generous and hast bestowed upon you a bounty of \
		many potentially-highly-delectable bipeds. Ready your appendages, for thy instincts art only confined by thine ambitions!"

	New()
		. = ..()
		var/datum/extinct_body_slot/slot_face = new/datum/extinct_body_slot(80, list(55, 85, 85, 85), EXTINCT_COLOR_PRIMARY)
		var/datum/extinct_body_slot/slot_head = new/datum/extinct_body_slot(100, list(50, 80, 80, 80), EXTINCT_COLOR_PRIMARY)
		var/datum/extinct_body_slot/slot_body_main = new/datum/extinct_body_slot(100, list(20, 50, 50, 50), EXTINCT_COLOR_SECONDARY)
		var/datum/extinct_body_slot/slot_body_side = new/datum/extinct_body_slot(75, list(25, 60, 55, 55), EXTINCT_COLOR_HIGHLIGHT)
		var/datum/extinct_body_slot/slot_body_back = new/datum/extinct_body_slot(75, list(80, 55, 60, 60), EXTINCT_COLOR_HIGHLIGHT)
		var/datum/extinct_body_slot/slot_legs = new/datum/extinct_body_slot(100, list(0, 0, 0, 0), EXTINCT_COLOR_SECONDARY)
		slot_face.desc_missing = "its face"
		slot_head.desc_missing = "a good portion of its head"
		slot_body_main.desc_missing = "the overall shape of its body"
		slot_body_side.desc_missing = "the sides of its body"
		slot_body_back.desc_missing = "the back of its body"
		slot_legs.desc_missing = "its legs"
		src.body_slot_data["face"] = slot_face
		src.body_slot_data["head"] = slot_head
		src.body_slot_data["body_main"] = slot_body_main
		src.body_slot_data["body_side"] = slot_body_side
		src.body_slot_data["body_back"] = slot_body_back
		src.body_slot_data["legs"] = slot_legs

		src.load_parts(part_type_main = /datum/extinct_body_part/arthropod)

	on_spawn(var/mob/living/critter/critter)
		critter.speech_verb_say = "clicks"
		critter.speech_verb_exclaim = "screeches"
		critter.speech_verb_ask = "chitters"

		return

	apply_species(var/datum/extinct_species/species)
		. = ..()
		species.abilities += /datum/targetable/vent_move
		species.abilities += pick(/datum/targetable/critter/bury_hide, /datum/targetable/critter/spit, /datum/targetable/critter/tackle)

		var/datum/dna_chromosome/power_enhancer/empower = new()
		var/datum/dna_chromosome/stabalize = new()
		var/datum/bioEffect/carapace = species.bioHolder.AddEffect("carapace", do_stability = FALSE, scannable = TRUE, innate = TRUE)
		stabalize.apply(carapace)
		empower.apply(carapace)

	generate_body_colors(var/datum/extinct_species/species)
		var/list/color_hsl_primary
		var/list/color_hsl_secondary
		var/list/color_hsl_highlight

		if(prob(20))
			color_hsl_primary = list(rand(0, 360), rand(0, 70), rand(15, 85))
		else
			color_hsl_primary = list(rand(0, 360), rand(0, 40), rand(35, 55))

		color_hsl_secondary = list()
		color_hsl_secondary += clamp(color_hsl_primary[1] + rand(-5, 5), 0, 360)
		color_hsl_secondary += clamp(color_hsl_primary[2] + rand(-5, 10), 0, 100)
		color_hsl_secondary += clamp(color_hsl_primary[3] + rand(-10, 5), 0, 100)

		if(prob(30))
			color_hsl_highlight = list(rand(0, 360), rand(30, 80), rand(40, 60))
		else
			color_hsl_highlight = list()
			color_hsl_highlight += clamp(color_hsl_primary[1] + rand(-90, 90), 0, 360)
			color_hsl_highlight += clamp(color_hsl_primary[2] + rand(-25, 20), 0, 100)
			color_hsl_highlight += clamp(color_hsl_primary[3] + rand(-10, 15), 0, 100)

		var/color_rgb_primary = hsl2rgb(color_hsl_primary[1], color_hsl_primary[2], color_hsl_primary[3])
		var/color_rgb_secondary = hsl2rgb(color_hsl_secondary[1], color_hsl_secondary[2], color_hsl_secondary[3])
		var/color_rgb_highlight = hsl2rgb(color_hsl_highlight[1], color_hsl_highlight[2], color_hsl_highlight[3])
		for(var/slot_key in species.body_parts)
			var/datum/extinct_body_part/part = species.body_parts[slot_key]
			if(part.color_category == EXTINCT_COLOR_RANDOM)
				part.color_category = pick(EXTINCT_COLOR_PRIMARY, EXTINCT_COLOR_SECONDARY, EXTINCT_COLOR_HIGHLIGHT, EXTINCT_COLOR_HIGHLIGHT)
			switch(part.color_category)
				if(EXTINCT_COLOR_PRIMARY)
					part.color = color_rgb_primary
				if(EXTINCT_COLOR_SECONDARY)
					part.color = color_rgb_secondary
				if(EXTINCT_COLOR_HIGHLIGHT)
					part.color = color_rgb_highlight
				if(EXTINCT_COLOR_BLACK)
					part.color = "#181818"
				else
					part.color = "#FFFFFF"

	get_fossil_desc(var/obj/item/fossil/fossil)
		var/list/datum/extinct_body_part/part_list = list()
		for(var/slot in fossil.slots_preserved)
			part_list[slot] = fossil.species.body_parts[slot]

		var/datum/extinct_body_part/head = part_list["head"]
		var/datum/extinct_body_part/face = part_list["face"]
		var/datum/extinct_body_part/body_main = part_list["body_main"]
		var/datum/extinct_body_part/body_side = part_list["body_side"]
		var/datum/extinct_body_part/body_back = part_list["body_back"]
		var/datum/extinct_body_part/legs = part_list["legs"]
		var/desc = null
		if(head && face)
			desc = "It has \a [face.desc] on its [head.desc]. "
		else if(head)
			desc = "It has \a [head.desc]. "
		else if(face)
			desc = "It seems to have \a [face.desc] somewhere on its head. "

		if(body_main && body_side && body_back)
			desc += "Its [body_main.desc] has "
			if(body_side)
				desc += "\a [body_side.desc] on its sides[body_back ? " and " : null]"
			if(body_back)
				desc += "\a [body_back.desc] on its back "
			desc += "."
		else if(body_side && body_back)
			desc += "It has \a [body_side.desc] and another [body_back.desc] somewhere on its body. "
		else if(body_side || body_back)
			desc += "It has \a [body_side ? body_side.desc : body_back.desc] somewhere on its body. "
		else if(body_main)
			desc += "It retains \a [body_main.desc]. "

		if(legs)
			if(desc)
				desc += "Its [legs.desc] were also able to remain preserved. "
			else
				desc += "You can see \a [legs.desc] preserved on the surface of the [fossil]. "
		return desc + src.get_fossil_desc_missing(fossil)

/datum/extinct_body_part/arthropod
	head_large
		icon_state = "head_large"
		desc = "large semi-spherical head"
	head_sturdy
		icon_state = "head_sturdy"
		desc = "sturdy-looking head"
	head_bug
		icon_state = "head_bug"
		desc = "bug-like head"
	head_tiny
		icon_state = "head_tiny"
		desc = "very small head"

		apply_species(var/datum/extinct_species/species)
			. = ..()
			species.body_parts -= "face" // Head is too tiny to fit eyes
			return
	head_arrow
		icon_state = "head_arrow"
		desc = "arrow-shaped head"

		apply_species(var/datum/extinct_species/species)
			. = ..()
			species.body_parts -= "face" // Head isn't shaped well for eyes
			return
	head_disk
		icon_state = "head_disk"
		desc = "disk-shaped head"
	head_indented
		icon_state = "head_indented"
		desc = "indented head"

	face_eyes_large
		icon_state = "face_eyes_large"
		desc = "pair of large eyes"
	face_eyes_small
		icon_state = "face_eyes_small"
		desc = "pair of small eyes"
	face_horns
		icon_state = "face_horns"
		desc = "set of small horns"
		color_category = EXTINCT_COLOR_HIGHLIGHT
	face_horn_large
		icon_state = "face_horn_large"
		desc = "single large horn"
		color_category = EXTINCT_COLOR_HIGHLIGHT
		// Keep the horn behind head while facing north
		override_layering = alist(NORTH = 45, SOUTH = INFINITY, EAST = INFINITY, WEST = INFINITY)
	face_antenna
		icon_state = "face_antenna"
		desc = "pair of antenna"
		color_category = EXTINCT_COLOR_BLACK
		// Keep the antenna behind head while facing north
		override_layering = alist(NORTH = 45, SOUTH = INFINITY, EAST = INFINITY, WEST = INFINITY)

	body_main_scales_long
		icon_state = "body_main_scales_long"
		desc = "long and thin segmented body"
	body_main_scales_thick
		icon_state = "body_main_scales_thick"
		desc = "large segmented body"
	body_main_crevice
		icon_state = "body_main_crevice"
		desc = "thin and creviced body"
	body_main_oval
		icon_state = "body_main_oval"
		desc = "oval-shaped segmented body"

	legs_roach
		icon_state = "legs_roach"
		desc = "set of large legs"
	legs_centipede
		icon_state = "legs_centipede"
		desc = "huge array of tiny legs"
	legs_thick
		icon_state = "legs_thick"
		desc = "set of thick legs"

	body_side_coat
		icon_state = "body_side_coat"
		desc = "outer coating"
	body_side_appendages
		icon_state = "body_side_appendages"
		desc = "pair of large appendages"
	body_side_fins
		icon_state = "body_side_fins"
		desc = "pair of long fins"
	body_side_spines
		icon_state = "body_side_spines"
		desc = "set of spines"
	body_side_bumps
		icon_state = "body_side_bumps"
		desc = "series of bumps"

	body_back_scales
		icon_state = "body_back_scales"
		desc = "set of large scales"
	body_back_scales_pair
		icon_state = "body_back_scales_pair"
		desc = "numerous small scales"
	body_back_spike
		icon_state = "body_back_spike"
		desc = "single large spike"
	body_back_spikes_middle
		icon_state = "body_back_spikes_middle"
		desc = "series of large spikes"

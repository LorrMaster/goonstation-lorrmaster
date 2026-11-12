#define EXTINCT_COLOR_RANDOM 0
#define EXTINCT_COLOR_PRIMARY 1
#define EXTINCT_COLOR_SECONDARY 2
#define EXTINCT_COLOR_HIGHLIGHT 3
#define EXTINCT_COLOR_BLACK 4

// ================================================================================================================
// ================================================ Body Categories ===============================================
// ================================================================================================================

/// Extinct critters are divided up into body plans with different sprite sets and potentially some innate traits.
/// The body category is NOT owned by any individual species. It's just used for choosing and building the body.
/// Sort of like the genetics equivalent of artsci artifact origins.
ABSTRACT_TYPE(/datum/extinct_body_category)
/datum/extinct_body_category
	var/name = null
	var/icon_file = null
	var/list/body_slot_data = list() //! Associative list of part slots that will be used to build the creature's body
	var/antag_message

	proc/on_spawn(var/mob/living/new_mob)
		return

	proc/apply_species(var/datum/extinct_species/species)
		// Generate a body and apply it to the new species
		var/alist/chosen_parts = alist()
		for(var/slot_key in list_keys(src.body_slot_data))
			var/datum/extinct_body_slot/slot = src.body_slot_data[slot_key]
			var/chosen = pick(slot.part_list)
			if(prob(slot.usage_prob) && chosen)
				var/datum/extinct_body_part/part = chosen
				chosen_parts[slot_key] = new part.type(part)
		species.body_parts = chosen_parts
		src.generate_body_colors(species)
		for(var/slot_key in species.body_parts)
			var/datum/extinct_body_part/part = species.body_parts[slot_key]
			part.apply_species(species)

	proc/generate_body_colors()
		return

	proc/get_fossil_desc(var/obj/item/fossil/fossil)
		var/list/datum/extinct_body_part/part_list = list()
		for(var/slot in fossil.slots_preserved)
			part_list += fossil.species.body_parts[slot]

		var/desc = "It has "
		var/datum/extinct_body_part/part_last = null
		for(var/datum/extinct_body_part/part in part_list)
			if(part_last)
				desc += "[part_last.desc], "
			part_last = part
		if(length(part_list) > 1)
			desc += " and \a [part_last.desc]. "
		else if(length(part_list) == 1)
			desc += " \a [part_last.desc]. "
		else
			desc = null
		desc += src.get_fossil_desc_missing(fossil)
		return desc

	proc/get_fossil_desc_missing(var/obj/item/fossil/fossil)
		var/list/slots_missing = list_keys(fossil.species.body_parts) - fossil.slots_preserved
		if(!slots_missing)
			return "It seems to be a complete fossil."
		var/desc = "It seems to be missing "
		var/datum/extinct_body_slot/slot_last = null
		for(var/slot in slots_missing)
			if(slot_last)
				desc += "[slot_last.desc_missing], "
			slot_last = src.body_slot_data[slot]
		if(length(slots_missing) > 1)
			desc += "and [slot_last.desc_missing]."
		else
			desc += "[slot_last.desc_missing]."
		return "<li>[desc]</li>"

	/// Find all the different types of body parts and load into their respective slots
	proc/load_parts(var/part_type_main = null)
		var/list/part_list = list() // Associative list. Keys are the part's icon_state
		if(part_type_main)
			// Load subtypes first
			var/list/part_type_list = concrete_typesof(part_type_main, cache = FALSE) // We'll likely only be doing this once per category
			for(var/part_type in part_type_list)
				if(part_type == part_type_main)
					continue
				var/datum/extinct_body_part/part = new part_type
				part_list[part.icon_state] = part
		else
			part_type_main = /datum/extinct_body_part

		var/list/icon_state_list = icon_states(src.icon_file)
		for(var/state in icon_state_list)
			var/state_base = state
			if(endswith(state, "_M"))
				state_base = copytext(state, 1, length(state) - 1)
			var/datum/extinct_body_part/part = part_list[state_base]
			if(part && endswith(state, "_M"))
				part.has_moving = TRUE

		for(var/state in part_list)
			for(var/slot_key in src.body_slot_data)
				if(!startswith(state, slot_key))
					continue
				var/datum/extinct_body_slot/slot = src.body_slot_data[slot_key]
				var/datum/extinct_body_part/part = part_list[state]
				part.icon_state = state
				if(part.color_category == -1)
					part.color_category = slot.color_category
				slot.part_list += part
				break
		return

// ================================================================================================================
// ================================================== Body Slots ==================================================
// ================================================================================================================

/// This is just used by the body category to store data on how to assemble the final sprite.
/datum/extinct_body_slot
	var/desc_missing
	var/layer_north
	var/layer_south
	var/layer_east
	var/layer_west
	var/color_category //! Default color that parts in this slot will use. For the face to be the same color as the head, etc.
	var/usage_prob = 100 //! Chance that a body part will fill this slot at all
	var/list/datum/extinct_body_part/part_list = list() //! Parts that can go into this slot

	New(var/usage_prob, var/list/dir_layers, var/color_category)
		. = ..()
		src.usage_prob = usage_prob
		src.layer_north = dir_layers[1]
		src.layer_south = dir_layers[2]
		src.layer_east = dir_layers[3]
		src.layer_west = dir_layers[4]
		src.color_category = color_category

	proc/get_layer(var/direction)
		switch(direction)
			if(NORTH)
				return layer_north
			if(SOUTH)
				return layer_south
			if(EAST)
				return layer_east
			else
				return layer_west

// ================================================================================================================
// ================================================== Body Parts ==================================================
// ================================================================================================================

/// By default body parts found in the .dmi will be a "/datum/extinct_body_part".
/// If you want to customize the body part in some way, create a subtype for it here.
/// Note for animations: The delay put on each frame will be reset when building the final sprite.
/datum/extinct_body_part
	var/icon_state = null
	var/desc = "-missing desc-" //! This is a...
	var/color_category = -1
	var/has_moving = FALSE //! Is there a moving version of this icon_state? Filled automatically when loading parts.
	/// Set to a list to override the default slot layering (Format: alist(NORTH = W, SOUTH = X, EAST = Y, WEST = Z)).
	/// Use infinity to keep the normal layering for that direction.
	var/alist/override_layering = null

	var/color = null
	var/is_analysed = FALSE //! Has this part been analysed by a genetics computer for the species that it is on?

	New(var/datum/extinct_body_part/source = null)
		. = ..()
		if(source)
			src.icon_state = source.icon_state
			src.has_moving = source.has_moving
			src.color_category = source.color_category

	/// Called after all the parts and colors have been chosen
	proc/apply_species(var/datum/extinct_species/species)
		return

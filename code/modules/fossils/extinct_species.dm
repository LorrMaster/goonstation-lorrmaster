var/global/list/extinct_body_categories = null
var/global/datum/extinct_species/extinct_species_list = list()

/datum/extinct_species
	var/name_genus = ""
	var/name_species = ""
	var/blood_id = "hemolymph"

	var/icon/body_icon = null //! The final sprite for this species.
	var/datum/extinct_body_category/body_category //! What general kind of of creature this is.
	var/alist/body_parts = alist() //! Associative list of "extinct_body_parts". Keys are slot names.
	var/datum/bioHolder/bioHolder
	var/list/abilities = list()
	var/critter_type = /mob/living/critter/extinct //! The type of critter to spawn. In case you want it to be a ranch critter or something.
	var/is_antag = FALSE

	New()
		. = ..()
		extinct_species_list += src
		if(!extinct_body_categories)
			extinct_body_categories = list()
			for(var/body_type in concrete_typesof(/datum/extinct_body_category))
				extinct_body_categories[body_type] = new body_type

		src.bioHolder = new()
		src.bioHolder.age = rand(10, 520) * 1000000
		src.body_category = extinct_body_categories[pick(extinct_body_categories)]
		src.body_category.apply_species(src)
		src.build_sprite()
		src.is_antag = prob(20)

		// Generate a super-scientific name for this species.
		var/list/start_strings = strings("extinct_names.txt", "name_start")
		var/list/middle_strings = strings("extinct_names.txt", "name_middle")
		var/list/end_strings = strings("extinct_names.txt", "name_end")
		src.name_genus = "[pick(start_strings)][pick(middle_strings)][pick(end_strings)]"
		src.name_species = "[pick(start_strings)][pick(middle_strings)][pick(end_strings)]"

	proc/on_spawn(var/mob/living/critter/critter)
		critter.blood_id = src.blood_id
		critter.bioHolder.CopyOther(src.bioHolder, copyPool = FALSE)
		for(var/ability_type in src.abilities)
			critter.addAbility(ability_type)
		src.body_category.on_spawn(critter)
		return

	// ============================================= Sprite Building =============================================

	/// Overlay the body parts. Each direction could be layered differently so we need to do this for each of them.
	proc/build_sprite()
		src.body_icon = icon('icons/mob/critter/nonhuman/extinct/extinct.dmi')
		src.build_sprite_direction(NORTH)
		src.build_sprite_direction(SOUTH)
		src.build_sprite_direction(EAST)
		src.build_sprite_direction(WEST)

		// Turn it upside-down for the death sprite
		var/icon/icon_dead_east = icon(src.body_icon, "creature", EAST, 1)
		var/icon/icon_dead_west = icon(src.body_icon, "creature", WEST, 1)
		icon_dead_east.Flip(NORTH)
		icon_dead_west.Flip(NORTH)
		src.body_icon.Insert(icon_dead_east, "creature_dead", SOUTH)
		src.body_icon.Insert(icon_dead_east, "creature_dead", EAST)
		src.body_icon.Insert(icon_dead_west, "creature_dead", NORTH)
		src.body_icon.Insert(icon_dead_west, "creature_dead", WEST)

	proc/build_sprite_direction(var/direction)
		// Figure out how the parts should be layered in the given direction, from back to front.
		var/list/slots = list_keys(src.body_parts)
		var/list/slots_ordered = list()
		while(length(slots) > 0)
			var/lowest_val = INFINITY
			var/lowest_slot = null
			for(var/slot in slots)
				var/datum/extinct_body_slot/slot_data = src.body_category.body_slot_data[slot]
				var/datum/extinct_body_part/part = src.body_parts[slot]
				var/slot_val
				if(part.override_layering && part.override_layering[direction] != INFINITY)
					slot_val = part.override_layering[direction]
				else
					slot_val = slot_data.get_layer(direction)
				if(slot_val < lowest_val)
					lowest_val = slot_val
					lowest_slot = slot
			slots_ordered += lowest_slot
			slots -= lowest_slot

		// Now take the ordering and use it to layer the sprites on top of each other
		var/icon/icon_dir = icon('icons/mob/critter/nonhuman/extinct/extinct.dmi', "creature", direction)
		var/icon/icon_dir_moving = icon('icons/mob/critter/nonhuman/extinct/extinct.dmi', "creature_M", direction)
		for(var/current_slot in slots_ordered)
			var/datum/extinct_body_part/part = src.body_parts[current_slot]
			var/hex_color = part.color
			var/red = GetRedPart(hex_color) / 255
			var/green = GetGreenPart(hex_color) / 255
			var/blue = GetBluePart(hex_color) / 255
			var/icon/part_sprite = icon(src.body_category.icon_file, part.icon_state, direction)
			part_sprite.MapColors(red, green, blue)
			icon_dir.Blend(part_sprite, ICON_OVERLAY)
			if(part.has_moving)
				part_sprite = icon(src.body_category.icon_file, "[part.icon_state]_M", direction)
				part_sprite.MapColors(red, green, blue)
			icon_dir_moving.Blend(part_sprite, ICON_OVERLAY)
		src.body_icon.Insert(icon_dir, "creature", direction, delay = 2)
		src.body_icon.Insert(icon_dir_moving, "creature", direction, moving = TRUE)



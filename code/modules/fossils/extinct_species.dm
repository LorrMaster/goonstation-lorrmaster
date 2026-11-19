var/global/list/extinct_body_categories = null
var/global/datum/extinct_species/extinct_species_list = list()

/datum/extinct_species
	var/name_genus = ""
	var/name_species = ""
	var/blood_id = "hemolymph"
	var/health_mult = 1

	var/icon/body_icon = null //! The final sprite for this species.
	var/datum/extinct_body_category/body_category //! What general kind of of creature this is.
	var/datum/extinct_niche/niche //! Type of critter, major abilities, is it player-controlled, etc.
	var/alist/body_parts = alist() //! Associative list of "extinct_body_parts". Keys are slot names.
	var/datum/bioHolder/bioHolder
	var/list/abilities = list()
	var/associated_color //! What color to use for things associated with this species, such as eggs
	var/is_recorded = FALSE //! Has this species's genetics been scanned and recorded into the medical database?

	New(var/niche_type = null)
		. = ..()
		extinct_species_list += src
		if(!extinct_body_categories)
			extinct_body_categories = list()
			for(var/body_type in concrete_typesof(/datum/extinct_body_category))
				extinct_body_categories[body_type] = new body_type
		src.body_category = extinct_body_categories[pick(extinct_body_categories)]
		src.bioHolder = new()
		src.bioHolder.age = rand(10, 520) * 1000000
		if(!niche_type)
			niche_type = pick(src.body_category.potential_niches)
		src.niche = new niche_type(src)
		src.body_category.apply_species(src)
		src.build_sprite()

		// Pick some genes for the gene pool. These genes will need to be activated to clone the creature from a fossil.
		var/list/chosen_genes = pick_multiple(src.niche.potential_genes, 2)
		chosen_genes += pick_multiple(src.body_category.potential_genes - chosen_genes, 2)
		for(var/chosen in chosen_genes)
			var/datum/bioEffect/gene_type = chosen
			src.bioHolder.AddNewPoolEffect(initial(gene_type.id), TRUE)

		// Generate a super-scientific name for this species.
		var/list/start_strings = strings("extinct_names.txt", "name_start")
		var/list/middle_strings = strings("extinct_names.txt", "name_middle")
		var/list/end_strings = strings("extinct_names.txt", "name_end")
		src.name_genus = "[pick(start_strings)][pick(middle_strings)][pick(end_strings)]"
		src.name_species = "[pick(start_strings)][pick(middle_strings)][pick(end_strings)]"

	proc/on_spawn(var/mob/living/critter/critter)
		critter.icon = src.body_icon
		critter.icon_state = "creature"
		critter.icon_state_alive = "creature"
		critter.icon_state_dead = "creature_dead"
		critter.icon_state_ghost = "creature"
		critter.name = pick("weird","odd","bizarre","curious","peculiar","strange","eerie","exotic","uncanny","unusual","unknown","quaint","outlandish")
		critter.name += " [src.body_category.name]"
		critter.blood_id = src.blood_id
		critter.bioHolder.CopyOther(src.bioHolder, copyPool = TRUE)
		for(var/ability_type in src.abilities)
			critter.addAbility(ability_type)
		src.body_category.on_spawn(critter)
		return

	proc/get_name_full()
		return "[capitalize(src.name_genus)] [capitalize(src.name_species)]"

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

ABSTRACT_TYPE(/obj/item/fossil)
/obj/item/fossil
	name = "fossil"
	desc = "An imprint of some long-dead space creature."
	icon = 'icons/obj/items/materials/fossil.dmi'
	var/sprite_count = 2 // Number of sprites available to choose from
	var/datum/extinct_species/species = null //! Data on what kind of creature was fossilized
	var/list/slots_preserved = list() //! Which parts of the creature's body have been preserved.

	New()
		. = ..()
		src.icon_state = "fossil_[rand(1,src.sprite_count)]$$[src.default_material]"
		if(!length(extinct_species_list) || prob(50 ** (1 / length(extinct_species_list))))
			src.species = new()
		else
			src.species = pick(extinct_species_list)

		var/list/slots_list = list_keys(src.species.body_parts)
		var/preserved_slot = pick(slots_list)
		src.slots_preserved += preserved_slot
		slots_list -= preserved_slot
		// 5% chance for a complete fossil.
		var/preserve_prob = (0.05 ** (1 / length(slots_list))) * 100
		for(var/slot in slots_list)
			if(prob(preserve_prob))
				src.slots_preserved += slot

	get_desc(dist, mob/user)
		. = ..()
		if(!src.species || dist > 1)
			return
		var/fossil_desc
		if(user.mind?.assigned_role == "Geneticist")
			fossil_desc = "Looks like \a <i>[species.name_genus] [species.name_species]</i> fossil, an extinct type of [species.body_category.name]. "
		else if(user.traitHolder.hasTrait("training_miner"))
			fossil_desc = "Looks like some kind of [pick("weird","odd-looking","strange","extinct")] [species.body_category.name]. "
		fossil_desc += src.species.body_category.get_fossil_desc(src)
		return fossil_desc


	afterattack(var/atom/A, var/mob/user)
		if(istype(A, /obj/machinery/computer/genetics))
			var/obj/machinery/computer/genetics/genetics_computer = A
			genResearch.researchMaterial += 100
			for(var/chromosome_type in concrete_typesof(/datum/dna_chromosome))
				var/datum/dna_chromosome/C = new chromosome_type(src)
				genetics_computer.saved_chromosomes += C
				C = new chromosome_type(src)
				genetics_computer.saved_chromosomes += C
			user.drop_item()
			playsound(genetics_computer, 'sound/machines/scan2.ogg', 125, TRUE)
			boutput(user,SPAN_SUCCESS("[src] submitted for 100 research material and some chromosomes."))

			for(var/slot in src.slots_preserved)
				var/datum/extinct_body_part/part = src.species.body_parts[slot]
				part.is_analysed = TRUE
			var/analysis_complete = TRUE
			for(var/slot in src.species.body_parts)
				var/datum/extinct_body_part/part = src.species.body_parts[slot]
				if(!part.is_analysed)
					analysis_complete = FALSE
					break
			if(analysis_complete)
				var/obj/item/fossil_critter_disk/disk = new(get_turf(genetics_computer), src.species)
				boutput(user, SPAN_SUCCESS("Analysis of <i>[src.species.name_genus] [src.species.name_species]</i> complete."))
				genetics_computer.visible_message("[disk] is ejected from the [genetics_computer].")
			qdel(src)

/obj/item/fossil/stone
	name = "fossil"
	default_material = "rock"
	sprite_count = 8

/obj/item/fossil/ice
	name = "frozen fossil"
	desc = "Some strange creature encased in ice. Probably best to keep it that way."
	default_material = "ice"
	sprite_count = 5

/obj/item/fossil/batiline
	name = "batiline fossil"
	desc = "An imprint of some long-dead space creature. Possibly poisoned by the toxic metals in the ore, or otherwise used it as protection against the radiation of space."
	default_material = "batiline"
	sprite_count = 3

/obj/item/fossil/cerenkite
	name = "cerenkite fossil"
	desc = "An imprint of some long-dead space creature. Best be careful with it before you're added to the exibit too."
	default_material = "cerenkite"
	sprite_count = 3

/obj/item/fossil/cobryl
	name = "cobryl fossil"
	default_material = "cobryl"
	sprite_count = 3

/obj/item/fossil/koshmarite
	name = "koshmarite fossil"
	desc = "A koshmarite imprint of some creature. Probably best to assume it's haunted until proven otherwise."
	default_material = "koshmarite"
	sprite_count = 3

/obj/item/fossil/mauxite
	name = "mauxite fossil"
	default_material = "mauxite"
	sprite_count = 3

/obj/item/fossil/molitz
	name = "molitz fossil"
	default_material = "molitz"
	sprite_count = 3

/obj/item/fossil/pharosium
	name = "pharosium fossil"
	desc = "An imprint of some long-dead space creature. Hard to tell whether it was originally organic or silicon."
	default_material = "pharosium"
	sprite_count = 3

/obj/item/fossil/plasmastone
	name = "plasmastone fossil"
	desc = "Some strange creature entombed in solid plasma. At least you think it's a tomb."
	default_material = "plasmastone"
	sprite_count = 3

/obj/item/fossil/syreline
	name = "syreline fossil"
	desc = "An imprint of some long-dead space creature. All this time and still looking fabulous."
	// "A syreline imprint of an ancient creature. It is very difficult to research these specimens
	// due to the supply being entirely bought up by billionaire collectors."
	default_material = "syreline"
	sprite_count = 3

/obj/item/fossil/uqill
	name = "uqill fossil"
	desc = "A remnents of some kind of ancient lifeform. It's unlear if this is the thing itself or just some tool that it left behind."
	default_material = "uqill"

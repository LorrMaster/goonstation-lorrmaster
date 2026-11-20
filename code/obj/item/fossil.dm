ABSTRACT_TYPE(/obj/item/fossil)
/obj/item/fossil
	name = "fossil"
	desc = "An imprint of some long-dead space creature."
	icon = 'icons/obj/items/materials/fossil.dmi'
	var/sprite_count = 2 // Number of sprites available to choose from
	var/datum/extinct_species/species = null //! Data on what kind of creature was fossilized
	var/datum/bioHolder/bioHolder = null
	var/list/slots_preserved = list() //! Which parts of the creature's body have been preserved.

	New()
		. = ..()
		src.icon_state = "fossil_[rand(1,src.sprite_count)]$$[src.default_material]"
		src.species = new()

		src.bioHolder = new()
		src.bioHolder.CopyOther(src.species.bioHolder)

		// Choose which body parts to preserve
		var/list/slots_list = list_keys(src.species.body_parts)
		var/preserved_slot = pick(slots_list)
		src.slots_preserved += preserved_slot
		slots_list -= preserved_slot
		var/preserve_prob = (0.05 ** (1 / length(slots_list))) * 100 // 5% chance for a complete fossil.
		for(var/slot in slots_list)
			if(prob(preserve_prob))
				src.slots_preserved += slot

		// More complete fossils start with some genes activated.
		for(var/test in (list_keys(src.bioHolder.effectPool) - list_keys(src.bioHolder.effects)))
			boutput(world, "Test: [test]")
		var/gene_preservation_amount = (length(src.slots_preserved) - 1) / length(slots_list)
		var/list/pool_ids = list_keys(src.bioHolder.effectPool)
		var/gene_pool_count = length(pool_ids - list_keys(src.bioHolder.effects))
		var/genes_preserved = round(gene_pool_count * gene_preservation_amount)
		for(var/i in 1 to genes_preserved)
			var/chosen = pick(pool_ids)
			src.bioHolder.ActivatePoolEffect(src.bioHolder.GetEffectFromPool(chosen), grant_research = FALSE)
			pool_ids -= chosen

	proc/record_genetics()
		if(src.species.is_recorded)
			return
		var/datum/db_record/personnel/medical/fossil_record = new()
		fossil_record["id"] = copytext(ref(src.species), -7, -1)
		fossil_record["blood_type"] = src.species.bioHolder.bloodType
		fossil_record["dnasample"] = global.create_new_dna_sample_file(src.species.bioHolder, src.species.get_name_full())
		data_core.medical.add_record(fossil_record)
		src.species.is_recorded = TRUE

	/// Proc is for testing
	proc/activate_all_genes()
		var/list/nonactive_genes = list_keys(src.bioHolder.effectPool) - list_keys(src.bioHolder.effects)
		for(var/gene_id in nonactive_genes)
			var/obj/item/genetics_injector/dna_injector/injector = new(src)
			injector.BE = src.bioHolder.effectPool[gene_id]
			injector.AfterAttack(src, usr)
			qdel(injector)


	get_desc(dist, mob/user)
		. = ..()
		if(!src.species || dist > 1)
			return
		var/fossil_desc
		if(user.mind?.assigned_role == "Geneticist" || user.traitHolder.hasTrait("training_miner"))
			fossil_desc = "Looks like \a <i>[species.name_genus] [species.name_species]</i> fossil, an extinct type of [species.body_category.name]. "
		else
			fossil_desc = "Looks like some kind of [pick("weird","odd-looking","strange","extinct")] [species.body_category.name]. "
		fossil_desc += src.species.body_category.get_fossil_desc(src)
		return fossil_desc


	afterattack(var/atom/A, var/mob/user)
		if(istype(A, /obj/machinery/computer/genetics))
			var/obj/machinery/computer/genetics/genetics_computer = A

			var/list/required_effects = list_keys(src.bioHolder.effectPool) - list_keys(src.bioHolder.effects)
			if(length(required_effects) > 0)
				boutput(user, SPAN_ALERT("[src] is not yet ready for final analysis."))
				return

			var/material_gained = (50 * length(src.slots_preserved)) + 100
			genResearch.researchMaterial += material_gained
			for(var/chromosome_type in concrete_typesof(/datum/dna_chromosome))
				var/datum/dna_chromosome/C = new chromosome_type(src)
				genetics_computer.saved_chromosomes += C
				C = new chromosome_type(src)
				genetics_computer.saved_chromosomes += C
			user.drop_item()
			playsound(genetics_computer, 'sound/machines/scan2.ogg', 125, TRUE)
			boutput(user,SPAN_SUCCESS("[src] submitted for [material_gained] research material and some chromosomes."))


			var/obj/item/fossil_critter_disk/disk = new(get_turf(genetics_computer), src.species)
			disk.bioHolder = new()
			disk.bioHolder.CopyOther(src.bioHolder)
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

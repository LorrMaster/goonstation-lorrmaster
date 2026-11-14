#define ROLE_EXTINCT_CREATURE "extinct_creature"

/mob/living/critter
	var/datum/extinct_species/extinct_species = null

/// A fossil critter that can be player-controlled
/mob/living/critter/extinct
	name = "weird creature"
	desc = " "
	icon_state = "creature"
	icon_state_dead = "creature_dead"
	icon_state_ghost = "creature"
	hand_count = 1
	can_help = TRUE
	can_throw = TRUE
	can_grab = TRUE
	can_disarm = TRUE
	health_brute = 50
	health_burn = 50
	has_genes = TRUE
	void_mindswappable = TRUE
	butcherable = BUTCHER_ALLOWED
	name_the_meat = TRUE
	literate = FALSE
	say_language = LANGUAGE_ANIMAL
	is_npc = TRUE
	ai_type = /datum/aiHolder/wanderer/floor_only
	ai_retaliates = TRUE
	ai_retaliate_patience = 2
	ai_retaliate_persistence = RETALIATE_ONCE

	New(newLoc, var/datum/extinct_species/species)
		. = ..()
		if(!species)
			species = new()
		src.extinct_species = species
		src.name = pick("weird","odd","bizarre","curious","peculiar","strange","eerie","exotic","uncanny","unusual","unknown","quaint","outlandish")
		src.name += " [src.extinct_species.body_category.name]"
		src.icon = src.extinct_species.body_icon
		src.extinct_species.on_spawn(src)

	examine(mob/user)
		. = ..()


	get_desc(dist, mob/user)
		. = ..()
		switch(user.mind?.assigned_role)
			if("Geneticist")
				. = "[pick("Wow","Amazing","Incredible","Unbelievable")]! "
				. += "It's a real-life <i>[src.extinct_species.name_genus] [src.extinct_species.name_species]</i>!"
			if("Chef")
				. = "You wonder what it tastes like."
			if("Rancher")
				. = "Maybe it's hungry?"
			if("Miner")
				. = "Almost looks like it came from a fossil."
			if("Pest Control Specialist")
				. = "Well your pest control training didn't include that."
			if("Quartermaster")
				. = "I wonder if there's a market for this?"
			else
				. = pick(
					"The heck is this...?",
					"Uhh... hello?",
					"You should really start laying off the... whatever it is you're taking.",
					"Whoever's fault this is you're pretty sure it's not yours.")

	setup_healths()
		add_hh_flesh(src.health_brute, src.health_brute_vuln)
		add_hh_flesh_burn(src.health_burn, src.health_burn_vuln)
		add_health_holder(/datum/healthHolder/toxin)
		add_health_holder(/datum/healthHolder/brain)

	valid_target(mob/living/C)
		if(iscritter(C))
			var/mob/living/critter/extinct = C
			if(extinct.extinct_species == src.extinct_species)
				return FALSE
		. = ..()

/// Lazy fossil critter spawning device
/obj/item/fossil_critter_disk
	name = "Fossil Disk"
	icon = 'icons/obj/items/disks.dmi'
	icon_state = "datadisk2"
	item_state = "card-id"
	w_class = W_CLASS_TINY
	var/datum/extinct_species/species = null
	var/ghost_confirmation_delay = 30 SECONDS

	New(newLoc, var/datum/extinct_species/species)
		. = ..()
		if(!species)
			return
		src.species = species
		src.name = "[src.species.name_genus] [src.species.name_species] Disk"
		src.desc = "A complete record of the extinct <i>[src.species.name_genus] [src.species.name_species]</i>."

	afterattack(var/atom/A, var/mob/user)
		if(!istype(A, /obj/machinery/computer/cloning))
			return
		var/obj/machinery/computer/cloning/computer = A
		var/obj/machinery/clonepod/clone_pod = null
		for(var/obj/machinery/clonepod/pod in computer.linked_pods)
			clone_pod = pod
			break
		if(!clone_pod)
			boutput(user, SPAN_ALERT("No clone pods detected."))
			return
		playsound(computer, 'sound/machines/scan2.ogg', 125, TRUE)
		user.drop_item(src)
		src.set_loc(computer)

		// We're gonna spawn the fossil critter out of thin air because this PR is already complicated enough.
		var/mob/living/critter/fossil_critter = new src.species.critter_type(get_turf(clone_pod), src.species)
		src.make_fossil_critter(fossil_critter, user.mind)
		qdel(src)

	proc/make_fossil_critter(var/mob/living/critter/extinct/critter, var/source)
		var/list/text_messages = list()
		text_messages.Add("Would you like to respawn as an extinct creature? Your name will be added to the list of eligible candidates.")
		text_messages.Add("You are eligible to be respawned as an extinct creature. You have [src.ghost_confirmation_delay / 10] seconds to respond to the offer.")
		text_messages.Add("You have been added to the list of eligible candidates. The game will pick a player soon. Good luck!")

		// The proc takes care of all the necessary work (job-banned etc checks, confirmation delay).
		message_admins("Sending [src.species.is_antag ? "antag" : "non-antag"] extinct creature offer to eligible ghosts. They have [src.ghost_confirmation_delay / 10] seconds to respond.")
		var/list/datum/mind/candidates = dead_player_list(1, src.ghost_confirmation_delay, text_messages, allow_dead_antags = FALSE)
		if(!islist(candidates) || length(candidates) <= 0)
			message_admins("Couldn't set up extinct creature ; no ghosts responded. Source: [source]")
			logTheThing(LOG_ADMIN, null, "Couldn't set up extinct creature ; no ghosts responded. Source: [source]")
			return

		var/datum/mind/chosen_player = pick(candidates)
		if(!isobserver(chosen_player.current))
			chosen_player.current.ghostize()
		chosen_player.transfer_to(critter)
		critter.is_npc = FALSE
		critter.mind.assigned_role = "Extinct Animal"
		log_respawn_event(chosen_player, "extinct creature", source)
		message_admins("[key_name(chosen_player)] respawned as an extinct creature by [source].")

		if(src.species.is_antag)
			chosen_player.add_antagonist(ROLE_EXTINCT_CREATURE, source = ANTAGONIST_SOURCE_SUMMONED)

// Temporarily keeping secret species-specific fossil stuff here
/obj/item/fossil
	var/datum/extinct_species/species = null //! Data on what kind of creature was fossilized
	var/list/slots_preserved = list() //! Which parts of the creature's body have been preserved.

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

	proc/on_create_secret()
		if(!length(extinct_species_list) || prob(50 ** (1 / length(extinct_species_list))))
			src.species = new()
		else
			src.species = pick(extinct_species_list)

		var/list/slots_list = list_keys(src.species.body_parts)
		var/preserved_slot = pick(slots_list)
		src.slots_preserved += preserved_slot
		slots_list -= preserved_slot
		// 3% chance for a complete fossil. Keeping it low for now but can increase later.
		var/preserve_prob = (0.03 ** (1 / length(slots_list))) * 100
		for(var/slot in slots_list)
			if(prob(preserve_prob))
				src.slots_preserved += slot

	proc/on_attack_secret(var/obj/machinery/computer/genetics/genetics_computer, var/mob/user)
		if(!src.species || !genetics_computer)
			return
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

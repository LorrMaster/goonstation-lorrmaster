
/// For mob types that are designed for extinct critters
/// Warning: Extinct creatures are not guaranteed to be of this type
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
	has_genes = TRUE
	health_brute = 50
	health_burn = 50
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
		src.health_brute = 50 * species.health_mult
		src.health_burn = 50 * species.health_mult
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
				. = "Maybe it would make for a good stew?"
			if("Rancher")
				. = "Maybe it's hungry?"
			if("Miner")
				. = "Just blame the geneticists."
			if("Pest Control Specialist")
				. = "Well your pest control training didn't include that."
			if("Quartermaster")
				. = "Maybe there's a market for this?"
			else
				. = pick(
					"The heck is this...?",
					"Uhh... hello?",
					"You should really start laying off the... whatever it is you're taking.",
					"Whoever's fault this is it's very likely not yours.")

	setup_healths()
		add_hh_flesh(src.health_brute, src.health_brute_vuln)
		add_hh_flesh_burn(src.health_burn, src.health_burn_vuln)
		add_health_holder(/datum/healthHolder/toxin)
		add_health_holder(/datum/healthHolder/brain)

	valid_target(mob/living/C)
		if(ismobcritter(C))
			var/mob/living/critter/extinct = C
			if(extinct.extinct_species == src.extinct_species)
				return FALSE
		. = ..()

/// A fossil critter that can be player-controlled
/mob/living/critter/extinct/player
	var/static/list/datum/mind/respawn_candidates = list() //! Players who have responded "yes" since the last request
	var/static/time_ask_last = -INFINITY
	var/static/time_ask_wait = 2 MINUTES //! Spam protection
	var/static/ghost_confirmation_delay = 5 SECONDS

	proc/transfer_mind(var/datum/mind/mind)
		if(!mind)
			return
		if(!isobserver(mind.current))
			mind.current.ghostize()
		mind.transfer_to(src)
		src.is_npc = FALSE
		src.mind.assigned_role = "Extinct Creature"
		log_respawn_event(src.mind, "extinct creature", src)
		message_admins("[key_name(src.mind)] respawned as an extinct creature.")

	/// System for asking observers if they want to respawn while trying to avoid spam.
	proc/request_player_new()
		if((time_ask_last + time_ask_wait) < TIME)
			while(length(src.respawn_candidates) > 0)
				var/datum/mind/candidate = pick(src.respawn_candidates)
				// TODO: Check if a player is already part of an existing species and skip them if they are
				src.respawn_candidates -= candidate
				if(!isobserver(candidate.current))
					continue
				src.transfer_mind(candidate)
			return
		time_ask_last = TIME
		var/list/text_messages = list()
		text_messages.Add("Would you like to respawn as an extinct creature? Your name will be added to the list of eligible candidates.")
		text_messages.Add("You are eligible to be respawned as an extinct creature. You have [src.ghost_confirmation_delay / 10] seconds to respond to the offer.")
		text_messages.Add("You have been added to the list of eligible candidates. The game will pick a player soon. Good luck!")
		message_admins("Sending extinct creature respawn offer to eligible ghosts. They have [src.ghost_confirmation_delay / 10] seconds to respond.")
		src.respawn_candidates = dead_player_list(1, src.ghost_confirmation_delay, text_messages, allow_dead_antags = FALSE)
		if(!islist(src.respawn_candidates) || length(src.respawn_candidates) <= 0)
			message_admins("Couldn't set up extinct creature ; no ghosts responded. Source: [src]")
			logTheThing(LOG_ADMIN, null, "Couldn't set up extinct creature ; no ghosts responded. Source: [src]")
			return
		if(QDELETED(src))
			message_admins("Couldn't set up extinct creature ; mob was destroyed")
			logTheThing(LOG_ADMIN, null, "Couldn't set up extinct creature ; mob was destroyed")
			return
		var/datum/mind/candidate = pick(src.respawn_candidates)
		src.respawn_candidates -= candidate
		return candidate


/// Lazy fossil critter spawning device
/obj/item/fossil_critter_disk
	name = "Fossil Disk"
	icon = 'icons/obj/items/disks.dmi'
	icon_state = "datadisk2"
	item_state = "card-id"
	w_class = W_CLASS_TINY
	var/datum/extinct_species/species = null

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
		var/mob/living/critter/fossil_critter = new src.species.niche.critter_type(get_turf(clone_pod), src.species)
		message_admins("[user] has cloned extinct creature [fossil_critter].")
		if(istype(fossil_critter, /mob/living/critter/extinct/player))
			var/mob/living/critter/extinct/player/player_critter = fossil_critter
			var/datum/mind/chosen = player_critter.request_player_new()
			if(chosen)
				player_critter.transfer_mind(chosen)
		qdel(src)

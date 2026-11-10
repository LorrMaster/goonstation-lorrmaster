
/mob/living/critter/extinct
	name = "weird creature"
	desc = ""
	icon_state = "creature"
	icon_state_dead = "creature"
	hand_count = 1
	can_help = TRUE
	can_throw = TRUE
	can_grab = TRUE
	can_disarm = TRUE
	health_brute = 50
	health_burn = 50
	has_genes = TRUE
	var/datum/extinct_species/species_data

	New(newLoc, var/datum/extinct_species/species)
		. = ..()
		if(!species)
			species = new()
		src.name = pick("weird","odd","bizarre","curious","peculiar","strange","eerie","exotic","uncanny","unusual","unknown","quaint","outlandish")
		src.name += " [species.body_category.name]"
		src.icon = species.body_icon
		src.species_data = species
		src.species_data.on_spawn(src)

		src.bioHolder.age = 0

	get_desc(dist, mob/user)
		. = ..()
		switch(user.mind?.assigned_role)
			if("Geneticist")
				. += "[pick("Wow","Amazing","Incredible","Unbelievable")]! "
				. += "It's a real-life <i>[src.species_data.name_genus] [src.species_data.name_species]</i>!"
			if("Chef")
				. += "You wonder what it tastes like."
			if("Rancher")
				. += "Is it hungry?"
			if("Miner")
				. += "Almost looks like it belongs in a fossil."
			if("Pest Control Specialist")
				. += "Well your pest control training didn't include that."
			else
				. += pick(
					"The heck is this...?",
					"Uhh... hello?",
					"You should really start laying off the... whatever it is you're taking.",
					"Whoever's fault this is you're pretty sure it's not yours."
				)

	setup_healths()
		add_hh_flesh(src.health_brute, src.health_brute_vuln)
		add_hh_flesh_burn(src.health_burn, src.health_burn_vuln)
		add_health_holder(/datum/healthHolder/toxin)
		add_health_holder(/datum/healthHolder/brain)

	valid_target(mob/living/C)
		if(istype(C, /mob/living/critter/extinct))
			var/mob/living/critter/extinct/extinct
			if(extinct.species_data == src.species_data)
				return FALSE
		. = ..()


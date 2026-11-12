#define ROLE_EXTINCT_CREATURE "extinct_creature"

/datum/antagonist/mob/fossil_critter
	id = ROLE_EXTINCT_CREATURE
	display_name = "extinct creature"
	remove_on_death = TRUE

	is_compatible_with(datum/mind/mind)
		return TRUE

	give_equipment()
		var/mob/living/critter/critter = src.owner.current
		critter.addAbility(/datum/targetable/critter/bite/extinct)
		critter.addAbility(/datum/targetable/critter/writhe)
		critter.addAbility(/datum/targetable/critter/wasp_sting/extinct)

	remove_equipment()
		. = ..()
		var/mob/living/critter/critter = src.owner.current
		critter.removeAbility(/datum/targetable/critter/bite/extinct)
		critter.removeAbility(/datum/targetable/critter/writhe)
		critter.removeAbility(/datum/targetable/critter/wasp_sting/extinct)

	announce()
		. = ..()
		var/mob/living/critter/critter = src.owner.current
		boutput(src.owner.current, SPAN_ALERT("<b>You have been respawned as a dangerous formerly-extinct species!</b>"))
		boutput(src.owner.current, SPAN_ALERT("<li></li>[critter.extinct_species.body_category.antag_message]"))

/// Placeholder abilities
/datum/targetable/critter/wasp_sting/extinct
	name = "Sting (neurotoxin)"
	icon_state = "scorpion_sting"
	desc = "Sting a mob, injecting them with 35 units of neurotoxin."
	cooldown = 120 SECONDS
	venom1 = "neurotoxin"
	amt1 = 35
	venom2 = "toxin"
	amt2 = 0

/datum/targetable/critter/bite/extinct
	cooldown = 5 SECONDS

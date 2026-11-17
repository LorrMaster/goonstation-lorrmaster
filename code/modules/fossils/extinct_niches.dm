/// Determines what type of mob will spawn. Can give them abilities themed around a certain survival strategy.
ABSTRACT_TYPE(/datum/extinct_niche)
/datum/extinct_niche
	var/name = "unnamed niche"
	var/critter_type = /mob/living/critter/extinct
	var/list/potential_genes = list() //! This creature is likely to start out with some of these genes

/datum/extinct_niche/bottomfeeder
	name = "bottom feeder"
	potential_genes = list(
		/datum/bioEffect/toxres,
		/datum/bioEffect/detox,
		/datum/bioEffect/nightvision,
		/datum/bioEffect/shortsighted
	)
	New(var/datum/extinct_species/species)
		. = ..()
		species.bioHolder.AddNewPoolEffect("bottomfeeder", TRUE)
		species.bioHolder.AddEffect("bottomfeeder", do_stability = FALSE, scannable = TRUE, innate = TRUE)
		return

/datum/extinct_niche/chicken
	name = "chicken-like creature"
	critter_type = /mob/living/critter/small_animal/ranch_base/chicken/extinct/ai_controlled
	potential_genes = list(
		/datum/bioEffect/fastSounds,
		/datum/bioEffect/food_stores,
		/datum/bioEffect/clumsy,
		/datum/bioEffect/power/mattereater
	)
	var/favorite_flag
	var/impressionable = FALSE
	var/hens_fight = FALSE
	var/hyperaggressive = FALSE
	var/befriend_with_feed = FALSE
	var/befriend_with_pets = FALSE
	var/forgiving = FALSE
	var/forgive_species = FALSE
	var/negative_happiness = FALSE
	var/crowded_minimum = 15
	var/list/egg_effects = list() //! Food effects for eggs laid by this species

	New(var/datum/extinct_species/species)
		. = ..()
		// Make our random creature have random chicken properties
		// These creatures aren't quite as domesticated and docile as the actual chickens
		src.favorite_flag = pick("rice","spicy","wheat","fish","synth","peanut","chicken_meat","banana")
		src.impressionable = prob(50)
		src.hens_fight = prob(25)
		src.hyperaggressive = prob(15)
		src.forgive_species = prob(25)
		if(src.forgive_species)
			src.forgiving = prob(25)
		src.befriend_with_feed = prob(50)
		src.befriend_with_pets = prob(50)
		src.negative_happiness = prob(75)
		src.crowded_minimum = rand(10, 20)

		// IDK, just pick some random food effects for the eggs
		var/list/potential_effects = list("space_splice", "c_power", "photosynthesis", "empulsar", "crunched", \
			"sugar_rush", "aquabreath", "supersleep", "frozen", "haunted", "missile", "fear", \
			"popsicle", "egg_defense", "food_fireburp", "food_cateyes", "food_explosion_resist", "food_disease_resist", \
			"food_rad_resist", "food_brute", "food_tox", "food_burn", "food_cold", "food_warm", "food_all", "food_hp_up")
		var/effect_count = rand(2, 3)
		for(var/i in 1 to effect_count)
			var/effect = pick(potential_effects)
			potential_effects -= effect
			src.egg_effects += effect
		return

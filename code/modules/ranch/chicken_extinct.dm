/obj/item/reagent_containers/food/snacks/ingredient/egg/chicken/extinct
	name = "strange egg"
	desc = "The perfect combination of cute and gross."
	initial_reagents = list("black_goop" = 5)
	egg_props_path = /datum/chicken_egg_props/extinct
	var/datum/extinct_species/species = null

	proc/set_species(var/datum/extinct_species/species)
		src.species = species
		var/datum/extinct_niche/chicken/chicken_niche = species.niche
		src.food_effects = chicken_niche.egg_effects.Copy()
		src.color = species.associated_color
		src.name = "[species.body_category.name] egg"


/datum/chicken_egg_props/extinct
	chicken_id = "extinct"
	hen_type = /mob/living/critter/small_animal/ranch_base/chicken/extinct/ai_controlled
	rooster_type = /mob/living/critter/small_animal/ranch_base/chicken/extinct/rooster/ai_controlled
	gender_balance = 50

	BeforeHatch()
		. = ..()
		var/obj/item/reagent_containers/food/snacks/ingredient/egg/chicken/extinct/egg = src.owner
		src.arguments = list(species = egg.species)


/obj/item/reagent_containers/food/snacks/ingredient/meat/mysterymeat/nugget/ranch_chicken/extinct
	name = "exotic nugget"
	desc = "An exotic meat that tastes like chicken despite clearly not being one."
	icon_state = "nugget-extinct"


/datum/ranch/evolution/chicken/extinct
	evolution_priority = -1
	check_evolution_conditions(mob/living/critter/small_animal/ranch_base/C)
		. = ..()

	evolve(mob/living/critter/small_animal/ranch_base/C)
		. = ..()
		var/mob/living/critter/small_animal/ranch_base/chicken/N = C
		N.egg_type = /obj/item/reagent_containers/food/snacks/ingredient/egg/chicken/extinct


/// It tastes like chicken so it's basically the same thing.
/// Would probably be better as its own type of ranch critter, but this is good enough for now
/mob/living/critter/small_animal/ranch_base/chicken/extinct
	desc = "Aww, it's an adorable small baby... thing."
	egg_type = /obj/item/reagent_containers/food/snacks/ingredient/egg/chicken/extinct
	species_type = /mob/living/critter/small_animal/ranch_base/chicken/extinct
	base_evolution_type = /datum/ranch/evolution/chicken/extinct
	attack_ability_type = /datum/targetable/critter/tackle
	chicken_id = "extinct"
	happiness = 0

	butcher_time = 0.5 SECONDS
	meat_type = /obj/item/reagent_containers/food/snacks/ingredient/meat/mysterymeat/nugget/ranch_chicken/extinct

	is_masc = FALSE // First critter needs to always be a hen or it will just go back into extinction
	critter_scream_sound = 'sound/misc/talk/roach_exclaim.ogg'

	New(newLoc, var/datum/extinct_species/species = null)
		. = ..()
		if(!species)
			var/niche_type = extinct_niche_ofmobtype(/mob/living/critter/small_animal/ranch_base/chicken/extinct)
			species = new(niche_type = niche_type)
		src.extinct_species = species
		src.extinct_species.on_spawn(src)
		src.real_name = src.name

		// Try and make babies easier to see
		var/list/baby_color = list(1.00, 0.25, 0.25, 0.00,\
								0.25, 1.00, 0.25, 0.00,\
								0.25, 0.25, 1.00, 0.00,\
								0.00, 0.00, 0.00, 1.00,\
								0.00, 0.00, 0.00, 0.00)
		src.add_filter("extinct_baby_color", 10, color_matrix_filter(baby_color, COLORSPACE_RGB))
		src.transform = matrix(0.75,0,0,0,0.75,0)

		var/datum/extinct_niche/chicken/niche = src.extinct_species.niche
		src.favorite_flag = niche.favorite_flag
		src.impressionable = niche.impressionable
		src.hens_fight = niche.hens_fight
		src.hyperaggressive = niche.hyperaggressive
		src.befriend_with_feed = niche.befriend_with_feed
		src.befriend_with_pets = niche.befriend_with_pets
		src.forgiving = niche.forgiving
		src.forgive_species = niche.forgive_species
		src.negative_happiness = niche.negative_happiness
		src.crowded_minimum = niche.crowded_minimum

	grow_up()
		src.stage = RANCH_STAGE_ADULT
		src.flags = src.flags & ~DOORPASS
		if(src.ai)
			src.ai.stop_move()
			src.ai.interrupt()
		src.transform = matrix(1,0,0,0,1,0)
		src.remove_filter("extinct_baby_color")
		critter_scream_pitch = 1
		desc = "It can actually look very cute if you look at it from the right distance and angle."

	death(var/gibbed, var/do_drop_equipment = 1)
		..()
		desc = "Oh no, not again!"

	lay_egg()
		. = ..()
		var/obj/item/reagent_containers/food/snacks/ingredient/egg/chicken/extinct/egg = .
		egg.set_species(src.extinct_species)
		src.desc = "Maybe this thing is the future of ranching?"

	rooster
		is_masc = TRUE
	rooster/ai_controlled
		is_npc = 1
	ai_controlled
		is_npc = 1

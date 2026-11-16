// ================================================================================================================
// ================================================= Bottom Feeder ================================================
// ================================================================================================================

/// Mobs drink cleanables and fluids off of the ground. Only works while lying down unless if you are a critter.
/// Critters can also toggle the ability on/off at will.
/datum/bioEffect/power/bottomfeeder
	name = "Bottom Feeder"
	desc = "Allows the subject to slurp floors clean while lying down."
	id = "bottomfeeder"
	icon_state = "locomotion"
	msgGain = "The floor suddenly looks very appetizing."
	msgLose = "The floor now looks completely disgusting."
	probability = 0
	blockCount = 4
	blockGaps = 7
	occur_in_genepools = FALSE
	stability_loss = 5
	degrade_to = "stinky"
	ability_path = /datum/targetable/geneticsAbility/bottomfeeder

	OnAdd()
		if(src.owner && !ismobcritter(src.owner))
			ability_path = null // Only critters can toggle using the ability. Mostly just to minimize ability clutter.
		. = ..()
		RegisterSignal(src.owner, COMSIG_MOVABLE_MOVED, PROC_REF(bottomfeed))

	OnRemove()
		. = ..()
		UnregisterSignal(src.owner, COMSIG_MOVABLE_MOVED)

	proc/bottomfeed()
		var/datum/targetable/geneticsAbility/bottomfeeder/bottomfeed = src.ability
		if(bottomfeed && !bottomfeed.is_active)
			return
		if(!ismobcritter(src.owner) && !src.owner.lying)
			return
		if(!isturf(src.owner.loc))
			return
		var/turf/T = src.owner.loc
		var/drank_something = FALSE
		if(T.active_liquid?.group)
			var/datum/reagents/R = T.active_liquid.group.reagents
			R.reaction(src.owner, INGEST, clamp(R.total_volume, CHEM_EPSILON, 25))
			R.trans_to(src.owner, min(R.total_volume, 25))
			drank_something = TRUE
		for(var/obj/decal/cleanable/mess in T.contents)
			if(mess.reagents)
				mess.reagents.trans_to(src.owner)
			if(mess.sample_reagent)
				src.owner.reagents?.add_reagent(mess.sample_reagent, mess.sample_amt)
			if(ishuman(src.owner))
				var/mob/living/carbon/human/H = src.owner
				H.sims.affectMotive("Hunger", 1 * src.power)
			drank_something = TRUE
			qdel(mess)
		if(drank_something)
			playsound(src.owner, 'sound/items/drink.ogg', 50, TRUE)
			eat_twitch(src.owner)

/// Only available to critters.
/datum/targetable/geneticsAbility/bottomfeeder
	name = "Bottom Feeder"
	desc = "Toggle bottom feeder ability."
	icon_state = "locomotion"
	targeted = FALSE
	needs_hands = FALSE
	cooldown = 0
	var/is_active = FALSE

	onAttach(datum/abilityHolder/H)
		. = ..()
		if(isliving(H.owner))
			var/mob/living/L = H.owner
			src.is_active = L.is_npc // Auto-enable for NPCs

	cast_genetics(atom/target, misfire)
		if (..())
			return CAST_ATTEMPT_FAIL_CAST_FAILURE
		if(src.is_active)
			boutput(src.owner, "Bottom Feeder is now inactive.")
		else
			boutput(src.owner, "Bottom Feeder is now active.")
		src.is_active = !src.is_active
		return CAST_ATTEMPT_SUCCESS


// ================================================================================================================
// ================================================== Egg Laying ==================================================
// ================================================================================================================

/obj/extinct_egg
	name = "large egg"
	desc = "Both cute and gross at the same time. It's very delicate."
	icon = 'icons/mob/critter/nonhuman/extinct/arthropod.dmi'
	icon_state = "egg_large"
	var/datum/extinct_species/species = null
	var/mob/living/critter/larva = null
	var/delay_hatch = 5 SECONDS //! Time to wait after a player has been chosen
	var/temperature_min = T0C
	var/temperature_max = T100C

	New(newLoc, datum/extinct_species/species)
		. = ..()
		if(!species)
			species = new()
		src.species = species

	get_desc(dist, mob/user)
		. = ..()
		switch(user.mind.assigned_role)
			if("Pest Control Specialist")
				. += "That egg could probably be killed at temperatures outside [src.temperature_min]K and [src.temperature_max]K."

	get_help_message(dist, mob/user)
		. = {"Can be destroyed through physical damage or exposure to high/low temperatures."}

	attack_hand(mob/user)
		. = ..()
		if(istype(user, /mob/living/critter))
			var/mob/living/critter/critter = user
			if(critter.extinct_species == src.species)
				boutput(critter, "Be careful around the egg, it can break very easily!")
				return
		user.visible_message(SPAN_ALERT("[user] smashes \the [src]!"), SPAN_ALERT("You smash \the [src]!"))
		src.break_egg(TRUE)

	attackby(obj/item/I, mob/user)
		. = ..()
		if(istype(user, /mob/living/critter))
			var/mob/living/critter/critter = user
			if(critter.extinct_species == src.species)
				boutput(critter, "Be careful around the egg, it can break very easily!")
				return
		user.visible_message(SPAN_ALERT("[user] smashes \the [src]!"), SPAN_ALERT("You smash \the [src]!"))
		src.break_egg(TRUE)

	ex_act(severity)
		. = ..()
		src.visible_message(SPAN_ALERT("The force of the explosion shatters \the [src]!"))
		src.break_egg(TRUE)

	bullet_act(obj/projectile/P)
		. = ..()
		src.visible_message(SPAN_ALERT("The force of the [P] pierces \the [src]!"))
		src.break_egg(TRUE)

	temperature_expose(datum/gas_mixture/air, exposed_temperature, exposed_volume, cannot_be_cooled)
		. = ..()
		src.temperature_check(exposed_temperature)

	hitby(atom/movable/AM, datum/thrown_thing/thr)
		. = ..()
		if(thr.bonus_throwforce >= 5)
			src.break_egg(TRUE)
		if(!isitem(AM))
			return
		var/obj/item/I = AM
		if(HAS_ANY_FLAGS(I.hit_type, DAMAGE_CUT | DAMAGE_STAB) || (I.w_class >= W_CLASS_BULKY))
			src.break_egg(TRUE)

	proc/temperature_check(var/temperature)
		if(temperature > src.temperature_max)
			src.visible_message(SPAN_ALERT("The heat burns open \the [src]!"))
			src.break_egg(TRUE)
		else if(temperature < src.temperature_min)
			src.visible_message(SPAN_ALERT("The cold completely ruins \the [src]!"))
			src.break_egg(TRUE)

	proc/hatch_egg()
		SPAWN(src.delay_hatch)
			if(QDELETED(src))
				return
			src.break_egg(FALSE)

	proc/break_egg(var/smashed)
		if(src.larva)
			src.larva.set_loc(src.loc)
			if(smashed)
				src.larva.gib()
		var/obj/decal/cleanable/extinct_egg_broken/broken = new(src.loc)
		broken.icon = src.icon
		broken.icon_state = "[src.icon_state]_broken"
		playsound(src, 'sound/impact_sounds/Flesh_Crush_1.ogg', 80, TRUE)
		qdel(src)

/obj/decal/cleanable/extinct_egg_broken
	name = "broken egg"
	desc = "What a mess."
	icon = 'icons/mob/critter/nonhuman/extinct/arthropod.dmi'

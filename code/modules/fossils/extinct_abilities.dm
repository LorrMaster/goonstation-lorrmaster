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
	effectType = EFFECT_TYPE_POWER
	can_research = FALSE // Fossil-exclusive genes should not be visible until the creature is cloned
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


/// Basically a passive short-range geological scanner. Also tells you where distant explosions came from.
/datum/bioEffect/geosense
	name = "Geo-Sense"
	desc = "Subject gains an acute perception of their geological surroundings."
	id = "geosense"
	icon_state = "locomotion"
	msgGain = "You feel very sensitive to various distant vibrations."
	msgLose = "The vibrations around you have silenced."
	probability = 0
	blockCount = 4
	// blockGaps = 9
	occur_in_genepools = FALSE
	effectType = EFFECT_TYPE_POWER
	can_research = FALSE // Fossil-exclusive genes should not be visible until the creature is cloned
	stability_loss = 10
	degrade_to = "clumsy"

	OnAdd()
		. = ..()
		RegisterSignal(src.owner, COMSIG_MOVABLE_MOVED, PROC_REF(sense_geology))
		get_image_group(CLIENT_IMAGE_GROUP_GEOLOGICAL_ANOMALIES).add_mob(src.owner)

	OnRemove()
		. = ..()
		UnregisterSignal(src.owner, COMSIG_MOVABLE_MOVED)
		get_image_group(CLIENT_IMAGE_GROUP_GEOLOGICAL_ANOMALIES).remove_mob(src.owner)

	proc/sense_geology(atom/movable/thing, atom/previous_loc, var/direction)
		if(!src.owner.client)
			return
		if((src.owner.traction == TRACTION_NONE) && !src.owner.has_grip()) // Don't sense anything while floating in space
			return
		var/sense_range = src.power
		for(var/turf/simulated/wall/auto/asteroid/AST in view(get_turf(src.owner), sense_range))
			var/datum/ore/event/E = AST.event
			if(!E)
				continue
			if(E.scan_decal)
				mining_scandecal(src.owner, AST, E.scan_decal)
			if(src.power >= 2 && istype(E, /datum/ore/event/fossil))
				var/datum/ore/event/fossil/fossil_event = E
				fossil_event.reveal_fossil(AST)

	/// Called when the camera shakes due to a distant explosion.
	proc/sense_explosion(turf/source)
		var/turf/T = get_turf(src.owner)
		if((src.owner.traction == TRACTION_NONE) && !src.owner.has_grip()) // In space no one can hear you explode.
			return
		var/dist = get_dist(T, source)
		var/exp_message
		if(dist < 12)
			exp_message = "The explosion came from the "
		else if(dist < 64)
			exp_message = "You feel a nearby explosion coming from the "
		else
			exp_message = "You feel a distant explosion coming from the "

		if(src.power >= 2)
			var/area/source_area = get_area(source)
			if(isarea(source_area) && !istype(source_area, /area/space) && (source_area.teleport_blocked != AREA_TELEPORT_BLOCKED))
				boutput(src.owner, SPAN_ALERT(exp_message + "[source_area]!"))
				return
		var/direction = dir2text(get_dir_accurate(T, source, TRUE))
		boutput(src.owner, SPAN_ALERT(exp_message + "[direction]!"))


/// Mobs drink cleanables and fluids off of the ground. Only works while lying down unless if you are a critter.
/// Also grants immunity from vomit, compost, and miasma clouds
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
	// blockGaps = 7
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

	proc/bottomfeed(atom/movable/thing, atom/previous_loc, var/direction)
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

/// Toggle button that is only available to critters.
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

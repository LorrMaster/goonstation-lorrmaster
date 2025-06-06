/*
Contains:
-Singularity generator
-Singularity
-Field generator & containment field
-Emitter
-Collector array & controller
-Singularity bomb
*/
// I came here with good intentions, I swear, I didn't know what this code was like until I was already waist deep in it
#define SINGULARITY_TIME 11
#define SINGULARITY_MAX_DIMENSION 11//defines the maximum dimension possible by a player created singularity.
#define DEFAULT_AREA 25
#define EVENT_GROWTH 3//the rate at which the event proc radius is scaled relative to the radius of the singularity
#define EVENT_MINIMUM 5//the base value added to the event proc radius, serves as the radius of a 1x1
#define UNWRENCHED 0
#define WRENCHED 1
#define WELDED 2

#ifdef UPSCALED_MAP
#undef SINGULARITY_MAX_DIMENSION
#define SINGULARITY_MAX_DIMENSION 22
#endif

/**
 * Checks if there is a containment field in each direction from the center turf. If not returns null.
 * If yes returns the distance to the closest field.
 */
proc/singularity_containment_check(turf/center)
	var/min_dist = INFINITY
	for(var/dir in alldirs)
		var/turf/T = center
		var/found_field = FALSE
		for(var/i in 1 to 20)
			T = get_step(T, dir)
			if(locate(/obj/machinery/containment_field) in T)
				min_dist = min(min_dist, i)
				found_field = TRUE
				break
			// in case people make really big singulo cages using multiple generators we want to count an active generator as a containment field too
			for(var/obj/machinery/field_generator/gen in T)
				if(gen.active && gen.active_dirs != 0) // TODO: require at least two dirs maybe? but note that active_dirs is a BIT FIELD
					found_field = TRUE
					min_dist = min(min_dist, i)
					break
		if(!found_field)
			return null
	return min_dist

//////////////////////////////////////////////////// Singularity generator /////////////////////

TYPEINFO(/obj/machinery/the_singularitygen)
	mats = 250

ADMIN_INTERACT_PROCS(/obj/machinery/the_singularitygen, proc/activate)

/obj/machinery/the_singularitygen
	name = "Gravitational Singularity Generator"
	desc = "An Odd Device which produces a Black Hole when set up."
	icon = 'icons/obj/singularity.dmi'
	icon_state = "TheSingGen"
	anchored = UNANCHORED // so it can be moved around out of crates
	density = 1
	var/bhole = 0 // it is time. we can trust people to use the singularity For Good - cirr
	var/activating = FALSE

	HELP_MESSAGE_OVERRIDE({"Automatically creates a singularity when all surrounding containment fields are active.\
							Can be anchored/unanchored with a <b>wrench</b>"})

/obj/machinery/the_singularitygen/process()
	if (src.activating)
		return
	var/max_radius = singularity_containment_check(get_turf(src))
	if(isnull(max_radius))
		return

	logTheThing(LOG_BOMBING, src.fingerprintslast, "A [src.name] was activated, spawning a singularity at [log_loc(src)]. Last touched by: [src.fingerprintslast ? "[src.fingerprintslast]" : "*null*"]")
	message_admins("A [src.name] was activated, spawning a singularity at [log_loc(src)]. Last touched by: [key_name(src.fingerprintslast)]")

	var/turf/T = get_turf(src)
	if(isrestrictedz(T?.z))
		src.visible_message(SPAN_NOTICE("[src] refuses to activate in this place. Odd."))
		qdel(src)

	src.activate(max_radius)

/obj/machinery/the_singularitygen/proc/activate(max_radius = null)
	src.activating = TRUE
	var/turf/T = get_turf(src)
	playsound(T, 'sound/machines/singulo_start.ogg', 90, FALSE, 3, flags=SOUND_IGNORE_SPACE)
	src.icon_state = "TheSingGenOhNo"
	SPAWN(7 SECONDS)
		if (src.bhole)
			new /obj/bhole(T, 3000)
		else
			new /obj/machinery/the_singularity(T, 100,,max_radius)
		qdel(src)

/obj/machinery/the_singularitygen/attackby(obj/item/W, mob/user)
	src.add_fingerprint(user)
	if (iswrenchingtool(W))
		if (!anchored)
			anchored = ANCHORED
			playsound(src.loc, 'sound/items/Ratchet.ogg', 75, 1)
			boutput(user, "You secure the [src.name] to the floor.")
			src.anchored = ANCHORED
		else if (anchored)
			anchored = UNANCHORED
			playsound(src.loc, 'sound/items/Ratchet.ogg', 75, 1)
			boutput(user, "You unsecure the [src.name].")
			src.anchored = UNANCHORED

		logTheThing(LOG_STATION, user, "[src.anchored ? "bolts" : "unbolts"] a [src.name] [src.anchored ? "to" : "from"] the floor at [log_loc(src)].") // Ditto (Convair880).
		return
	else
		return ..()

//////////////////////////////////////////////////// Singularity /////////////////////////////

/obj/machinery/the_singularity/
	name = "gravitational singularity"
	desc = "Perhaps the densest thing in existence, except for you."

	plane = PLANE_DEFAULT_NOWARP
	icon = 'icons/effects/64x64.dmi'
	icon_state = "whole"
	anchored = ANCHORED
	density = 1
	event_handler_flags = IMMUNE_SINGULARITY | IMMUNE_TRENCH_WARP
	deconstruct_flags = DECON_NONE
	flags = 0 // no fluid submerge images and we also don't need tgui interactability


	pixel_x = -16
	pixel_y = -16

	var/has_moved
	var/active = 0 //determines if the singularity is contained
	var/energy = 10
	var/lastT = 0
	var/Dtime = null
	var/Wtime = 0
	var/dieot = 0
	var/selfmove = 1
	var/grav_pull = 6
	var/radius = 0 //the variable used for all calculations involving size.this is the current size
	var/maxradius = INFINITY//the maximum size the singularity can grow to
	var/restricted_z_allowed = FALSE
	var/right_spinning //! boolean for the spaghettification animation spin direction
	///Count for rate-limiting the spaghettification effect
	var/spaget_count = 0
	var/katamari_mode = FALSE //! If true the sucked-in objects will get stuck to the singularity
	var/num_absorbed = 0 //! Number of objects absorbed by the singularity
	var/num_absorbed_players = 0 //! number of players absorbed
	var/gib_mobs = 0 //! if it should call gib on mobs
	var/list/obj/succ_cache

	/// Targeted turf when loose
	var/turf/target_turf
	/// How many steps we'll continue to walk towards the target turf before rerolling
	var/target_turf_counter = 0

#ifdef SINGULARITY_TIME
/*
hello I've lost my remaining sanity by dredging this code from the depths of hell where it was cast eons before I arrived in this place
for some reason I brought it back and tried to clean it up a bit and I regret everything but it's too late now I can't put it back please forgive me
- haine
*/
/obj/machinery/the_singularity/New(loc, var/E = 100, var/Ti = null,var/rad = 2)
	START_TRACKING
	START_TRACKING_CAT(TR_CAT_GHOST_OBSERVABLES)
	src.energy = E
	maxradius = rad
	succ_cache = list()
	if(maxradius<2)
		radius = maxradius
	else
		radius = 2
	SafeScale((radius+1)/3.0,(radius+1)/3.0)
	grav_pull = (radius+1)*3
	event()
	if (Ti)
		src.Dtime = Ti
	right_spinning = prob(50)

	var/offset = rand(1000)
	add_filter("loose rays", 1, rays_filter(size=1, density=10, factor=0, offset=offset, threshold=0.2, color="#c0c", x=0, y=0))
	animate(get_filter("loose rays"), offset=offset+60, time=5 MINUTES, easing=LINEAR_EASING, flags=ANIMATION_PARALLEL, loop=-1)

	//get all bendy

	var/image/lense = image(icon='icons/effects/overlays/lensing.dmi', icon_state="lensing_med_hole", pixel_x = -208, pixel_y = -208)
	lense.plane = PLANE_DISTORTION
	lense.blend_mode = BLEND_OVERLAY
	lense.appearance_flags = RESET_ALPHA | RESET_COLOR
	src.UpdateOverlays(lense, "grav_lensing")
	..()

/obj/machinery/the_singularity/disposing()
	STOP_TRACKING
	STOP_TRACKING_CAT(TR_CAT_GHOST_OBSERVABLES)
	. = ..()

/obj/machinery/the_singularity/process()
	var/turf/T = get_turf(src)
	if(isrestrictedz(T?.z) && !src.restricted_z_allowed)
		src.visible_message(SPAN_NOTICE("Something about this place makes [src] wither and implode."))
		qdel(src)
	eat()

	if (src.Dtime)//If its a temp singularity IE: an event
		if (Wtime != 0)
			if ((src.Wtime + src.Dtime) <= world.time)
				src.Wtime = 0
				qdel (src)
		else
			src.Wtime = world.time

	if (dieot)
		if (energy <= 0)//slowly dies over time
			qdel (src)
		else
			energy -= 15


	if (prob(20))//Chance for it to run a special event
		event()

	if (active == 1)
		move()
		SPAWN(2 SECONDS) // slowing this baby down a little -drsingh // smoother movement
			move()

			var/recapture_prob = clamp(25-(radius**2) , 0, 25)
			if(prob(recapture_prob))
				var/check_max_radius = singularity_containment_check(get_turf(src))
				if(!isnull(check_max_radius) && check_max_radius >= radius)
					src.active = FALSE
					animate(get_filter("loose rays"), size=1, time=5 SECONDS, easing=LINEAR_EASING, flags=ANIMATION_PARALLEL, loop=1)
					maxradius = check_max_radius
					logTheThing(LOG_STATION, null, "[src] has been contained (at maxradius [maxradius]) at [log_loc(src)]")
					message_admins("[src] has been contained (at maxradius [maxradius]) at [log_loc(src)]")

	else
		var/check_max_radius = singularity_containment_check(get_turf(src))
		if(isnull(check_max_radius) || check_max_radius < radius)
			src.active = TRUE
			animate(get_filter("loose rays"), size=100, time=5 SECONDS, easing=LINEAR_EASING, flags=ANIMATION_PARALLEL, loop=1)
			maxradius = INFINITY
			logTheThing(LOG_STATION, null, "[src] has become loose at [log_loc(src)]")
			message_admins("[src] has become loose at [log_loc(src)]")
			message_ghosts("<b>[src]</b> has become loose at [log_loc(src, ghostjump=TRUE)].")


/obj/machinery/the_singularity/emp_act()
	return // No action required this should be the one doing the EMPing

/obj/machinery/the_singularity/proc/eat()

	var/turf/sing_center = src.get_center()
	for (var/turf/T in range(grav_pull, sing_center))
		var/max_affected_atoms_per_turf = 30
		for(var/atom/A in list(T) + T.contents)
			if (max_affected_atoms_per_turf-- <= 0)
				break

			if (A == src)
				continue

			if (A.event_handler_flags & IMMUNE_SINGULARITY)
				continue

			if (!active)
				if (A.event_handler_flags & IMMUNE_SINGULARITY_INACTIVE)
					continue

			if(IN_EUCLIDEAN_RANGE(sing_center, A, radius+0.5))
				src.Bumped(A)
			else if (istype(A, /atom/movable))
				var/atom/movable/AM = A
				if (!AM.anchored)
					step_towards(AM, src)

/obj/machinery/the_singularity/proc/move()
	// if we're inside something (e.g posessed mob) dont move
	if (!isturf(src.loc))
		return

	if (selfmove)
		var/list/vector = src.calc_direction()
		var/next_dir = pick(alldirs)

		if (src.target_turf_counter <= 0)
			if (prob(20)) // drift towards a random station turf for a few steps
				src.target_turf = get_random_station_turf()
				src.target_turf_counter = rand(radius,radius*2)
		else
			if (!src.target_turf)
				src.target_turf = get_random_station_turf()
			src.target_turf_counter--
			next_dir = get_dir_accurate(src, src.target_turf)

		var/vector_length = (vector[1] ** 2 + vector[2] ** 2) ** (1/2)
		if (prob(vector_length * 400)) //scale the chance to move in the direction of resultant force by the strength of that force
			var/angle = arctan(vector[2], vector[1])
			next_dir = angle2dir(angle)

		// don't cross containment fields
		for (var/dist = max(0,radius-1), dist <= radius+1, dist++)
			var/turf/checkloc = get_ranged_target_turf(src.get_center(), next_dir, dist)
			if (locate(/obj/machinery/containment_field) in checkloc)
				return

		step(src, next_dir)

///Returns a 2D vector representing the resultant force acting on the singulo by all gravity wells, scaled by their distance
/obj/machinery/the_singularity/proc/calc_direction()
	var/list/total_vector = list(0,0) //if only we had vector primitives...
	var/turf/singulo_turf = get_turf(src)
	//unfortunately these are two unrelated types that both have special behaviour so this is going to get messy
	for(var/atom/movable/magnet as anything in by_cat[TR_CAT_SINGULO_MAGNETS])
		var/turf/magnet_turf = get_turf(magnet)
		if (magnet_turf.z != singulo_turf.z)
			continue

		var/sign = -1 //default to pull
		if (istype(magnet, /obj/machinery/artifact))
			var/obj/machinery/artifact/artifact = magnet
			var/datum/artifact/gravity_well_generator/artifact_datum = artifact.artifact
			if (istype(artifact_datum) && !artifact_datum.activated)
				continue
			if (artifact_datum.gravity_type == 1)
				sign = 1 //push
		if (istype(magnet, /obj/gravity_well_generator))
			var/obj/gravity_well_generator/generator = magnet
			if (!generator.active)
				continue

		//our actual offset from this magnet
		var/list/vector = list(0,0)
		vector[1] = ((singulo_turf.x - magnet_turf.x) * sign)
		vector[2] = ((singulo_turf.y - magnet_turf.y) * sign)
		//no need to root, we can reuse the squared value (I'm basically a doom programmer)
		var/length_squared = (vector[1] ** 2) + (vector[2] ** 2)
		//inverse square law I guess? gravity is radial
		total_vector[1] += vector[1] * 1/length_squared
		total_vector[2] += vector[2] * 1/length_squared
	return total_vector

/obj/machinery/the_singularity/ex_act(severity, last_touched, power)
	if (severity == 1 && prob(power * 5)) //need a big bomb (TTV+ sized), but a big enough bomb will always clear it
		var/turf/T = get_turf(src)
		qdel(src)
		new /obj/bhole(T,rand(100,300))

/obj/machinery/the_singularity/Bumped(atom/A)
	if(istype(A, /obj/dummy))
		return

	if (A.event_handler_flags & IMMUNE_SINGULARITY)
		return
	if (!active)
		if (A.event_handler_flags & IMMUNE_SINGULARITY_INACTIVE)
			return

	if(QDELETED(A)) // Don't bump that which no longer exists
		return
	src.consume_atom(A)

/obj/machinery/the_singularity/proc/consume_atom(atom/A, no_visuals = FALSE)
	var/gain = 0

	if(!no_visuals)
		num_absorbed++
		if(src.spaget_count < 25 && !katamari_mode)
			src.spaget_count++
			animate_spaghettification(A, src, 15 SECONDS, right_spinning)
			SPAWN(16 SECONDS)
				src.spaget_count-- //this is fine, it doesn't need to be tick perfect
		else if(katamari_mode)
			var/obj/dummy/kat_overlay = new()
			kat_overlay.appearance = A.appearance
			kat_overlay.appearance_flags = RESET_COLOR | RESET_ALPHA | PIXEL_SCALE | RESET_TRANSFORM
			kat_overlay.pixel_x = 0
			kat_overlay.pixel_y = 0
			kat_overlay.vis_flags = 0
			kat_overlay.plane = PLANE_NOSHADOW_ABOVE
			kat_overlay.layer = src.layer + rand()
			kat_overlay.mouse_opacity = 0
			kat_overlay.alpha = 64
			var/matrix/tr = new
			tr.Turn(randfloat(0, 360))
			tr.Translate(sqrt(num_absorbed) * 3 + 16 - 16, -16)
			tr.Turn(randfloat(0, 360))
			tr.Translate(-pixel_x, -pixel_y)
			kat_overlay.transform = tr
			src.underlays += kat_overlay

	if (isliving(A) && !isintangible(A))//if its a mob
		var/mob/living/L = A
		L.set_loc(src.get_center())
		gain = 20
		if (ishuman(L))
			var/mob/living/carbon/human/H = A
			//Special halloween-time Unkillable gibspam protection!
			if (H.unkillable)
				H.unkillable = 0
			H.dump_contents_chance = 100 // zamu being funny here for the crunchy gib mode
			if (H.mind && H.mind.assigned_role)
				logTheThing(LOG_COMBAT, H, "is spaghettified by \the [src] at [log_loc(src)].")
				src.num_absorbed_players++
				switch (H.mind.assigned_role)
					if ("Clown")
						// Hilarious.
						gain = 500
						grow()
					if ("Lawyer")
						// Satan.
						gain = 250
					if ("Tourist", "Geneticist")
						// Nerds that are oblivious to dangers
						gain = 200
					if ("Chief Engineer")
						// Hubris
						gain = 150
					if ("Engineer")
						// More hubris
						gain = 100
					if ("Staff Assistant", "Captain")
						// Worthless
						gain = 20
					else
						gain = 50

		if (gib_mobs)
			// this also ghostize/qdels.
			L.gib()
		else
			L.ghostize()
			qdel(L)

	else if (isobj(A))
		//if (istype(A, /obj/item/graviton_grenade))
			//src.warp = 100
		if (istype(A.material))
			gain += A.material.getProperty("density") * 3 * A.material_amt
			gain += A.material.getProperty("radioactive") * 4 * A.material_amt
			gain += A.material.getProperty("n_radioactive") * 6 * A.material_amt
			if(isitem(A))
				var/obj/item/I = A
				gain *= min(I.amount, INFINITY)

		if (A.reagents)
			gain += min(A.reagents.total_volume/4, 50)

		if (istype(A, /obj/machinery/nuclearbomb))
			gain += 5000 //ten clowns
			playsound_global(clients, 'sound/machines/singulo_start.ogg', 50)
			SPAWN(1 SECOND)
				src.maxradius += 5
				for (var/i in 1 to 5)
					src.grow()
					sleep(0.5 SECONDS)
			qdel(A)
		else if (istype(A, /obj/item/plutonium_core)) // as a treat
			gain += 5000
			qdel(A)
		else
			var/obj/O = A
			succ_cache[A.type] += 1
			gain += 10/succ_cache[A.type]
			for(var/atom/other_food in A)
				src.consume_atom(other_food, no_visuals = TRUE)
			O.set_loc(src.get_center())
			O.ex_act(1)
			if (O)
				qdel(O)

	else if (isturf(A))
		var/turf/T = A
		if (issimulatedturf(T))
			if (istype(T, /turf/simulated/floor))
				T.ReplaceWithSpace()
				gain += 2
			else
				T.ReplaceWithFloor()

	src.energy += gain

/obj/machinery/the_singularity/proc/get_center()
	return src.loc

/obj/machinery/the_singularity/attackby(var/obj/item/I, var/mob/user)
	if (istype(I, /obj/item/clothing/mask/cigarette))
		var/obj/item/clothing/mask/cigarette/C = I
		if (!C.on)
			C.light(user, SPAN_ALERT("<b>[user]</b> lights [C] on [src]. Holy fucking shit!"))
		else
			return ..()
	else
		return ..()

/obj/machinery/the_singularity/proc/shrink()
	radius--
	SafeScaleAnim((radius-0.5)/(radius+0.5),(radius-0.5)/(radius+0.5), anim_time=3 SECONDS, anim_easing=CUBIC_EASING|EASE_OUT)
	grav_pull = min((radius+1)*3, grav_pull)

/obj/machinery/the_singularity/proc/grow()
	if(radius<maxradius)
		radius++
		SafeScaleAnim((radius+0.5)/(radius-0.5),(radius+0.5)/(radius-0.5), anim_time=3 SECONDS, anim_easing=CUBIC_EASING|EASE_OUT)
		grav_pull = max(grav_pull, radius)

// totally rewrote this proc from the ground-up because it was puke but I want to keep this comment down here vvv so we can bask in the glory of What Used To Be - haine
		/* uh why was lighting a cig causing the singularity to have an extra process()?
		   this is dumb as hell, commenting this. the cigarette will get processed very soon. -drsingh
		SPAWN(0) //start fires while it's lit
			src.process()
		*/

/////////////////////////////////////////////Controls which "event" is called
/obj/machinery/the_singularity/proc/event()
	var/numb = rand(1,3)
	if(prob(25 / max(radius, 1)))
		grow()
	switch (numb)
		if (1)//Eats the turfs around it
			BHolerip()
			return
		if (2)//tox damage all carbon mobs in area
			Toxmob()
			return
		if (3)//Stun mobs who lack optic scanners
			Mezzer()
			return


/obj/machinery/the_singularity/proc/Toxmob()
	for (var/mob/living/M in hearers(radius*EVENT_GROWTH+EVENT_MINIMUM, src.get_center()))
		M.take_radiation_dose(clamp(0.2 SIEVERTS*(radius+1), 0, 2 SIEVERTS))
		M.show_text("You feel odd.", "red")

/obj/machinery/the_singularity/proc/Mezzer()
	for (var/mob/living/carbon/M in hearers(radius*EVENT_GROWTH+EVENT_MINIMUM, src.get_center()))
		if (ishuman(M))
			var/mob/living/carbon/human/H = M
			if (H.bioHolder?.HasEffect("blind") || H.blinded)
				return
			else if (istype(H.glasses,/obj/item/clothing/glasses/toggleable/meson))
				M.show_text("You look directly into [src.name], good thing you had your protective eyewear on!", "green")
				return
			// remaining eye(s) meson cybereyes?
			else if((!H.organHolder?.left_eye || istype(H.organHolder?.left_eye, /obj/item/organ/eye/cyber/meson)) && (!H.organHolder?.right_eye || istype(H.organHolder?.right_eye, /obj/item/organ/eye/cyber/meson)))
				M.show_text("You look directly into [src.name], good thing your eyes are protected!", "green")
				return
		M.changeStatus("stunned", 7 SECONDS)
		M.visible_message(SPAN_ALERT("<B>[M] stares blankly at [src]!</B>"),\
		"<B>You look directly into [src]!<br>[SPAN_ALERT("You feel weak!")]</B>")

/obj/machinery/the_singularity/proc/BHolerip()
	var/turf/sing_center = src.get_center()
	for (var/turf/T in orange(radius+EVENT_GROWTH+0.5, sing_center))
		if (prob(70))
			continue

		if (T && !istype(T, /turf/space) && (IN_EUCLIDEAN_RANGE(sing_center, T, radius+EVENT_GROWTH+0.5)))
			if (issimulatedturf(T))
				if (istype(T,/turf/simulated/floor) && !istype(T,/turf/simulated/floor/plating))
					var/turf/simulated/floor/F = T
					if (!F.broken)
						if (prob(80))
							F.break_tile_to_plating()
							if(!F.intact)
								var/obj/item/tile/tile = new(F)
								tile.setMaterial(F.material)
						else
							F.break_tile()
				else if (istype(T, /turf/simulated/wall))
					var/turf/simulated/wall/W = T
					if (istype(W, /turf/simulated/wall/r_wall) || istype(W, /turf/simulated/wall/auto/reinforced))
						new /obj/structure/girder/reinforced(W)
					else
						new /obj/structure/girder(W)
					var/obj/item/sheet/S = new /obj/item/sheet(W)
					if (W.material)
						S.setMaterial(W.material)
					else
						var/datum/material/M = getMaterial("steel")
						S.setMaterial(M)
					W.ReplaceWithFloor()
	return
#endif

/// Singularity that can exist on restricted z levels
/obj/machinery/the_singularity/admin
	restricted_z_allowed = TRUE


/particles/singularity
	transform = list(1, 0, 0, 0,
	                 0, 1, 0, 0,
					 0, 0, 0, 1,
					 0, 0, 0, 1)
	width = 200
	height = 200
	spawning = 2
	count = 1000
	lifespan = 8
	fade = 10
	fadein = 8
	position = generator("circle", 200, 300, UNIFORM_RAND)
	gravity = list(0, 0, 0.05)
	velocity = list(0, 0, 0.4)
	friction = 0.2

//////////////////////////////////////// Field generator /////////////////////////////////////////

TYPEINFO(/obj/machinery/field_generator)
	mats = 14

/obj/machinery/field_generator
	name = "Field Generator"
	desc = "Projects an energy field when active"
	icon = 'icons/obj/singularity.dmi'
	icon_state = "Field_Gen"
	anchored = UNANCHORED
	density = 1
	req_access = list(access_engineering_engine)
	object_flags = CAN_REPROGRAM_ACCESS | NO_GHOSTCRITTER
	appearance_flags = KEEP_TOGETHER
	var/Varedit_start = 0
	var/Varpower = 0
	var/active = 0
	var/power = 20
	var/max_power = 100
	var/state = UNWRENCHED
	var/steps = 0
	var/last_check = 0
	var/check_delay = 10
	var/recalc = 0
	var/locked = 1
	//Remote control stuff
	var/net_id = null
	var/obj/machinery/power/data_terminal/link = null
	var/active_dirs = 0
	var/shortestlink = 0

	HELP_MESSAGE_OVERRIDE({"In order to be activated, the Field Generator has to be <b>wrenched</b> and <b>welded</b> down first. Once \
							secured, a valid ID has to be swiped to unlock the controls. On activation, the generator will connect to \
							other ones within a cardinal range of 13 tiles."})

	proc/set_active(var/act)
		if (src.active != act)
			src.active = act
			if (src.active)
				event_handler_flags |= IMMUNE_SINGULARITY_INACTIVE
			else
				event_handler_flags &= ~IMMUNE_SINGULARITY_INACTIVE

/obj/machinery/field_generator/attack_hand(mob/user)
	if(state == WELDED)
		if(!src.locked)
			if(src.active >= 1)
	//			src.active = 0
	//			icon_state = "Field_Gen"
				boutput(user, "You are unable to turn off the field generator, wait till it powers down.")
	//			src.cleanup()
			else
				set_active(1)
				icon_state = "Field_Gen +a"
				boutput(user, "You turn on the field generator.")
				logTheThing(LOG_STATION, user, "activated a [src.name] at [log_loc(src)].") // Hmm (Convair880).
		else
			boutput(user, "The controls are locked!")
	else
		boutput(user, "The field generator needs to be firmly secured to the floor first.")
	src.add_fingerprint(user)

/obj/machinery/field_generator/attack_ai(mob/user as mob)
	if(state == WELDED)
		if(src.active >= 1)
			boutput(user, "You are unable to turn off the field generator, wait till it powers down.")
		else
			src.set_active(1)
			icon_state = "Field_Gen +a"
			boutput(user, "You turn on the field generator.")
			logTheThing(LOG_STATION, user, "activated a [src.name] at [log_loc(src)].") // Hmm (Convair880).
	else
		boutput(user, "The field generator needs to be firmly secured to the floor first.")
	src.add_fingerprint(user)

/obj/machinery/field_generator/New()
	START_TRACKING
	..()
	SPAWN(0.6 SECONDS)
		if(!src.link && (state == WELDED))
			src.get_link()

		src.net_id = format_net_id("\ref[src]")

/obj/machinery/field_generator/disposing()
	STOP_TRACKING
	for(var/dir in cardinal)
		src.cleanup(dir)
	if (link)
		link.master = null
		link = null
	active = FALSE
	. = ..()

/obj/machinery/field_generator/was_deconstructed_to_frame(mob/user)
	. = ..()
	for(var/dir in cardinal)
		src.cleanup(dir)
	active = FALSE
	state = UNWRENCHED
	anchored = UNANCHORED

/obj/machinery/field_generator/can_deconstruct(mob/user)
	. = !active

/obj/machinery/field_generator/process(var/mult)
	if(src.Varedit_start == 1)
		if(src.active == 0)
			src.set_active(1)
			src.state = WELDED
			src.power = 100
			src.anchored = ANCHORED
			icon_state = "Field_Gen +a"
		Varedit_start = 0

	if(src.active == 1)
		if(!src.state == WELDED)
			src.set_active(0)
			return
		setup_field(NORTH)
		setup_field(SOUTH)
		setup_field(EAST)
		setup_field(WEST)
		src.set_active(2)
	src.power = clamp(src.power, 0, src.max_power)
	if(src.active >= 1)
		src.power -= 1 * mult
		if(Varpower == 0)
			if(src.power <= 0)
				src.visible_message(SPAN_ALERT("The [src.name] shuts down due to lack of power!"))
				playsound(src, 'sound/machines/shielddown.ogg', 50, TRUE)
				icon_state = "Field_Gen"
				src.set_active(0)
				src.cleanup(NORTH)
				src.cleanup(SOUTH)
				src.cleanup(EAST)
				src.cleanup(WEST)
				for(var/dir in cardinal)
					src.UpdateOverlays(null, "field_start_[dir]")
					src.UpdateOverlays(null, "field_end_[dir]")
				return

	if (src.active >= 1 && src.power <= 40)
		if (!ON_COOLDOWN(src, "power_alarm", 20 SECONDS + rand(-5 SECONDS, 5 SECONDS))) //stupid rand just to make the alarms go off at slightly different times and not stack up
			playsound(src, 'sound/machines/pod_alarm.ogg', 50, FALSE, pitch = 0.6 + (power/40) * 0.4)
			src.visible_message(SPAN_ALERT("The [src.name] emits a low power warning alarm!"))
		if (!src.GetOverlayImage("amber"))
			src.UpdateOverlays(image(src.icon, "FieldGen_amber", FLOAT_LAYER - 1), "amber")
	else
		src.UpdateOverlays(null, "amber")

/obj/machinery/field_generator/proc/setup_field(var/NSEW = 0)
	var/turf/T = src.loc
	var/turf/T2 = src.loc
	var/obj/machinery/field_generator/G
	var/steps = 0

	if(!NSEW)//Make sure its ran right
		return
	var/oNSEW = turn(NSEW, 180)

	for(var/dist = 0, dist <= SINGULARITY_MAX_DIMENSION, dist += 1) // checks out to max dimension tiles away for another generator to link to
		T = get_step(T2, NSEW)
		T2 = T
		steps += 1
		G = locate(/obj/machinery/field_generator) in T
		if(G && G != src && !QDELETED(G))
			steps -= 1
			if(shortestlink==0)
				shortestlink = dist
			else if (shortestlink > dist)
				shortestlink = dist
			if(!G.active)
				return
			if(G.active_dirs & oNSEW)
				return // already active I guess
			break

	if(isnull(G))
		return

	src.UpdateOverlays(image('icons/obj/singularity.dmi', "Contain_F_Start", dir=NSEW, layer=(NSEW == NORTH ? src.layer - 1 : FLOAT_LAYER)), "field_start_[NSEW]")
	G.UpdateOverlays(image('icons/obj/singularity.dmi', "Contain_F_End", dir=NSEW, layer=(NSEW == SOUTH ? src.layer - 1 : FLOAT_LAYER)), "field_end_[NSEW]")

	T2 = src.loc

	for(var/dist = 0, dist < steps, dist += 1) // creates each field tile
		var/field_dir = get_dir(T2,get_step(T2, NSEW))
		T = get_step(T2, NSEW)
		T2 = T
		var/obj/machinery/containment_field/CF = new/obj/machinery/containment_field/(src, G) //(ref to this gen, ref to connected gen)
		CF.set_loc(T)
		CF.set_dir(field_dir)

	active_dirs |= NSEW
	G.active_dirs |= oNSEW

	G.process() // ok, a cool trick / ugly hack to make the direction of the fields nice and consistent in a circle

//Create a link with a data terminal on the same tile, if possible.
/obj/machinery/field_generator/proc/get_link()
	if(src.link)
		src.link.master = null
		src.link = null
	var/turf/T = get_turf(src)
	var/obj/machinery/power/data_terminal/test_link = locate() in T
	if(test_link && !DATA_TERMINAL_IS_VALID_MASTER(test_link, test_link.master))
		src.link = test_link
		src.link.master = src

	return

/obj/machinery/field_generator/bullet_act(var/obj/projectile/P)
	if(!P)
		return
	if(!P.proj_data)
		return
	if(P.proj_data.damage_type == D_ENERGY)
		src.power += P.power
		FLICK("Field_Gen_Flash", src)

/obj/machinery/field_generator/attackby(obj/item/W, mob/user)
	if (iswrenchingtool(W))
		if(active)
			boutput(user, "Turn off the field generator first.")
			return

		else if(state == UNWRENCHED)
			state = WRENCHED
			playsound(src.loc, 'sound/items/Ratchet.ogg', 75, 1)
			boutput(user, "You secure the external reinforcing bolts to the floor.")
			desc = "Projects an energy field when active. It has been bolted to the floor."
			src.anchored = ANCHORED
			return

		else if(state == WRENCHED)
			state = UNWRENCHED
			playsound(src.loc, 'sound/items/Ratchet.ogg', 75, 1)
			boutput(user, "You undo the external reinforcing bolts.")
			desc = "Projects an energy field when active."
			src.anchored = UNANCHORED
			return

	if(isweldingtool(W))
		if(state != UNWRENCHED)
			if(!W:try_weld(user, 1, noisy = 2))
				return
			var/positions = src.get_welding_positions()
			actions.start(new /datum/action/bar/private/welding(user, src, 2 SECONDS, /obj/machinery/field_generator/proc/weld_action, \
						list(user), "[user] finishes using [his_or_her(user)] [W.name] on the field generator.", positions[1], positions[2]),user)
		if(state == WRENCHED)
			boutput(user, "You start to weld the field generator to the floor.")
			return
		else if(state == WELDED)
			boutput(user, "You start to cut the field generator free from the floor.")
			return

	if(ispulsingtool(W))
		boutput(user, SPAN_ALERT("The [src.name] is at [src.power]/100 power."))

	var/obj/item/card/id/id_card = get_id_card(W)
	if (istype(id_card))
		if (src.allowed(user))
			src.locked = !src.locked
			boutput(user, "Controls are now [src.locked ? "locked." : "unlocked."]")
		else
			boutput(user, SPAN_ALERT("Access denied."))

	else
		src.add_fingerprint(user)
		boutput(user, SPAN_ALERT("You hit the [src.name] with your [W.name]!"))
		for(var/mob/M in AIviewers(src))
			if(M == user)	continue
			M.show_message(SPAN_ALERT("The [src.name] has been hit with the [W.name] by [user.name]!"))

/obj/machinery/field_generator/proc/get_welding_positions()
	var/start
	var/stop

	start = list(-6,-15)
	stop = list(6,-15)

	if(state == WELDED)
		. = list(stop,start)
	else
		. = list(start,stop)

/obj/machinery/field_generator/proc/weld_action(mob/user)
	if(state == WRENCHED)
		state = WELDED
		src.get_link() //Set up a link, now that we're secure!
		boutput(user, "You weld the field generator to the floor.")
		desc = "Projects an energy field when active. It has been bolted and welded to the floor."
	else if(state == WELDED)
		state = WRENCHED
		if(src.link) //Clear active link.
			src.link.master = null
			src.link = null
		boutput(user, "You cut the field generator free from the floor.")
		desc = "Projects an energy field when active. It has been bolted to the floor."

/obj/machinery/field_generator/proc/cleanup(var/NSEW)
	var/obj/machinery/containment_field/F
	var/obj/machinery/field_generator/G
	var/turf/T = src.loc
	var/turf/T2 = src.loc
	var/oNSEW = turn(NSEW, 180)

	active_dirs &= ~NSEW

	src.UpdateOverlays(null, "field_start_[NSEW]")
	src.UpdateOverlays(null, "field_end_[oNSEW]")

	for(var/dist = 0, dist <= SINGULARITY_MAX_DIMENSION, dist += 1) // checks out to 8 tiles away for fields
		T = get_step(T2, NSEW)
		T2 = T
		for(F in T)
			if(F.gen_primary == src || F.gen_secondary == src )
				qdel(F)

		G = locate(/obj/machinery/field_generator) in T
		if(G)
			G.UpdateOverlays(null, "field_end_[NSEW]")
			G.UpdateOverlays(null, "field_start_[oNSEW]")
			G.active_dirs &= ~oNSEW
			if(!G.active)
				break
			else
				G.setup_field(oNSEW)


//Send a signal over our link, if possible.
/obj/machinery/field_generator/proc/post_status(var/target_id, var/key, var/value, var/key2, var/value2, var/key3, var/value3)
	if(!src.link || !target_id)
		return

	var/datum/signal/signal = get_free_signal()
	signal.source = src
	signal.transmission_method = TRANSMISSION_WIRE
	signal.data[key] = value
	if(key2)
		signal.data[key2] = value2
	if(key3)
		signal.data[key3] = value3

	signal.data["address_1"] = target_id
	signal.data["sender"] = src.net_id

	src.link.post_signal(src, signal)

//What do we do with an incoming command?
/obj/machinery/field_generator/receive_signal(datum/signal/signal)
	if(!src.link)
		return
	if(!signal || !src.net_id || signal.encryption)
		return

	/* People might abuse this but I find it funny
	if(signal.transmission_method != TRANSMISSION_WIRE) //No radio for us thanks
		return
	*/

	var/target = signal.data["sender"]

	//They don't need to target us specifically to ping us.
	//Otherwise, ff they aren't addressing us, ignore them
	if(signal.data["address_1"] != src.net_id)
		if((signal.data["address_1"] == "ping") && signal.data["sender"])
			SPAWN(0.5 SECONDS) //Send a reply for those curious jerks
				src.post_status(target, "command", "ping_reply", "device", "PNET_ENG_FIELD", "netid", src.net_id)

		return

	var/sigcommand = lowertext(signal.data["command"])
	if(!sigcommand || !signal.data["sender"])
		return

	//Oh okay, time to start up.
	if(sigcommand == "activate" && !src.active)
		src.set_active(1)
		icon_state = "Field_Gen +a"

	if(sigcommand == "deactivate" && src.active)
		src.set_active(0)
		icon_state = "Field_Gen"

	return

/obj/machinery/field_generator/activated
	Varedit_start = TRUE
	power = 50

/obj/machinery/field_generator/does_impact_particles(kinetic_impact)
	return kinetic_impact

/////////////////////////////////////////////// Containment field //////////////////////////////////

/obj/machinery/containment_field
	name = "Containment Field"
	desc = "An energy field."
	icon = 'icons/obj/singularity.dmi'
	icon_state = "Contain_F"
	pass_unstable = TRUE
	anchored = ANCHORED
	density = 1
	event_handler_flags = USE_FLUID_ENTER | IMMUNE_SINGULARITY | IMMUNE_TRENCH_WARP
	var/active = 1
	var/power = 10
	var/delay = 5
	var/last_active
	var/mob/U
	var/obj/machinery/field_generator/gen_primary
	var/obj/machinery/field_generator/gen_secondary
	var/datum/light/light

/obj/machinery/containment_field/New(var/obj/machinery/field_generator/A, var/obj/machinery/field_generator/B)
	src.gen_primary = A
	src.gen_secondary = B
	light = new /datum/light/point
	light.set_brightness(0.7)
	light.set_color(0, 0.1, 0.8)
	light.attach(src)
	light.enable()

	..()

/obj/machinery/containment_field/disposing()
	src.gen_primary = null
	src.gen_secondary = null
	..()

/obj/machinery/containment_field/ex_act(severity)
	return

/obj/machinery/containment_field/attack_hand(mob/user)
	return

/obj/machinery/containment_field/process()
	if(isnull(gen_primary)||isnull(gen_secondary))
		qdel(src)
		return

	if(!(gen_primary.active)||!(gen_secondary.active))
		qdel(src)
		return

/obj/machinery/containment_field/proc/shock(mob/user as mob)
	if(isnull(gen_primary) || isnull(gen_secondary))
		qdel(src)
		return

	elecflash(user)

	src.power = max(gen_primary.power,gen_secondary.power)

	var/prot = 1
	var/shock_damage = 0
	if(src.power > 200)
		shock_damage = min(rand(40,80),rand(40,100))*prot
	else if(src.power > 120)
		shock_damage = min(rand(30,60),rand(30,90))*prot
	else if(src.power > 80)
		shock_damage = min(rand(20,40),rand(20,40))*prot
	else if(src.power > 60)
		shock_damage = min(rand(20,30),rand(20,30))*prot
	else
		shock_damage = min(rand(10,20),rand(10,20))*prot

	// Added (Convair880).
	logTheThing(LOG_COMBAT, user, "was shocked by a containment field at [log_loc(src)] and received [shock_damage] damage.")

	if (user?.bioHolder)
		if (user.bioHolder.HasEffect("resist_electric_heal"))
			var/healing = 0
			if (shock_damage)
				healing = shock_damage / 3
			user.HealDamage("All", shock_damage, shock_damage)
			user.take_toxin_damage(0 - healing)
			boutput(user, SPAN_NOTICE("You absorb the electrical shock, healing your body!"))
			return
		else if (user.bioHolder.HasEffect("resist_electric"))
			boutput(user, SPAN_NOTICE("You feel electricity course through you harmlessly!"))
			return

	user.TakeDamage(user.hand == LEFT_HAND ? "l_arm" : "r_arm", 0, shock_damage)
	boutput(user, SPAN_ALERT("<B>You feel a powerful shock course through your body sending you flying!</B>"))
	user.unlock_medal("HIGH VOLTAGE", 1)
	if (isliving(user))
		var/mob/living/L = user
		L.Virus_ShockCure(100)
		L.shock_cyberheart(100)
	if(user.getStatusDuration("stunned") < shock_damage * 10)	user.changeStatus("stunned", shock_damage/4 SECONDS)
	if(user.getStatusDuration("knockdown") < shock_damage * 10)	user.changeStatus("knockdown", shock_damage/4 SECONDS)

	if(user.get_burn_damage() >= 500) //This person has way too much BURN, they've probably been shocked a lot! Let's destroy them!
		user.visible_message("<span style=\"color:red;font-weight:bold;\">[user.name] was disintegrated by the [src.name]!</span>")
		logTheThing(LOG_COMBAT, user, "was elecgibbed by [src] ([src.type]) at [log_loc(user)].")
		user.elecgib()
		return
	else
		var/throwdir = get_dir(src, get_step_away(user, src))
		if (get_turf(user) == get_turf(src))
			if (prob(50))
				throwdir = turn(throwdir,90)
			else
				throwdir = turn(throwdir,-90)
		var/atom/target = get_edge_target_turf(user, throwdir)
		user.throw_at(target, 200, 4)
		for(var/mob/M in AIviewers(src))
			if(M == user)	continue
			M.show_message(SPAN_ALERT("[user.name] was shocked by the [src.name]!"), 3, SPAN_ALERT("You hear a heavy electrical crack"), 2)

	src.gen_primary.power -= 3
	src.gen_secondary.power -= 3
	return

/obj/machinery/containment_field/Bumped(atom/O)
	. = ..()
	if(iscarbon(O))
		shock(O)

/obj/machinery/containment_field/Cross(atom/movable/mover)
	. = ..()
	if(prob(10))
		. = TRUE

/obj/machinery/containment_field/Crossed(atom/movable/AM)
	. = ..()
	if(iscarbon(AM))
		shock(AM)

/////////////////////////////////////////// Emitter ///////////////////////////////
TYPEINFO(/obj/machinery/emitter)
	mats = 10

/obj/machinery/emitter
	name = "\improper Emitter"
	desc = "Shoots a high power laser when active"
	icon = 'icons/obj/singularity.dmi'
	icon_state = "Emitter"
	anchored = UNANCHORED
	density = 1
	req_access = list(access_engineering_engine)
	object_flags = CAN_REPROGRAM_ACCESS | NO_GHOSTCRITTER
	var/active = 0
	var/power = 20
	var/fire_delay = 100
	var/HP = 20
	var/last_shot = 0
	var/shot_number = 0
	var/state = UNWRENCHED
	var/locked = 1
	var/emagged = FALSE
	//Remote control stuff
	var/net_id = null
	var/obj/machinery/power/data_terminal/link = null
	var/datum/projectile/current_projectile = new/datum/projectile/laser/heavy

	HELP_MESSAGE_OVERRIDE({"The Emitter shoots laser bolts at Containment Field Generators to power them. Has to be \
							<b>wrenched</b> and <b>welded</b> down before being useable. The control systems must be unlocked \
							with a valid ID in order to activate the Emitter."})

/obj/machinery/emitter/New()
	..()
	SPAWN(0.6 SECONDS)
		if(!src.link && (state == WELDED))
			src.get_link()

		src.net_id = format_net_id("\ref[src]")

/obj/machinery/emitter/can_deconstruct(mob/user)
	. = !active

/obj/machinery/emitter/was_deconstructed_to_frame(mob/user)
	. = ..()
	active = FALSE
	state = UNWRENCHED
	anchored = UNANCHORED

//Create a link with a data terminal on the same tile, if possible.
/obj/machinery/emitter/proc/get_link()
	if(src.link)
		src.link.master = null
		src.link = null
	var/turf/T = get_turf(src)
	var/obj/machinery/power/data_terminal/test_link = locate() in T
	if(test_link && !DATA_TERMINAL_IS_VALID_MASTER(test_link, test_link.master))
		src.link = test_link
		src.link.master = src

	return

/obj/machinery/emitter/attack_hand(mob/user)
	if(state == WELDED)
		if(!src.locked)
			if(src.active==1)
				if(tgui_alert(user, "Turn off the emitter?", "Emitter controls", list("Yes", "No")) == "Yes")
					src.active = 0
					icon_state = "Emitter"
					boutput(user, "You turn off the emitter.")
					logTheThing(LOG_STATION, user, "deactivated active emitter at [log_loc(src)].")
					message_admins("[key_name(user)] deactivated active emitter at [log_loc(src)].")
			else
				if(tgui_alert(user, "Turn on the emitter?", "Emitter controls", list("Yes", "No")) == "Yes")
					src.active = 1
					icon_state = "Emitter +a"
					boutput(user, "You turn on the emitter.")
					logTheThing(LOG_STATION, user, "activated emitter at [log_loc(src)].")
					src.shot_number = 0
					src.fire_delay = 100
					message_admins("[key_name(user)] activated emitter at [log_loc(src)].")
		else
			boutput(user, "The controls are locked!")
	else
		boutput(user, "The emitter needs to be firmly secured to the floor first.")
	src.add_fingerprint(user)
	..()

/obj/machinery/emitter/attack_ai(mob/user as mob)
	if (src.emagged)
		boutput(user, SPAN_NOTICE("Unable to interface with [src]!"))
		return
	if(state == WELDED)
		if(src.active==1)
			if(tgui_alert(user, "Turn off the emitter?","Switch",list("Yes","No")) == "Yes")
				src.active = 0
				icon_state = "Emitter"
				boutput(user, "You turn off the emitter.")
				logTheThing(LOG_STATION, user, "deactivated active emitter at [log_loc(src)].")
				message_admins("[key_name(user)] deactivated active emitter at [log_loc(src)].")
		else
			if(tgui_alert(user, "Turn on the emitter?","Switch",list("Yes","No")) == "Yes")
				src.active = 1
				icon_state = "Emitter +a"
				boutput(user, "You turn on the emitter.")
				logTheThing(LOG_STATION, user, "activated emitter at [log_loc(src)].")
				src.shot_number = 0
				src.fire_delay = 100
				message_admins("[key_name(user)] activated emitter at [log_loc(src)].")
	else
		boutput(user, "The emitter needs to be firmly secured to the floor first.")
	src.add_fingerprint(user)
	return

/obj/machinery/emitter/process()

	if(status & (NOPOWER|BROKEN))
		return

	if(!src.state == WELDED)
		src.active = 0
		return

	if(((src.last_shot + src.fire_delay) <= world.time) && (src.active == 1))
		src.last_shot = world.time
		if(src.shot_number < 3)
			src.fire_delay = 2
			src.shot_number ++
		else
			src.fire_delay = rand(20,100)
			src.shot_number = 0

		if (!is_cardinal(src.dir)) // Not cardinal (not power of 2)
			src.dir &= 12 // Cardinalize

		src.visible_message(SPAN_ALERT("<b>[src]</b> fires a bolt of energy!"))

		shoot_projectile_DIR(src, current_projectile, dir)
		var/horizontal_offset = (src.dir in list(EAST, WEST)) ? 10 : 0 //offset by 10 pixels if we're firing to the side otherwise it looks weird
		muzzle_flash_any(src, dir_to_angle(dir), "muzzle_flash_plaser", horizontal_offset = horizontal_offset)
		use_power(current_projectile.power)

		if(prob(35))
			elecflash(src)
	..()

/obj/machinery/emitter/attackby(obj/item/W, mob/user)
	if (ispryingtool(W))
		if(!anchored)
			src.set_dir(turn(src.dir, -90))
			return
		else
			boutput(user, "The emitter is too firmly secured to be rotated!")
			return
	else if (iswrenchingtool(W))
		if(active)
			boutput(user, "Turn off the emitter first.")
			return

		else if(state == UNWRENCHED)
			state = WRENCHED
			playsound(src.loc, 'sound/items/Ratchet.ogg', 75, 1)
			boutput(user, "You secure the external reinforcing bolts to the floor.")
			src.anchored = ANCHORED
			desc = "Shoots a high power laser when active, it has been bolted to the floor."
			return

		else if(state == WRENCHED)
			state = UNWRENCHED
			playsound(src.loc, 'sound/items/Ratchet.ogg', 75, 1)
			boutput(user, "You undo the external reinforcing bolts.")
			src.anchored = UNANCHORED
			desc = "Shoots a high power laser when active."
			return

	if(isweldingtool(W))
		if(state != UNWRENCHED)
			if(!W:try_weld(user, 1, noisy = 2))
				return
			var/positions = src.get_welding_positions()
			actions.start(new /datum/action/bar/private/welding(user, src, 2 SECONDS, /obj/machinery/emitter/proc/weld_action, \
						list(user), "[user] finishes using [his_or_her(user)] [W.name] on the emitter.", positions[1], positions[2]),user)
		if(state == WRENCHED)
			boutput(user, "You start to weld the emitter to the floor.")
			return
		else if(state == WELDED)
			boutput(user, "You start to cut the emitter free from the floor.")
			return

	var/obj/item/card/id/id_card = get_id_card(W)
	if (istype(id_card) && length(src.req_access))
		if (src.allowed(user))
			src.locked = !src.locked
			boutput(user, "Controls are now [src.locked ? "locked." : "unlocked."]")
			if (!src.locked)
				logTheThing(LOG_STATION, user, "unlocked emitter at at [log_loc(src)].")
		else
			boutput(user, SPAN_ALERT("Access denied."))

	else
		src.add_fingerprint(user)
		boutput(user, SPAN_ALERT("You hit the [src.name] with your [W.name]!"))
		for(var/mob/M in AIviewers(src))
			if(M == user)	continue
			M.show_message(SPAN_ALERT("The [src.name] has been hit with the [W.name] by [user.name]!"))

/obj/machinery/emitter/proc/get_welding_positions()
	var/start
	var/stop
	if(dir & (NORTH|SOUTH))
		start = list(-10,-7)
		stop = list(10,-7)
	else
		start = list(-10,-14)
		stop = list(10,-14)

	if(state == WELDED)
		. = list(stop,start)
	else
		. = list(start,stop)


/obj/machinery/emitter/proc/weld_action(mob/user)
	if(state == WRENCHED)
		state = WELDED
		src.get_link()
		desc = "Shoots a high power laser when active, it has been bolted and welded to the floor."
		boutput(user, "You weld the emitter to the floor.")
		logTheThing(LOG_STATION, user, "welds an emitter to the floor at [log_loc(src)].")
	else if(state == WELDED)
		state = WRENCHED
		if(src.link) //Time to clear our link.
			src.link.master = null
			src.link = null
		desc = "Shoots a high power laser when active, it has been bolted to the floor."
		boutput(user, "You cut the emitter free from the floor.")
		logTheThing(LOG_STATION, user, "unwelds an emitter from the floor at [log_loc(src)].")

//Send a signal over our link, if possible.
/obj/machinery/emitter/proc/post_status(var/target_id, var/key, var/value, var/key2, var/value2, var/key3, var/value3)
	if(!src.link || src.emagged || !target_id)
		return

	var/datum/signal/signal = get_free_signal()
	signal.source = src
	signal.transmission_method = TRANSMISSION_WIRE
	signal.data[key] = value
	if(key2)
		signal.data[key2] = value2
	if(key3)
		signal.data[key3] = value3

	signal.data["address_1"] = target_id
	signal.data["sender"] = src.net_id

	src.link.post_signal(src, signal)

//What do we do with an incoming command?
/obj/machinery/emitter/receive_signal(datum/signal/signal)
	if(!src.link || src.emagged)
		return
	if(!signal || !src.net_id || signal.encryption)
		return


	if(signal.transmission_method != TRANSMISSION_WIRE) //No radio for us thanks
		return

	var/target = signal.data["sender"]

	//They don't need to target us specifically to ping us.
	//Otherwise, ff they aren't addressing us, ignore them
	if(signal.data["address_1"] != src.net_id)
		if((signal.data["address_1"] == "ping") && signal.data["sender"])
			SPAWN(0.5 SECONDS) //Send a reply for those curious jerks
				src.post_status(target, "command", "ping_reply", "device", "PNET_ENG_EMITR", "netid", src.net_id)

		return

	var/sigcommand = lowertext(signal.data["command"])
	if(!sigcommand || !signal.data["sender"])
		return

	//Oh okay, time to start up.
	if(sigcommand == "activate" && !src.active)
		src.active = 1
		icon_state = "Emitter +a"
		src.shot_number = 0
		src.fire_delay = 100
	//oh welp shutdown time.
	else if(sigcommand == "deactivate" && src.active)
		src.active = 0
		icon_state = "Emitter"

	return

/obj/machinery/emitter/emag_act(mob/user, obj/item/card/emag/E)
	if (!src.emagged)
		boutput(user, SPAN_ALERT("\The [src] shorts out its remote connectivity controls!"))
		src.emagged = TRUE

/obj/machinery/emitter/demag(mob/user)
	. = ..()
	if (src.emagged)
		src.emagged = FALSE

/obj/machinery/emitter/assault
	name = "prototype assault emitter"
	desc = "Shoots a VERY high power laser when active. The ID lock appears to have been messily smashed off."
	current_projectile = new/datum/projectile/laser/asslaser
	locked = FALSE
	fire_delay = 30
	req_access = list()
	HELP_MESSAGE_OVERRIDE({"The Emitter shoots assault lasers at <s>Containment Field Generators</s> just about anything! Has to be \
							<b>wrenched</b> and <b>welded</b> down before being useable."})

	attack_ai(mob/user)
		return

	receive_signal(datum/signal/signal)
		return

/////////////////////////////////// Collector array /////////////////////////////////

/obj/item/electronics/frame/collector_array
	name = "Radiation Collector Array frame"
	store_type = /obj/machinery/power/collector_array
	viewstat = 2
	secured = 2
	icon_state = "dbox"

TYPEINFO(/obj/machinery/power/collector_array)
	mats = 20

/obj/machinery/power/collector_array
	name = "Radiation Collector Array"
	desc = "A device which uses Hawking Radiation and plasma to produce power."
	icon = 'icons/obj/singularity.dmi'
	icon_state = "ca"
	anchored = ANCHORED
	density = 1
	directwired = 1
	var/magic = 0
	var/active = 0
	var/obj/item/tank/plasma/P = null
	var/obj/machinery/power/collector_control/CU = null
	deconstruct_flags = DECON_WELDER | DECON_MULTITOOL | DECON_CROWBAR | DECON_WRENCH
	HELP_MESSAGE_OVERRIDE({"Must be cardinally adjacent to a Radiation Collector Controller to function. \
							It can be bolted or unbolted to the floor with a <b>wrench</b>."})

/obj/machinery/power/collector_array/New()
	..()
	SPAWN(0.5 SECONDS)
		UpdateIcon()


/obj/machinery/power/collector_array/update_icon()
	if (src.active || src.magic)
		src.UpdateOverlays(image('icons/obj/singularity.dmi', "on"), "on")
	else
		src.UpdateOverlays(null, "on")

	if(src.P || src.magic)
		src.UpdateOverlays(image('icons/obj/singularity.dmi', "ptank"), "ptank")
	else
		src.UpdateOverlays(null, "ptank")

/obj/machinery/power/collector_array/power_change()
	..()
	UpdateIcon()

/obj/machinery/power/collector_array/process()

	if(magic == 1)
		src.active = 1
		icon_state = "ca_active"
	else
		if(P)
			if(P.air_contents.toxins <= 0)
				src.active = 0
				icon_state = "ca_deactive"
				UpdateIcon()
		else if(src.active == 1)
			src.active = 0
			icon_state = "ca_deactive"
			UpdateIcon()
		..()

/obj/machinery/power/collector_array/attack_hand(mob/user)
	if(src.active==1)
		src.active = 0
		icon_state = "ca_deactive"
		UpdateIcon()
		CU?.updatecons()
		boutput(user, "You turn off the collector array.")
		return

	if(src.active==0)
		src.active = 1
		icon_state = "ca_active"
		UpdateIcon()
		CU?.updatecons()
		boutput(user, "You turn on the collector array.")
		return

/obj/machinery/power/collector_array/attackby(obj/item/W, mob/user)
	if (iswrenchingtool(W))
		if(src.active)
			boutput(user, SPAN_ALERT("The [src.name] must be turned off first!"))
		else
			if (!src.anchored)
				playsound(src.loc, 'sound/items/Ratchet.ogg', 75, 1)
				boutput(user, "You secure the [src.name] to the floor.")
				src.anchored = ANCHORED
			else
				playsound(src.loc, 'sound/items/Ratchet.ogg', 75, 1)
				boutput(user, "You unsecure the [src.name].")
				src.anchored = UNANCHORED
			logTheThing(LOG_STATION, user, "[src.anchored ? "bolts" : "unbolts"] a [src.name] [src.anchored ? "to" : "from"] the floor at [log_loc(src)].") // Ditto (Convair880).
	else if(istype(W, /obj/item/tank/plasma))
		if(src.P)
			boutput(user, SPAN_ALERT("There appears to already be a plasma tank loaded!"))
			return
		src.P = W
		W.set_loc(src)
		user.u_equip(W)
		CU?.updatecons()
		UpdateIcon()
	else if (ispryingtool(W))
		if(!P)
			return
		var/obj/item/tank/plasma/Z = src.P
		Z.set_loc(get_turf(src))
		Z.layer = initial(Z.layer)
		src.P = null
		CU?.updatecons()
		UpdateIcon()
	else
		src.add_fingerprint(user)
		boutput(user, SPAN_ALERT("You hit the [src.name] with your [W.name]!"))
		for(var/mob/M in AIviewers(src))
			if(M == user)	continue
			M.show_message(SPAN_ALERT("The [src.name] has been hit with the [W.name] by [user.name]!"))

////////////////////////// Collector array controller ////////////////////////////

/obj/item/electronics/frame/collector_control
	name = "Radiation Collector Control frame"
	store_type = /obj/machinery/power/collector_control
	viewstat = 2
	secured = 2
	icon_state = "dbox"

TYPEINFO(/obj/machinery/power/collector_control)
	mats = 25

/obj/machinery/power/collector_control
	name = "Radiation Collector Control"
	desc = "A device which uses Hawking Radiation and Plasma to produce power."
	icon = 'icons/obj/singularity.dmi'
	icon_state = "cu"
	anchored = ANCHORED
	density = 1
	directwired = 1
	var/magic = 0
	var/active = 0
	var/lastpower = 0
	var/obj/item/tank/plasma/P1 = null
	var/obj/item/tank/plasma/P2 = null
	var/obj/item/tank/plasma/P3 = null
	var/obj/item/tank/plasma/P4 = null
	var/obj/machinery/power/collector_array/CA1 = null
	var/obj/machinery/power/collector_array/CA2 = null
	var/obj/machinery/power/collector_array/CA3 = null
	var/obj/machinery/power/collector_array/CA4 = null
	var/obj/machinery/power/collector_array/CAN = null
	var/obj/machinery/power/collector_array/CAS = null
	var/obj/machinery/power/collector_array/CAE = null
	var/obj/machinery/power/collector_array/CAW = null
	var/list/obj/machinery/the_singularity/S = null
	deconstruct_flags = DECON_WELDER | DECON_MULTITOOL | DECON_CROWBAR | DECON_WRENCH

	HELP_MESSAGE_OVERRIDE({"Transfers the energy from cardinally adjacent Radiation Collector Arrays \
							to the wire below it as usable electric power. \
							It can be bolted or unbolted to the floor with a <b>wrench</b>."})

/obj/machinery/power/collector_control/New()
	..()
	START_TRACKING
	AddComponent(/datum/component/mechanics_holder)
	SPAWN(1 SECOND)
		updatecons()

/obj/machinery/power/collector_control/disposing()
	STOP_TRACKING
	. = ..()

/obj/machinery/power/collector_control/proc/updatecons()

	if(magic != 1)

		CAN = locate(/obj/machinery/power/collector_array) in get_step(src,NORTH)
		CAS = locate(/obj/machinery/power/collector_array) in get_step(src,SOUTH)
		CAE = locate(/obj/machinery/power/collector_array) in get_step(src,EAST)
		CAW = locate(/obj/machinery/power/collector_array) in get_step(src,WEST)
		S = list()
		for_by_tcl(singu, /obj/machinery/the_singularity)//this loop checks for valid singularities
			if(!QDELETED(singu) && GET_DIST(singu,loc)<SINGULARITY_MAX_DIMENSION+2 )
				S |= singu

		if(!isnull(CAN))
			CA1 = CAN
			CAN.CU = src
			if(CA1.P)
				P1 = CA1.P
		else
			CAN = null
		if(!isnull(CAS))
			CA3 = CAS
			CAS.CU = src
			if(CA3.P)
				P3 = CA3.P
		else
			CAS = null
		if(!isnull(CAW))
			CA4 = CAW
			CAW.CU = src
			if(CA4.P)
				P4 = CA4.P
		else
			CAW = null
		if(!isnull(CAE))
			CA2 = CAE
			CAE.CU = src
			//DrMelon attempted fix for null.P at singularity.dm /// seemed to have been a tabulation error
			if(CA2.P)
				P2 = CA2.P
		else
			CAE = null

		UpdateIcon()
		SPAWN(1 MINUTE)
			updatecons()

	else
		UpdateIcon()
		SPAWN(1 MINUTE)
			updatecons()

/obj/machinery/power/collector_control/update_icon()
	overlays = null
	if(magic != 1)
		if(src.active == 0)
			return
		overlays += image('icons/obj/singularity.dmi', "cu on")
		if((P1)&&(CA1.active != 0))
			overlays += image('icons/obj/singularity.dmi', "cu 1 on")
		if((P2)&&(CA2.active != 0))
			overlays += image('icons/obj/singularity.dmi', "cu 2 on")
		if((P3)&&(CA3.active != 0))
			overlays += image('icons/obj/singularity.dmi', "cu 3 on")
		if((!P1)||(!P2)||(!P3))
			overlays += image('icons/obj/singularity.dmi', "cu n error")
		if(length(S))
			overlays += image('icons/obj/singularity.dmi', "cu sing")
			for(var/obj/machinery/the_singularity/singu in S)
				if(!singu.active)
					overlays += image('icons/obj/singularity.dmi', "cu conterr")
					break
	else
		overlays += image('icons/obj/singularity.dmi', "cu on")
		overlays += image('icons/obj/singularity.dmi', "cu 1 on")
		overlays += image('icons/obj/singularity.dmi', "cu 2 on")
		overlays += image('icons/obj/singularity.dmi', "cu 3 on")
		overlays += image('icons/obj/singularity.dmi', "cu sing")

/obj/machinery/power/collector_control/power_change()
	UpdateIcon()
	..()

/obj/machinery/power/collector_control/process(mult)
	if(magic != 1)
		if(src.active == 1)
			var/power_a = 0
			var/power_s = 0
			var/power_p = 0

			for(var/obj/machinery/the_singularity/singu in S)
				if(singu && !QDELETED(singu))
					power_s += singu.energy*max((singu.radius**2),1)/4
			if(P1?.air_contents)
				if(CA1.active != 0)
					power_p += P1.air_contents.toxins
					P1.air_contents.toxins -= 0.001 * mult
			if(P2?.air_contents)
				if(CA2.active != 0)
					power_p += P2.air_contents.toxins
					P2.air_contents.toxins -= 0.001 * mult
			if(P3?.air_contents)
				if(CA3.active != 0)
					power_p += P3.air_contents.toxins
					P3.air_contents.toxins -= 0.001 * mult
			if(P4?.air_contents)
				if(CA4.active != 0)
					power_p += P4.air_contents.toxins
					P4.air_contents.toxins -= 0.001 * mult
			power_a = power_p*power_s*50
			src.lastpower = power_a
			add_avail(power_a)
			SEND_SIGNAL(src,COMSIG_MECHCOMP_TRANSMIT_SIGNAL, "power=[num2text(round(power_a), 50)]&powerfmt=[engineering_notation(power_a)]W")
			..()
	else
		var/power_a = 0
		var/power_s = 0
		var/power_p = 0
		for(var/obj/machinery/the_singularity/singu in S)
			if(singu && !QDELETED(singu))
				power_s += singu.energy*((singu.radius*2+1)**2)/DEFAULT_AREA  //should give the area of the singularity and divide it by the area of a standard singularity(a 5x5)
		power_p += 50
		power_a = power_p*power_s*50
		src.lastpower = power_a
		add_avail(power_a)
		..()

/obj/machinery/power/collector_control/attack_hand(mob/user)
	if(src.active==1)
		src.active = 0
		boutput(user, "You turn off the collector control.")
		src.lastpower = 0
		UpdateIcon()
		return

	if(src.active==0)
		src.active = 1
		boutput(user, "You turn on the collector control.")
		updatecons()
		return

/obj/machinery/power/collector_control/attackby(obj/item/W, mob/user)
	if (iswrenchingtool(W))
		if(src.active)
			boutput(user, SPAN_ALERT("The [src.name] must be turned off first!"))
		else
			if (!src.anchored)
				playsound(src.loc, 'sound/items/Ratchet.ogg', 75, 1)
				boutput(user, "You secure the [src.name] to the floor.")
				src.anchored = ANCHORED
			else
				playsound(src.loc, 'sound/items/Ratchet.ogg', 75, 1)
				boutput(user, "You unsecure the [src.name].")
				src.anchored = UNANCHORED
			logTheThing(LOG_STATION, user, "[src.anchored ? "bolts" : "unbolts"] a [src.name] [src.anchored ? "to" : "from"] the floor at [log_loc(src)].") // Ditto (Convair880).
	else if(istype(W, /obj/item/device/analyzer/atmospheric))
		boutput(user, SPAN_NOTICE("The analyzer detects that [lastpower]W are being produced."))

	else
		src.add_fingerprint(user)
		boutput(user, SPAN_ALERT("You hit the [src.name] with your [W.name]!"))
		for(var/mob/M in AIviewers(src))
			if(M == user)	continue
			M.show_message(SPAN_ALERT("The [src.name] has been hit with the [W.name] by [user.name]!"))

///////////////////////////////////////// Singularity bomb /////////////////////////////

// Thing thing had zero logging despite being overhauled recently. I corrected that oversight (Convair880).
TYPEINFO(/obj/machinery/the_singularitybomb)
	mats = 14

ADMIN_INTERACT_PROCS(/obj/machinery/the_singularitybomb, proc/prime, proc/abort)
/obj/machinery/the_singularitybomb
	name = "\improper Singularity Bomb"
	desc = "A WMD that creates a singularity."
	icon = 'icons/obj/power.dmi'
	icon_state = "portgen0"
	anchored = UNANCHORED
	density = 1
	var/state = UNWRENCHED
	var/timing = 0
	var/time = 30
	var/last_tick = null
	var/mob/activator = null // For logging purposes.
	is_syndicate = 1
	var/bhole = 1

/obj/machinery/the_singularitybomb/attackby(obj/item/W, mob/user)
	src.add_fingerprint(user)

	if (iswrenchingtool(W))

		if(state == UNWRENCHED)
			state = WRENCHED
			playsound(src.loc, 'sound/items/Ratchet.ogg', 75, 1)
			boutput(user, "You secure the external reinforcing bolts to the floor.")
			src.anchored = ANCHORED
			return

		else if(state == WRENCHED)
			state = UNWRENCHED
			playsound(src.loc, 'sound/items/Ratchet.ogg', 75, 1)
			boutput(user, "You undo the external reinforcing bolts.")
			src.anchored = UNANCHORED
			return

	if(isweldingtool(W))
		if(timing)
			boutput(user, "Stop the countdown first.")
			return

		var/turf/T = user.loc


		if(state == WRENCHED)
			if(!W:try_weld(user, 1, noisy = 2))
				return
			boutput(user, "You start to weld the bomb to the floor.")
			sleep(5 SECONDS)

			logTheThing(LOG_STATION, user, "welds a [src.name] to the floor at [log_loc(src)].") // Like here (Convair880).

			if ((user.loc == T && user.equipped() == W))
				state = WELDED
				icon_state = "portgen1"
				boutput(user, "You weld the bomb to the floor.")
			else if((isrobot(user) && (user.loc == T)))
				state = WELDED
				icon_state = "portgen1"
				boutput(user, "You weld the bomb to the floor.")
			return

		if(state == WELDED)
			if(!W:try_weld(user, 1, noisy = 2))
				return
			boutput(user, "You start to cut the bomb free from the floor.")
			sleep(5 SECONDS)

			logTheThing(LOG_STATION, user, "cuts a [src.name] from the floor at [log_loc(src)].") // Hmm (Convair880).
			if (src.activator)
				src.activator = null

			if ((user.loc == T && user.equipped() == W))
				state = WRENCHED
				icon_state = "portgen0"
				boutput(user, "You cut the bomb free from the floor.")
			else if((isrobot(user) && (user.loc == T)))
				state = WRENCHED
				icon_state = "portgen0"
				boutput(user, "You cut the bomb free from the floor.")
			return

	else
		boutput(user, SPAN_ALERT("You hit the [src.name] with your [W.name]!"))
		for(var/mob/M in AIviewers(src))
			if(M == user)	continue
			M.show_message(SPAN_ALERT("The [src.name] has been hit with the [W.name] by [user.name]!"))

/obj/machinery/the_singularitybomb/Topic(href, href_list)
	..()
	if (usr.stat || usr.restrained() || usr.lying)
		return
	if ((in_interact_range(src, usr) && istype(src.loc, /turf)))
		src.add_dialog(usr)
		switch(href_list["action"]) //Yeah, this is weirdly set up. Planning to expand it later.
			if("trigger")
				switch(href_list["spec"])
					if("prime")
						if(!timing)
							src.prime()
						else
							boutput(usr, SPAN_ALERT("\The [src] is already primed!"))
					if("abort")
						if(timing)
							src.abort()
						else
							boutput(usr, SPAN_ALERT("\The [src] is already deactivated!"))
			if("timer")
				if(!timing)
					var/tp = text2num_safe(href_list["tp"])
					src.time += tp
					src.time = clamp(round(src.time), 30, 600)
				else
					boutput(usr, SPAN_ALERT("You can't change the time while the timer is engaged!"))
		/*
		if (href_list["time"])
			src.timing = text2num_safe(href_list["time"])
			if(timing) processing_items |= src
				src.icon_state = "portgen2"
			else
				src.icon_state = "portgen1"

		if (href_list["tp"])
			var/tp = text2num_safe(href_list["tp"])
			src.time += tp
			src.time = clamp(round(src.time), 60, 600)

		if (href_list["close"])
			usr.Browse(null, "window=timer")
			usr.machine = null
			return
		*/
		if (ismob(src.loc))
			attack_hand(src.loc)
		else
			src.updateUsrDialog()

		src.add_fingerprint(usr)
	else
		usr.Browse(null, "window=timer")
		return
	return

/obj/machinery/the_singularitybomb/proc/prime()
	src.timing = 1
	processing_items |= src
	src.icon_state = "portgen2"
	logTheThing(LOG_BOMBING, usr, "activated [src.name] ([src.time] seconds) at [log_loc(src)].")
	message_admins("[key_name(usr)] activated [src.name] ([src.time] seconds) at [log_loc(src)].")
	if (ismob(usr))
		src.activator = usr

/obj/machinery/the_singularitybomb/proc/abort()
	src.timing = 0
	src.icon_state = "portgen1"

	// And here (Convair880).
	logTheThing(LOG_BOMBING, usr, "deactivated [src.name][src.activator ? " (primed by [constructTarget(src.activator,"bombing")]" : ""] at [log_loc(src)].")
	message_admins("[key_name(usr)] deactivated [src.name][src.activator ? " (primed by [key_name(src.activator)])" : ""] at [log_loc(src)].")

/obj/machinery/the_singularitybomb/attack_ai(mob/user as mob)
	return

/obj/machinery/the_singularitybomb/attack_hand(mob/user)
	..()
	if(src.state != WELDED)
		boutput(user, "The bomb needs to be firmly secured to the floor first.")
		return
	if (user.stat || user.restrained() || user.lying)
		return
	if ((BOUNDS_DIST(src, user) == 0 && istype(src.loc, /turf)))
		src.add_dialog(user)
		/*
		var/dat = text("<TT><B>Timing Unit</B><br>[] []:[]<br><A href='byond://?src=\ref[];tp=-30'>-</A> <A href='byond://?src=\ref[];tp=-1'>-</A> <A href='byond://?src=\ref[];tp=1'>+</A> <A href='byond://?src=\ref[];tp=30'>+</A><br></TT>", (src.timing ? text("<A href='byond://?src=\ref[];time=0'>Timing</A>", src) : text("<A href='byond://?src=\ref[];time=1'>Not Timing</A>", src)), minute, second, src, src, src, src)
		dat += "<BR><BR><A href='byond://?src=\ref[src];close=1'>Close</A>"
		*/
		user.Browse(src.get_interface(), "window=timer")
		onclose(user, "timer")
	else
		user.Browse(null, "window=timer")
		src.remove_dialog(user)

	src.add_fingerprint(user)
	return

/obj/machinery/the_singularitybomb/proc/time()
	var/turf/T = get_turf(src.loc)
	for(var/mob/O in hearers(src.loc, null))
		O.show_message("[bicon(src)] *beep* *beep*", 3, "*beep* *beep*", 2)


	playsound(T, 'sound/effects/creaking_metal1.ogg', 100, FALSE, 5, 0.5)
	for (var/mob/M in range(7,T))
		boutput(M, "<span class='bold alert'>The contaiment field on \the [src] begins destabilizing!</span>")
		shake_camera(M, 5, 16)
	for (var/turf/TF in range(4,T))
		animate_shake(TF,5,1 * GET_DIST(TF,T),1 * GET_DIST(TF,T))
	particleMaster.SpawnSystem(new /datum/particleSystem/bhole_warning(T))

	SPAWN(3 SECONDS)
		for (var/mob/M in range(7,T))
			boutput(M, "<span class='bold alert'>The containment field on \the [src] fails completely!</span>")
			shake_camera(M, 5, 16)

		// And most importantly here (Convair880)!
		logTheThing(LOG_BOMBING, src.activator, "A [src.name] (primed by [src.activator ? "[src.activator]" : "*unknown*"]) detonates at [log_loc(src)].")
		message_admins("A [src.name] (primed by [src.activator ? "[key_name(src.activator)]" : "*unknown*"]) detonates at [log_loc(src)].")

		playsound(T, 'sound/machines/singulo_start.ogg', 90, FALSE, 5, flags=SOUND_IGNORE_SPACE)
		if (bhole)
			var/obj/B = new /obj/bhole(get_turf(src.loc), rand(1600, 2400), rand(75, 100))
			B.name = "gravitational singularity"
			B.color = "#FF00FF"
		else
			new /obj/machinery/the_singularity(get_turf(src.loc), rand(1600, 2400))

	return

/obj/machinery/the_singularitybomb/process()
	if (src.timing)
		if (src.time > 0)
			if (!last_tick) last_tick = world.time
			var/passed_time = round(max(round(world.time - last_tick),10) / 10)
			src.time = max(0, src.time - passed_time)
			last_tick = world.time
		else
			time()
			src.time = 0
			src.timing = 0
			last_tick = 0

		if (ismob(src.loc))
			attack_hand(src.loc)
		else
			for(var/mob/M in viewers(1, src))
				if (M.using_dialog_of(src))
					src.Attackhand(M)

	return

/obj/machinery/the_singularitybomb/proc/get_time()
	if(src.time < 0)
		return "DO:OM"
	else
		var/seconds = src.time % 60
		var/minutes = (src.time - seconds) / 60
		var/flick_seperator = (seconds % 2 == 0)  || !src.timing
		minutes = minutes < 10 ? "0[minutes]" : "[minutes]"
		seconds = seconds < 10 ? "0[seconds]" : "[seconds]"

		return "[minutes][flick_seperator ? ":" : " "][seconds]"

/obj/machinery/the_singularitybomb/proc/get_interface()
	return {"<html>
				<head>
					<style>
						body {
							font-family:verdana,sans-serif;

						}
						a {
							text-decoration:none;
						}
						.top_level {
							display: inline;
							border: 2px solid #333;
							padding:10px;
						}
						.timing_div {
							overflow:auto;
							padding:10px;
						}
						.timer {
							display:table-cell;
							color:#0A0;
							font-weight:bold;
							text-align:src.get_center();
							vertical-align:middle;
							border:3px solid #222;
							background-color:#111;
							padding:3px;
						}
						.timer.active {
							color:#F00;
						}
						.button {
							display:table-cell;
							color:#0A0;
							font-weight:bold;
							text-align:src.get_center();
							vertical-align:middle;
							border:3px solid #222;
							background-color:#111;
							padding:3px;
						}
						.button.timer_b {
							width:50px;
						}
						/*
						.button:hover {
							background-color:#222;
							border:3px solid #333;
						}
						*/
						#abort {
							color:#000;
							background-color:#A00;
						}
						/*
						#abort:hover {
							background-color:#600;
						}
						*/
						#prime {
							color:#000;
							background-color:#0A0;
						}
						/*
						#prime:hover {
							background-color:#060;
						}
						*/

						.timer_table {
							text-align:src.get_center();
							vertical-align:middle;
							width:200px;
						}
					</style>

				</head>
				<body bgcolor=#555>
					<div class="timing_div top_level">
						<table class="timer_table">
							<tr>
								<td class="timer[src.timing ? " active" : ""]" colspan=4>[src.get_time()]</td>
							</tr>

							<tr>
								<td>
									<a href="byond://?src=\ref[src];action=timer;tp=-30">
										<div class="button timer_b">
											--
										</div>
									</a>
								</td>
								<td>
									<a href="byond://?src=\ref[src];action=timer;tp=-1">
										<div class="button timer_b">
											-
										</div>
									</a>
								</td>
								<td>
									<a href="byond://?src=\ref[src];action=timer;tp=1">
										<div class="button timer_b">
											+
										</div>
									</a>
								</td>
								<td>
									<a href="byond://?src=\ref[src];action=timer;tp=30">
										<div class="button timer_b">
											++
										</div>
									</a>
								</td>
							</tr>
							<tr>
								<td colspan=2>
									<a href="byond://?src=\ref[src];action=trigger;spec=abort">
										<div class="button" id="abort">
											Abort
										</div>
									</a>
								</td>
								<td colspan=2>
									<a href="byond://?src=\ref[src];action=trigger;spec=prime">
										<div class="button" id="prime">
											Prime
										</div>
									</a>
								</td>
							</tr>
						</table>
					</div>
				</body>
			</html>"}

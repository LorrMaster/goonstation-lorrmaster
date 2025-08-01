#define COMMAND_LINK_COLOR "#0C0"
#define SECURITY_LINK_COLOR "#F00"
#define RESEARCH_LINK_COLOR "#90F"
#define MEDICAL_LINK_COLOR "#F9F"
#define ENGINEERING_LINK_COLOR "#F90"
#define CIVILIAN_LINK_COLOR "#09F"
#define SILICON_LINK_COLOR "#999"

#define NANOTRASEN_LINK_COLOR "#3348ff"
#define SYNDICATE_LINK_COLOR "#800"

ABSTRACT_TYPE(/datum/job)
/datum/job
	var/name = null
	var/list/alias_names = null
	var/initial_name = null
	var/linkcolor = "#0FF"

	/// Job starting wages
	var/wages = 0
	var/limit = -1
	var/list/trait_list = list() // specific job trait string, i.e. "training_security"
	/// job category flag for use with loops rather than a needing a bunch of type checks
	var/job_category = JOB_SPECIAL
	var/upper_limit = null //! defaults to `limit`
	var/lower_limit = 0
	var/admin_set_limit = FALSE //! has an admin manually set the limit to something
	var/variable_limit = FALSE //! does this job scale down at lower population counts
	var/add_to_manifest = TRUE //! On join, add to general, bank, and security records.
	var/no_late_join = FALSE
	var/no_jobban_from_this_job = FALSE
	///can you roll this job if you rolled antag with a non-traitor-allowed favourite job (e.g.: prevent sec mains from forcing only captain antag rounds)
	var/allow_antag_fallthrough = TRUE

	///Can this job roll antagonist? if FALSE ignores invalid_antagonist_roles
	var/can_roll_antag = TRUE
	///Which station antagonist roles can this job NOT be (e.g. ROLE_TRAITOR but not ROLE_NUKEOP)
	var/list/invalid_antagonist_roles = list()

	var/requires_whitelist = FALSE
	var/trusted_only = FALSE // Do we require mentor/HoS status to be played
	var/requires_supervisor_job = null //! String name of another job. The current job will only be available if the supervisor job is filled.
	var/needs_college = 0
	var/assigned = 0
	var/high_priority_job = FALSE
	///Fill up to this limit, then drop this job out of high priotity
	var/high_priority_limit = INFINITY
	//should a job be considered last for selection, but also as a last resort fallback job? NOTE: ignores other requirements such as round min/max
	var/low_priority_job = FALSE
	var/order_priority = 1 //! What order jobs are filled in within their priority tier, lower number = higher priority
	var/cant_allocate_unwanted = FALSE //! Job cannot be set to "unwanted" in player preferences.
	var/receives_miranda = FALSE
	var/list/receives_implants = null //! List of object paths of implant types given on spawn.
	var/receives_disk = FALSE //! Job spawns with cloning data disk, can specify a type
	var/obj/item/clothing/suit/security_badge/badge = null //! Typepath of the badge to spawn the player with
	var/announce_on_join = FALSE //! On join, send message to all players indicating who is fulfilling the role; primarily for heads of staff
	var/radio_announcement = TRUE //! The announcement computer will send a message when the player joins after round-start.
	var/list/alt_names = list()
	var/slot_card = /obj/item/card/id //! Object path of the ID card type to issue player. Overridden by `spawn_id`.
	var/spawn_id = TRUE //! Does player spawn with an ID. Overrides slot_card if TRUE.
	// Following slots support single item list or weighted list - Do not use regular lists or it will error!
	var/list/slot_head = list()
	var/list/slot_mask = list()
	var/list/slot_ears = list(/obj/item/device/radio/headset) // cogwerks experiment - removing default headsets
	var/list/slot_eyes = list()
	var/list/slot_suit = list()
	var/list/slot_jump = list()
	var/list/slot_glov = list()
	var/list/slot_foot = list()
	var/list/slot_back = list(/obj/item/storage/backpack)
	var/list/slot_belt = list(/obj/item/device/pda2)
	var/list/slot_poc1 = list() // Pay attention to size. Not everything is small enough to fit in jumpsckets.
	var/list/slot_poc2 = list()
	var/list/slot_lhan = list()
	var/list/slot_rhan = list()
	var/list/items_in_backpack = list() // stop giving everyone a free airtank gosh
	var/list/items_in_belt = list() // works the same as above but is for jobs that spawn with a belt that can hold things
	var/access_string = null // used to quickly grab access via string, i.e. "Chief Engineer", completely overrides var/list/access if non-null !!!
	var/list/access = list(access_fuck_all) // Please define in global get_access() proc (access.dm), so it can also be used by bots etc.
	var/mob/living/mob_type = /mob/living/carbon/human
	var/datum/mutantrace/starting_mutantrace = null
	var/change_name_on_spawn = FALSE
	var/tmp/special_spawn_location = null
	var/bio_effects = null
	var/objective = null
	var/rounds_needed_to_play = 0 //0 by default, set to the amount of rounds they should have in order to play this
	var/rounds_allowed_to_play = 0 //0 by default (which means infinite), set to the amount of rounds they are allowed to have in order to play this, primarily for assistant jobs
	var/map_can_autooverride = TRUE //! Base the initial limit of job slots on the number of map-defined job start locations.
	/// Does this job use the name and appearance from the character profile? (for tracking respawned names)
	var/uses_character_profile = TRUE
	/// The faction to be assigned to the mob on setup uses flags from factions.dm
	var/faction = list()

	var/short_description = null //! Description provided when a player hovers over the job name in latejoin menu
	var/wiki_link = null //! Link to the wiki page for this job

	///If this job should show in the ID computer (only works for staple jobs)
	var/show_in_id_comp = TRUE

	var/counts_as = null //! Name of a job that we count towards the cap of
	///if true, cryoing won't free up slots, only ghosting will
	///basically there should never be two of these
	var/unique = FALSE
	var/request_limit = 0 //!Maximum total `limit` via RoleControl request function
	var/request_cost = null //!Cost to open an additional slot using RoleControl
	var/player_requested = FALSE //! Flag if currently requested via RoleControl



	New()
		..()
		src.initial_name = src.name
		if (isnull(src.upper_limit))
			src.upper_limit = src.limit

		if (src.access_string)
			src.access = get_access(src.access_string)

#define SLOT_SCALING_UPPER_THRESHOLD 50 //the point at which we have maximum slots open
#define SLOT_SCALING_LOWER_THRESHOLD 20 //the point at which we have minimum slots open

	proc/recalculate_limit(player_count)
		if (src.limit < 0 || src.admin_set_limit) //don't mess with infinite slot or admin limit set jobs
			return src.limit
		if (player_count >= SLOT_SCALING_UPPER_THRESHOLD) //above this just open everything up
			src.limit = src.upper_limit
			return src.limit
		var/old_limit = src.limit
		//basic linear scale between upper and lower limits
		var/scalar = (player_count - SLOT_SCALING_LOWER_THRESHOLD) / (SLOT_SCALING_UPPER_THRESHOLD - SLOT_SCALING_LOWER_THRESHOLD)
		src.limit = src.lower_limit + scalar * (src.upper_limit - src.lower_limit)
		logTheThing(LOG_DEBUG, src, "Variable job limit for [src.name] calculated as [src.limit] slots at [player_count] player count")
		src.limit = round(src.limit, 1)
		src.limit = clamp(src.limit, src.lower_limit, src.upper_limit) //paranoia clamp, probably not needed
		if (src.limit != old_limit)
			logTheThing(LOG_DEBUG, src, "Altering variable job limit for [src.name] from [old_limit] to [src.limit] at [player_count] player count.")
		return src.limit

#undef SLOT_SCALING_UPPER_THRESHOLD
#undef SLOT_SCALING_LOWER_THRESHOLD

	onVarChanged(variable, oldval, newval)
		. = ..()
		if (variable == "limit")
			src.admin_set_limit = TRUE

	proc/special_setup(var/mob/M, no_special_spawn)
		SHOULD_NOT_SLEEP(TRUE)
		if (!M)
			return
		if (src.receives_miranda)
			M.verbs += /mob/proc/recite_miranda
			M.verbs += /mob/proc/add_miranda
		LAZYLISTADDUNIQUE(M.faction, src.faction)
		for (var/T in src.trait_list)
			M.traitHolder.addTrait(T)
		SPAWN(0)
			if (length(src.receives_implants))
				for(var/obj/item/implant/implant as anything in src.receives_implants)
					if(ispath(implant))
						new implant(M)

			var/give_access_implant = ismobcritter(M)
			if(!spawn_id && (length(access) > 0 || length(access) == 1 && access[1] != access_fuck_all))
				give_access_implant = TRUE
			if (give_access_implant)
				var/obj/item/implant/access/I = new /obj/item/implant/access(M)
				I.access.access = src.access.Copy()
				I.uses = -1

			if (src.special_spawn_location && !no_special_spawn)
				var/location = src.special_spawn_location
				if (!istype(src.special_spawn_location, /turf))
					location = pick_landmark(src.special_spawn_location)
				if (!isnull(location))
					M.set_loc(location)

			if (ishuman(M) && src.bio_effects)
				var/list/picklist = params2list(src.bio_effects)
				if (length(picklist))
					for(var/pick in picklist)
						M.bioHolder.AddEffect(pick)

			if (ishuman(M) && src.starting_mutantrace)
				var/mob/living/carbon/human/H = M
				H.set_mutantrace(src.starting_mutantrace)

			if (src.objective)
				var/datum/objective/newObjective = new /datum/objective/crew(src.objective, M.mind)
				boutput(M, "<B>Your OPTIONAL Crew Objectives are as follows:</b>")
				boutput(M, "<B>Objective #1</B>: [newObjective.explanation_text]")

			if (M.client && src.change_name_on_spawn && !jobban_isbanned(M, "Custom Names"))
				//if (ishuman(M)) //yyeah this doesn't work with critters fix later
				var/default = M.real_name + " the " + src.name
				var/orig_real = M.real_name
				M.choose_name(3, src.name, default)
				if(M.real_name != default && M.real_name != orig_real)
					phrase_log.log_phrase("name-[ckey(src.name)]", M.real_name, no_duplicates=TRUE)

	/// Is this job highlighted for latejoiners
	proc/is_highlighted()
		return job_controls.priority_job == src || src.player_requested

	proc/can_be_antag(var/role)
		if (!src.can_roll_antag)
			return FALSE
		return !(role in src.invalid_antagonist_roles)

	/// The default miranda's rights for this job
	proc/get_default_miranda()
		return DEFAULT_MIRANDA

	///Check if a string matches this job's name or alias with varying case sensitivity
	proc/match_to_string(string, case_sensitive)
		if (case_sensitive)
			return src.name == string || (string in src.alias_names)
		else
			if(cmptext(src.name, string))
				return TRUE
			for (var/alias in src.alias_names)
				if (cmptext(src.name, string))
					return TRUE

	proc/has_rounds_needed(datum/player/player, var/min = 0, var/max = 0)
		if (src.rounds_needed_to_play)
			min = src.rounds_needed_to_play
		if (src.rounds_allowed_to_play)
			max = src.rounds_allowed_to_play
		if (!min && !max)
			return TRUE

		var/round_num = player.get_rounds_participated()
		if (isnull(round_num)) //fetch failed, assume they're allowed because everything is probably broken right now
			return TRUE
		if (player?.cloudSaves.getData("bypass_round_reqs")) //special flag for account transfers etc.
			return TRUE
		if (round_num >= min && (round_num <= max || !max))
			return TRUE
		return FALSE


// Command Jobs

ABSTRACT_TYPE(/datum/job/command)
/datum/job/command
	linkcolor = COMMAND_LINK_COLOR
	slot_card = /obj/item/card/id/command
	map_can_autooverride = FALSE
	invalid_antagonist_roles = list(ROLE_HEAD_REVOLUTIONARY, ROLE_GANG_MEMBER, ROLE_GANG_LEADER, ROLE_SPY_THIEF, ROLE_CONSPIRATOR)
	job_category = JOB_COMMAND
	unique = TRUE

	special_setup(mob/M, no_special_spawn)
		. = ..()
		var/image/image = image('icons/mob/antag_overlays.dmi', icon_state = "head", loc = M)
		image.appearance_flags = PIXEL_SCALE | RESET_ALPHA | RESET_COLOR | RESET_TRANSFORM | KEEP_APART
		get_image_group(CLIENT_IMAGE_GROUP_HEADS_OF_STAFF).add_image(image)

/datum/job/command/captain
	name = "Captain"
	limit = 1
	wages = PAY_EXECUTIVE
	access_string = "Captain"
	high_priority_job = TRUE
	receives_miranda = TRUE
	can_roll_antag = FALSE
	announce_on_join = TRUE
	receives_implants = list(/obj/item/implant/health/security/anti_mindhack)
	wiki_link = "https://wiki.ss13.co/Captain"

	slot_card = /obj/item/card/id/gold
	slot_belt = list(/obj/item/device/pda2/captain)
	slot_back = list(/obj/item/storage/backpack/captain)
	slot_jump = list(/obj/item/clothing/under/rank/captain)
	slot_suit = list(/obj/item/clothing/suit/armor/captain)
	slot_foot = list(/obj/item/clothing/shoes/swat/captain)
	slot_glov = list(/obj/item/clothing/gloves/swat/captain)
	slot_head = list(/obj/item/clothing/head/caphat)
	slot_eyes = list(/obj/item/clothing/glasses/sunglasses)
	slot_ears = list(/obj/item/device/radio/headset/command/captain)
	slot_poc1 = list(/obj/item/disk/data/floppy/read_only/authentication)
	items_in_backpack = list(/obj/item/storage/box/id_kit,/obj/item/device/flash)
	rounds_needed_to_play = ROUNDS_MIN_CAPTAIN

	derelict
		//name = "NT-SO Commander"
		name = null
		limit = 0
		slot_suit = list(/obj/item/clothing/suit/armor/captain/centcomm)
		slot_jump = list(/obj/item/clothing/under/misc/turds)
		slot_head = list(/obj/item/clothing/head/centhat)
		slot_belt = list(/obj/item/tank/pocket/extended/oxygen)
		slot_glov = list(/obj/item/clothing/gloves/fingerless)
		slot_back = list(/obj/item/storage/backpack/NT)
		slot_mask = list(/obj/item/clothing/mask/gas)
		slot_eyes = list(/obj/item/clothing/glasses/thermal)
		items_in_backpack = list(/obj/item/crowbar,/obj/item/device/light/flashlight,/obj/item/camera,/obj/item/gun/energy/egun)
		special_spawn_location = LANDMARK_HTR_TEAM

		special_setup(var/mob/living/carbon/human/M)
			..()
			if (!M)
				return
			M.show_text("<b>Something has gone terribly wrong here! Search for survivors and escape together.</b>", "blue")

/datum/job/command/head_of_personnel
	name = "Head of Personnel"
	limit = 1
	wages = PAY_IMPORTANT
	access_string = "Head of Personnel"
	wiki_link = "https://wiki.ss13.co/Head_of_Personnel"

	allow_antag_fallthrough = FALSE
	receives_miranda = TRUE
	announce_on_join = TRUE


	slot_back = list(/obj/item/storage/backpack)
	slot_belt = list(/obj/item/device/pda2/hop)
	slot_jump = list(/obj/item/clothing/under/suit/hop)
	slot_foot = list(/obj/item/clothing/shoes/brown)
	slot_ears = list(/obj/item/device/radio/headset/command/hop)
	slot_poc1 = list(/obj/item/pocketwatch)
	items_in_backpack = list(/obj/item/storage/box/id_kit,/obj/item/device/flash,/obj/item/storage/box/accessimp_kit)

/datum/job/command/head_of_security
	name = "Head of Security"
	limit = 1
	wages = PAY_IMPORTANT
	trait_list = list("training_drinker", "training_security")
	access_string = "Head of Security"
	requires_whitelist = TRUE
	receives_miranda = TRUE
	can_roll_antag = FALSE
	announce_on_join = TRUE
	receives_disk = /obj/item/disk/data/floppy/sec_command
	badge = /obj/item/clothing/suit/security_badge
	show_in_id_comp = FALSE
	receives_implants = list(/obj/item/implant/health/security/anti_mindhack)
	items_in_backpack = list(/obj/item/device/flash)
	wiki_link = "https://wiki.ss13.co/Head_of_Security"

	slot_jump = list(/obj/item/clothing/under/rank/head_of_security)
	slot_suit = list(/obj/item/clothing/suit/armor/vest)
	slot_back = list(/obj/item/storage/backpack/security)
	slot_belt = list(/obj/item/device/pda2/hos)
	slot_poc1 = list(/obj/item/storage/security_pouch) //replaces sec starter kit
	slot_poc2 = list(/obj/item/requisition_token/security)
	slot_foot = list(/obj/item/clothing/shoes/swat)
	slot_head = list(/obj/item/clothing/head/hos_hat)
	slot_ears = list(/obj/item/device/radio/headset/command/hos)
	slot_eyes = list(/obj/item/clothing/glasses/sunglasses/sechud)

	derelict
		name = null//"NT-SO Special Operative"
		limit = 0
		slot_suit = list(/obj/item/clothing/suit/armor/NT)
		slot_jump = list(/obj/item/clothing/under/misc/turds)
		slot_head = list(/obj/item/clothing/head/NTberet)
		slot_belt = list(/obj/item/tank/pocket/extended/oxygen)
		slot_mask = list(/obj/item/clothing/mask/gas)
		slot_glov = list(/obj/item/clothing/gloves/latex)
		slot_back = list(/obj/item/storage/backpack/NT)
		slot_eyes = list(/obj/item/clothing/glasses/thermal)
		items_in_backpack = list(/obj/item/crowbar,/obj/item/device/light/flashlight,/obj/item/breaching_charge,/obj/item/breaching_charge,/obj/item/gun/energy/plasma_gun)
		special_spawn_location = LANDMARK_HTR_TEAM

		special_setup(var/mob/living/carbon/human/M)
			..()
			if (!M)
				return
			M.show_text("<b>Something has gone terribly wrong here! Search for survivors and escape together.</b>", "blue")

/datum/job/command/chief_engineer
	name = "Chief Engineer"
	limit = 1
	wages = PAY_IMPORTANT
	trait_list = list("training_engineer")
	access_string = "Chief Engineer"
	announce_on_join = TRUE
	wiki_link = "https://wiki.ss13.co/Chief_Engineer"

	slot_back = list(/obj/item/storage/backpack/engineering)
	slot_belt = list(/obj/item/storage/belt/utility/prepared/ceshielded)
	slot_glov = list(/obj/item/clothing/gloves/yellow)
	slot_foot = list(/obj/item/clothing/shoes/brown)
	slot_head = list(/obj/item/clothing/head/helmet/hardhat/chief_engineer)
	slot_eyes = list(/obj/item/clothing/glasses/toggleable/meson)
	slot_jump = list(/obj/item/clothing/under/rank/chief_engineer)
	slot_ears = list(/obj/item/device/radio/headset/command/ce)
	slot_poc1 = list(/obj/item/paper/book/from_file/pocketguide/engineering)
	slot_poc2 = list(/obj/item/device/pda2/chiefengineer)
	items_in_backpack = list(/obj/item/device/flash, /obj/item/rcd_ammo/medium)

	derelict
		name = null//"Salvage Chief"
		limit = 0
		slot_suit = list(/obj/item/clothing/suit/space/industrial)
		slot_foot = list(/obj/item/clothing/shoes/magnetic)
		slot_head = list(/obj/item/clothing/head/helmet/space/industrial)
		slot_belt = list(/obj/item/tank/pocket/oxygen)
		slot_mask = list(/obj/item/clothing/mask/gas)
		slot_eyes = list(/obj/item/clothing/glasses/thermal) // mesons look fuckin weird in the dark
		items_in_backpack = list(/obj/item/crowbar,/obj/item/rcd,/obj/item/rcd_ammo,/obj/item/rcd_ammo,/obj/item/device/light/flashlight,/obj/item/cell/cerenkite)
		special_spawn_location = LANDMARK_HTR_TEAM

		special_setup(var/mob/living/carbon/human/M)
			..()
			if (!M)
				return
			M.show_text("<b>Something has gone terribly wrong here! Search for survivors and escape together.</b>", "blue")

/datum/job/command/research_director
	name = "Research Director"
	limit = 1
	wages = PAY_IMPORTANT
	trait_list = list("training_scientist")
	access_string = "Research Director"
	announce_on_join = TRUE
	wiki_link = "https://wiki.ss13.co/Research_Director"

	slot_back = list(/obj/item/storage/backpack/research)
	slot_belt = list(/obj/item/device/pda2/research_director)
	slot_foot = list(/obj/item/clothing/shoes/brown)
	slot_jump = list(/obj/item/clothing/under/rank/research_director)
	slot_suit = list(/obj/item/clothing/suit/labcoat/research_director)
	slot_rhan = list(/obj/item/clipboard/with_pen)
	slot_eyes = list(/obj/item/clothing/glasses/spectro)
	slot_ears = list(/obj/item/device/radio/headset/command/rd)
	items_in_backpack = list(/obj/item/device/flash)

	special_setup(var/mob/living/carbon/human/M)
		..()
		for_by_tcl(heisenbee, /obj/critter/domestic_bee/heisenbee)
			if (!heisenbee.beeMom)
				heisenbee.beeMom = M
				heisenbee.beeMomCkey = M.ckey

/datum/job/command/medical_director
	name = "Medical Director"
	limit = 1
	wages = PAY_IMPORTANT
	trait_list = list("training_medical")
	access_string = "Medical Director"
	announce_on_join = TRUE
	wiki_link = "https://wiki.ss13.co/Medical_Director"

	slot_back = list(/obj/item/storage/backpack/medic)
	slot_glov = list(/obj/item/clothing/gloves/latex)
	slot_belt = list(/obj/item/storage/belt/medical/prepared)
	slot_foot = list(/obj/item/clothing/shoes/brown)
	slot_jump = list(/obj/item/clothing/under/rank/medical_director)
	slot_suit = list(/obj/item/clothing/suit/labcoat/medical_director)
	slot_ears = list(/obj/item/device/radio/headset/command/md)
	slot_eyes = list(/obj/item/clothing/glasses/healthgoggles/upgraded)
	slot_poc1 = list(/obj/item/device/pda2/medical_director)
	items_in_backpack = list(/obj/item/device/flash)

// Security Jobs

ABSTRACT_TYPE(/datum/job/security)
/datum/job/security
	linkcolor = SECURITY_LINK_COLOR
	slot_card = /obj/item/card/id/security
	receives_miranda = TRUE
	job_category = JOB_SECURITY

/datum/job/security/security_officer
	name = "Security Officer"
	limit = 5
	lower_limit = 3
	variable_limit = TRUE
	high_priority_job = TRUE
	high_priority_limit = 2 //always try to make sure there's at least a couple of secoffs
	order_priority = 2 //fill secoffs after captain and AI
	wages = PAY_TRADESMAN
	trait_list = list("training_security")
	access_string = "Security Officer"
	can_roll_antag = FALSE
	receives_implants = list(/obj/item/implant/health/security/anti_mindhack)
	receives_disk = /obj/item/disk/data/floppy/security
	badge = /obj/item/clothing/suit/security_badge
	slot_back = list(/obj/item/storage/backpack/security)
	slot_belt = list(/obj/item/device/pda2/security)
	slot_jump = list(/obj/item/clothing/under/rank/security)
	slot_suit = list(/obj/item/clothing/suit/armor/vest)
	slot_head = list(/obj/item/clothing/head/helmet/hardhat/security)
	slot_foot = list(/obj/item/clothing/shoes/swat)
	slot_ears = list(/obj/item/device/radio/headset/security)
	slot_eyes = list(/obj/item/clothing/glasses/sunglasses/sechud)
	slot_poc1 = list(/obj/item/storage/security_pouch) //replaces sec starter kit
	slot_poc2 = list(/obj/item/requisition_token/security)
	rounds_needed_to_play = ROUNDS_MIN_SECURITY
	wiki_link = "https://wiki.ss13.co/Security_Officer"

	assistant
		name = "Security Assistant"
		limit = 3
		lower_limit = 2
		high_priority_job = FALSE //nope
		wages = PAY_UNTRAINED
		access_string = "Security Assistant"
		receives_implants = list(/obj/item/implant/health/security)
		slot_back = list(/obj/item/storage/backpack/security)
		slot_jump = list(/obj/item/clothing/under/rank/security/assistant)
		slot_suit = list()
		slot_glov = list(/obj/item/clothing/gloves/fingerless)
		slot_head = list(/obj/item/clothing/head/red)
		slot_foot = list(/obj/item/clothing/shoes/brown)
		slot_poc1 = list(/obj/item/storage/security_pouch/assistant)
		slot_poc2 = list(/obj/item/requisition_token/security/assistant)
		items_in_backpack = list(/obj/item/paper/book/from_file/space_law)
		rounds_needed_to_play = ROUNDS_MIN_SECASS
		wiki_link = "https://wiki.ss13.co/Security_Assistant"

	derelict
		//name = "NT-SO Officer"
		name = null
		limit = 0
		slot_suit = list(/obj/item/clothing/suit/armor/NT_alt)
		slot_jump = list(/obj/item/clothing/under/misc/turds)
		slot_head = list(/obj/item/clothing/head/helmet/swat)
		slot_glov = list(/obj/item/clothing/gloves/fingerless)
		slot_back = list(/obj/item/storage/backpack/NT)
		slot_belt = list(/obj/item/gun/energy/laser_gun)
		slot_eyes = list(/obj/item/clothing/glasses/sunglasses)
		items_in_backpack = list(/obj/item/crowbar,/obj/item/device/light/flashlight,/obj/item/baton,/obj/item/breaching_charge,/obj/item/breaching_charge)
		special_spawn_location = LANDMARK_HTR_TEAM

		special_setup(var/mob/living/carbon/human/M)
			..()
			if (!M)
				return
			M.show_text("<b>Something has gone terribly wrong here! Search for survivors and escape together.</b>", "blue")

/datum/job/security/detective
	name = "Detective"
	limit = 1
	wages = PAY_TRADESMAN
	trait_list = list("training_drinker")
	access_string = "Detective"
	badge = /obj/item/clothing/suit/security_badge
	invalid_antagonist_roles = list(ROLE_HEAD_REVOLUTIONARY, ROLE_GANG_LEADER, ROLE_GANG_MEMBER, ROLE_CONSPIRATOR)
	allow_antag_fallthrough = FALSE
	unique = TRUE
	slot_back = list(/obj/item/storage/backpack)
	slot_belt = list(/obj/item/storage/belt/security/shoulder_holster)
	slot_poc1 = list(/obj/item/device/pda2/forensic)
	slot_jump = list(/obj/item/clothing/under/rank/det)
	slot_foot = list(/obj/item/clothing/shoes/detective)
	slot_head = list(/obj/item/clothing/head/det_hat)
	slot_glov = list(/obj/item/clothing/gloves/black)
	slot_suit = list(/obj/item/clothing/suit/det_suit)
	slot_ears = list(/obj/item/device/radio/headset/detective)
	items_in_backpack = list(/obj/item/clothing/glasses/vr,/obj/item/storage/box/detectivegun,/obj/item/camera/large)
	map_can_autooverride = FALSE
	rounds_needed_to_play = ROUNDS_MIN_DETECTIVE
	wiki_link = "https://wiki.ss13.co/Detective"

	special_setup(var/mob/living/carbon/human/M)
		..()

		if (M.traitHolder && !M.traitHolder.hasTrait("smoker"))
			items_in_backpack += list(/obj/item/device/light/zippo) //Smokers start with a trinket version

// Research Jobs

ABSTRACT_TYPE(/datum/job/research)
/datum/job/research
	linkcolor = RESEARCH_LINK_COLOR
	slot_card = /obj/item/card/id/research
	job_category = JOB_RESEARCH

/datum/job/research/scientist
	name = "Scientist"
	limit = 5
	wages = PAY_DOCTORATE
	trait_list = list("training_scientist")
	access_string = "Scientist"
	slot_back = list(/obj/item/storage/backpack/research)
	slot_belt = list(/obj/item/device/pda2/toxins)
	slot_jump = list(/obj/item/clothing/under/rank/scientist)
	slot_suit = list(/obj/item/clothing/suit/labcoat/science)
	slot_foot = list(/obj/item/clothing/shoes/white)
	slot_mask = list(/obj/item/clothing/mask/gas)
	slot_lhan = list(/obj/item/tank/air)
	slot_ears = list(/obj/item/device/radio/headset/research)
	slot_eyes = list(/obj/item/clothing/glasses/spectro)
	slot_poc1 = list(/obj/item/pen = 50, /obj/item/pen/fancy = 25, /obj/item/pen/red = 5, /obj/item/pen/pencil = 20)
	wiki_link = "https://wiki.ss13.co/Scientist"

/datum/job/research/research_assistant
	name = "Research Trainee"
	limit = 2
	wages = PAY_UNTRAINED
	trait_list = list("training_scientist")
	access_string = "Scientist"
	rounds_allowed_to_play = ROUNDS_MAX_RESASS
	slot_back = list(/obj/item/storage/backpack/research)
	slot_ears = list(/obj/item/device/radio/headset/research)
	slot_jump = list(/obj/item/clothing/under/color/purple)
	slot_foot = list(/obj/item/clothing/shoes/white)
	slot_belt = list(/obj/item/device/pda2/toxins)
	slot_eyes = list(/obj/item/clothing/glasses/spectro)
	slot_poc1 = list(/obj/item/pen = 50, /obj/item/pen/fancy = 25, /obj/item/pen/red = 5, /obj/item/pen/pencil = 20)
	wiki_link = "https://wiki.ss13.co/Research_Assistant"

ABSTRACT_TYPE(/datum/job/medical)
/datum/job/medical
	linkcolor = MEDICAL_LINK_COLOR
	slot_card = /obj/item/card/id/medical
	job_category = JOB_MEDICAL

/datum/job/medical/medical_doctor
	name = "Medical Doctor"
	limit = 5
	wages = PAY_DOCTORATE
	trait_list = list("training_medical")
	access_string = "Medical Doctor"
	slot_back = list(/obj/item/storage/backpack/medic)
	slot_glov = list(/obj/item/clothing/gloves/latex)
	slot_belt = list(/obj/item/storage/belt/medical/prepared)
	slot_jump = list(/obj/item/clothing/under/rank/medical)
	slot_suit = list(/obj/item/clothing/suit/labcoat/medical)
	slot_foot = list(/obj/item/clothing/shoes/red)
	slot_ears = list(/obj/item/device/radio/headset/medical)
	slot_eyes = list(/obj/item/clothing/glasses/healthgoggles/upgraded)
	slot_poc1 = list(/obj/item/device/pda2/medical)
	slot_poc2 = list(/obj/item/paper/book/from_file/pocketguide/medical)
	items_in_backpack = list(/obj/item/crowbar/blue) // cogwerks: giving medics a guaranteed air tank, stealing it from roboticists (those fucks)
	// 2018: guaranteed air tanks now spawn in boxes (depending on backpack type) to save room
	wiki_link = "https://wiki.ss13.co/Medical_Doctor"

	derelict
		//name = "Salvage Medic"
		name = null
		limit = 0
		slot_suit = list(/obj/item/clothing/suit/armor/vest)
		slot_head = list(/obj/item/clothing/head/helmet/swat)
		slot_belt = list(/obj/item/tank/pocket/oxygen)
		slot_mask = list(/obj/item/clothing/mask/breath)
		slot_eyes = list(/obj/item/clothing/glasses/healthgoggles/upgraded)
		slot_glov = list(/obj/item/clothing/gloves/latex)
		items_in_backpack = list(/obj/item/crowbar,/obj/item/device/light/flashlight,/obj/item/storage/firstaid/regular,/obj/item/storage/firstaid/regular)
		special_spawn_location = LANDMARK_HTR_TEAM

		special_setup(var/mob/living/carbon/human/M)
			..()
			if (!M) return
			M.show_text("<b>Something has gone terribly wrong here! Search for survivors and escape together.</b>", "blue")

/datum/job/medical/geneticist
	name = "Geneticist"
	limit = 2
	wages = PAY_DOCTORATE
	access_string = "Geneticist"
	slot_back = list(/obj/item/storage/backpack/genetics)
	slot_belt = list(/obj/item/device/pda2/genetics)
	slot_jump = list(/obj/item/clothing/under/rank/geneticist)
	slot_foot = list(/obj/item/clothing/shoes/white)
	slot_suit = list(/obj/item/clothing/suit/labcoat/genetics)
	slot_ears = list(/obj/item/device/radio/headset/medical)
	slot_poc1 = list(/obj/item/device/analyzer/genetic)
	wiki_link = "https://wiki.ss13.co/Geneticist"

/datum/job/medical/roboticist
	name = "Roboticist"
	limit = 3
	wages = PAY_DOCTORATE
	trait_list = list("training_medical")
	access_string = "Roboticist"
	slot_back = list(/obj/item/storage/backpack/robotics)
	slot_belt = list(/obj/item/storage/belt/roboticist/prepared)
	slot_jump = list(/obj/item/clothing/under/rank/roboticist)
	slot_foot = list(/obj/item/clothing/shoes/black)
	slot_suit = list(/obj/item/clothing/suit/labcoat/robotics)
	slot_glov = list(/obj/item/clothing/gloves/latex)
	slot_eyes = list(/obj/item/clothing/glasses/healthgoggles/upgraded)
	slot_ears = list(/obj/item/device/radio/headset/medical)
	slot_poc1 = list(/obj/item/device/pda2/medical/robotics)
	slot_poc2 = list(/obj/item/reagent_containers/mender/brute)
	wiki_link = "https://wiki.ss13.co/Roboticist"

/datum/job/medical/medical_assistant
	name = "Medical Trainee"
	limit = 2
	wages = PAY_UNTRAINED
	trait_list = list("training_medical")
	access_string = "Medical Doctor"
	rounds_allowed_to_play = ROUNDS_MAX_MEDASS
	slot_back = list(/obj/item/storage/backpack/medic)
	slot_belt = list(/obj/item/storage/belt/medical/prepared)
	slot_foot = list(/obj/item/clothing/shoes/red)
	slot_ears = list(/obj/item/device/radio/headset/medical)
	slot_glov = list(/obj/item/clothing/gloves/latex)
	slot_eyes = list(/obj/item/clothing/glasses/healthgoggles/upgraded)
	slot_poc1 = list(/obj/item/device/pda2/medical)
	slot_poc2 = list(/obj/item/paper/book/from_file/pocketguide/medical)
	slot_jump = list(/obj/item/clothing/under/scrub = 30,/obj/item/clothing/under/scrub/teal = 14,/obj/item/clothing/under/scrub/blue = 14,/obj/item/clothing/under/scrub/purple = 14,/obj/item/clothing/under/scrub/orange = 14,/obj/item/clothing/under/scrub/pink = 14)
	wiki_link = "https://wiki.ss13.co/Medical_Assistant"

// Engineering Jobs

ABSTRACT_TYPE(/datum/job/engineering)
/datum/job/engineering
	linkcolor = ENGINEERING_LINK_COLOR
	slot_card = /obj/item/card/id/engineering
	job_category = JOB_ENGINEERING

/datum/job/engineering/engineer
	name = "Engineer"
	limit = 8
	wages = PAY_TRADESMAN
	trait_list = list("training_engineer")
	access_string = "Engineer"
	slot_back = list(/obj/item/storage/backpack/engineering)
	slot_belt = list(/obj/item/storage/belt/utility/prepared)
	slot_jump = list(/obj/item/clothing/under/rank/engineer)
	slot_foot = list(/obj/item/clothing/shoes/orange)
	slot_lhan = list(/obj/item/storage/toolbox/mechanical/engineer_spawn)
	slot_glov = list(/obj/item/clothing/gloves/yellow)
	slot_poc1 = list(/obj/item/device/pda2/engine)
	slot_ears = list(/obj/item/device/radio/headset/engineer)
#ifdef HOTSPOTS_ENABLED
	items_in_backpack = list(/obj/item/paper/book/from_file/pocketguide/engineering, /obj/item/clothing/shoes/stomp_boots)
#else
	items_in_backpack = list(/obj/item/paper/book/from_file/pocketguide/engineering, /obj/item/old_grenade/oxygen)
#endif
	wiki_link = "https://wiki.ss13.co/Engineer"

	derelict
		name = null//"Salvage Engineer"
		limit = 0
		slot_suit = list(/obj/item/clothing/suit/space/engineer)
		slot_head = list(/obj/item/clothing/head/helmet/welding)
		slot_belt = list(/obj/item/tank/pocket/oxygen)
		slot_mask = list(/obj/item/clothing/mask/breath)
		items_in_backpack = list(/obj/item/crowbar,/obj/item/device/light/flashlight,/obj/item/device/light/glowstick,/obj/item/gun/kinetic/flaregun,/obj/item/ammo/bullets/flare,/obj/item/cell/cerenkite)
		special_spawn_location = LANDMARK_HTR_TEAM

		special_setup(var/mob/living/carbon/human/M)
			..()
			if (!M)
				return
			M.show_text("<b>Something has gone terribly wrong here! Search for survivors and escape together.</b>", "blue")

/datum/job/engineering/technical_assistant
	name = "Technical Trainee"
	limit = 2
	wages = PAY_UNTRAINED
	trait_list = list("training_engineer")
	access_string = "Engineer"
	rounds_allowed_to_play = ROUNDS_MAX_TECHASS
	slot_back = list(/obj/item/storage/backpack/engineering)
	slot_ears = list(/obj/item/device/radio/headset/engineer)
	slot_jump = list(/obj/item/clothing/under/color/yellow)
	slot_foot = list(/obj/item/clothing/shoes/brown)
	slot_lhan = list(/obj/item/storage/toolbox/mechanical/engineer_spawn)
	slot_glov = list(/obj/item/clothing/gloves/yellow)
	slot_belt = list(/obj/item/storage/belt/utility/prepared)
	slot_poc1 = list(/obj/item/device/pda2/engine)
	slot_poc2 = list(/obj/item/paper/book/from_file/pocketguide/engineering)
#ifdef HOTSPOTS_ENABLED
	items_in_backpack = list(/obj/item/clothing/shoes/stomp_boots)
#endif

	wiki_link = "https://wiki.ss13.co/Technical_Assistant"

/datum/job/engineering/quartermaster
	name = "Quartermaster"
	limit = 3
	wages = PAY_TRADESMAN
	trait_list = list("training_quartermaster")
	access_string = "Quartermaster"
	slot_glov = list(/obj/item/clothing/gloves/black)
	slot_foot = list(/obj/item/clothing/shoes/black)
	slot_jump = list(/obj/item/clothing/under/rank/cargo)
	slot_belt = list(/obj/item/device/pda2/quartermaster)
	slot_ears = list(/obj/item/device/radio/headset/shipping)
	slot_poc1 = list(/obj/item/paper/book/from_file/pocketguide/quartermaster)
	slot_poc2 = list(/obj/item/device/appraisal)
	wiki_link = "https://wiki.ss13.co/Quartermaster"

/datum/job/engineering/miner
	name = "Miner"
	#ifdef UNDERWATER_MAP
	limit = 6
	#else
	limit = 5
	#endif
	wages = PAY_TRADESMAN
	trait_list = list("training_miner")
	access_string = "Miner"
	slot_back = list(/obj/item/storage/backpack/engineering)
	slot_mask = list(/obj/item/clothing/mask/breath)
	slot_eyes = list(/obj/item/clothing/glasses/toggleable/meson)
	slot_belt = list(/obj/item/storage/belt/mining/prepared)
	slot_jump = list(/obj/item/clothing/under/rank/overalls)
	slot_foot = list(/obj/item/clothing/shoes/orange)
	slot_glov = list(/obj/item/clothing/gloves/black)
	slot_ears = list(/obj/item/device/radio/headset/miner)
	slot_poc1 = list(/obj/item/device/pda2/mining)
	#ifdef UNDERWATER_MAP
	slot_suit = list(/obj/item/clothing/suit/space/diving/engineering)
	slot_head = list(/obj/item/clothing/head/helmet/space/engineer/diving/engineering)
	items_in_backpack = list(/obj/item/paper/book/from_file/pocketguide/mining,
							/obj/item/clothing/shoes/flippers,
							/obj/item/item_box/glow_sticker)
	#else
	slot_suit = list(/obj/item/clothing/suit/space/engineer)
	slot_head = list(/obj/item/clothing/head/helmet/space/engineer)
	items_in_backpack = list(/obj/item/crowbar,
							/obj/item/paper/book/from_file/pocketguide/mining)
	#endif
	wiki_link = "https://wiki.ss13.co/Miner"

// Civilian Jobs

ABSTRACT_TYPE(/datum/job/civilian)
/datum/job/civilian
	linkcolor = CIVILIAN_LINK_COLOR
	slot_card = /obj/item/card/id/civilian
	job_category = JOB_CIVILIAN

/datum/job/civilian/chef
	name = "Chef"
	limit = 1
	wages = PAY_UNTRAINED
	trait_list = list("training_chef")
	access_string = "Chef"
	slot_belt = list(/obj/item/device/pda2/chef)
	slot_jump = list(/obj/item/clothing/under/rank/chef)
	slot_foot = list(/obj/item/clothing/shoes/chef)
	slot_head = list(/obj/item/clothing/head/chefhat)
	slot_suit = list(/obj/item/clothing/suit/chef)
	slot_ears = list(/obj/item/device/radio/headset/civilian)
	items_in_backpack = list(/obj/item/kitchen/rollingpin, /obj/item/kitchen/utensil/knife/cleaver, /obj/item/bell/kitchen)
	wiki_link = "https://wiki.ss13.co/Chef"

/datum/job/civilian/bartender
	name = "Bartender"
	alias_names = list("Barman")
	limit = 1
	wages = PAY_UNTRAINED
	trait_list = list("training_drinker", "training_bartender")
	access_string = "Bartender"
	slot_belt = list(/obj/item/device/pda2/bartender)
	slot_jump = list(/obj/item/clothing/under/rank/bartender)
	slot_foot = list(/obj/item/clothing/shoes/black)
	slot_suit = list(/obj/item/clothing/suit/armor/vest)
	slot_ears = list(/obj/item/device/radio/headset/civilian)
	slot_poc1 = list(/obj/item/cloth/towel/bar)
	slot_poc2 = list(/obj/item/reagent_containers/food/drinks/cocktailshaker)
	items_in_backpack = list(/obj/item/gun/kinetic/sawnoff, /obj/item/ammo/bullets/abg, /obj/item/paper/book/from_file/pocketguide/bartending)
	wiki_link = "https://wiki.ss13.co/Bartender"

/datum/job/civilian/botanist
	name = "Botanist"
	#ifdef MAP_OVERRIDE_DONUT3
	limit = 7
	#else
	limit = 5
	#endif
	wages = PAY_TRADESMAN
	access_string = "Botanist"
	slot_belt = list(/obj/item/device/pda2/botanist)
	slot_jump = list(/obj/item/clothing/under/rank/hydroponics)
	slot_foot = list(/obj/item/clothing/shoes/brown)
	slot_glov = list(/obj/item/clothing/gloves/black)
	slot_poc1 = list(/obj/item/paper/botany_guide)
	slot_ears = list(/obj/item/device/radio/headset/civilian)
	wiki_link = "https://wiki.ss13.co/Botanist"

	faction = list(FACTION_BOTANY)

/datum/job/civilian/rancher
	name = "Rancher"
	limit = 1
	wages = PAY_TRADESMAN
	access_string = "Rancher"
	slot_belt = list(/obj/item/storage/belt/rancher/prepared)
	slot_jump = list(/obj/item/clothing/under/rank/rancher)
	slot_head = list(/obj/item/clothing/head/cowboy)
	slot_foot = list(/obj/item/clothing/shoes/westboot/brown/rancher)
	slot_glov = list(/obj/item/clothing/gloves/black)
	slot_poc1 = list(/obj/item/paper/ranch_guide)
	slot_poc2 = list(/obj/item/device/pda2/botanist)
	slot_ears = list(/obj/item/device/radio/headset/civilian)
	items_in_backpack = list(/obj/item/device/camera_viewer/ranch,/obj/item/storage/box/knitting)
	wiki_link = "https://wiki.ss13.co/Rancher"

/datum/job/civilian/janitor
	name = "Janitor"
	limit = 3
	wages = PAY_TRADESMAN
	access_string = "Janitor"
	slot_belt = list(/obj/item/storage/fanny/janny)
	slot_jump = list(/obj/item/clothing/under/rank/janitor)
	slot_foot = list(/obj/item/clothing/shoes/galoshes)
	slot_glov = list(/obj/item/clothing/gloves/long)
	slot_rhan = list(/obj/item/mop)
	slot_ears = list(/obj/item/device/radio/headset/civilian)
	slot_poc1 = list(/obj/item/device/pda2/janitor)
	items_in_backpack = list(/obj/item/reagent_containers/glass/bucket, /obj/item/lamp_manufacturer/organic)
	wiki_link = "https://wiki.ss13.co/Janitor"

/datum/job/civilian/chaplain
	name = "Chaplain"
	limit = 1
	wages = PAY_UNTRAINED
	trait_list = list("training_chaplain")
	access_string = "Chaplain"
	slot_jump = list(/obj/item/clothing/under/rank/chaplain)
	slot_belt = list(/obj/item/device/pda2/chaplain)
	slot_foot = list(/obj/item/clothing/shoes/black)
	slot_ears = list(/obj/item/device/radio/headset/civilian)
	slot_lhan = list(/obj/item/bible/loaded)
	wiki_link = "https://wiki.ss13.co/Chaplain"

	special_setup(var/mob/living/carbon/human/M)
		..()
		OTHER_START_TRACKING_CAT(M, TR_CAT_CHAPLAINS)

/datum/job/civilian/staff_assistant
	name = "Staff Assistant"
	wages = PAY_UNTRAINED
	access_string = "Staff Assistant"
	no_jobban_from_this_job = TRUE
	low_priority_job = TRUE
	cant_allocate_unwanted = TRUE
	map_can_autooverride = FALSE
	slot_jump = list(/obj/item/clothing/under/rank/assistant)
	slot_foot = list(/obj/item/clothing/shoes/black)
	slot_ears = list(/obj/item/device/radio/headset/civilian)
	wiki_link = "https://wiki.ss13.co/Staff_Assistant"

	special_setup(mob/living/carbon/human/M, no_special_spawn)
		..()
		if (prob(20))
			M.stow_in_available(new /obj/item/paper/businesscard/seneca)


/datum/job/civilian/mail_courier
	name = "Mail Courier"
	alias_names = "Mailman"
	wages = PAY_TRADESMAN
	access_string = "Mail Courier"
	limit = 1
	slot_jump = list(/obj/item/clothing/under/misc/mail/syndicate)
	slot_head = list(/obj/item/clothing/head/mailcap)
	slot_foot = list(/obj/item/clothing/shoes/brown)
	slot_back = list(/obj/item/storage/backpack/satchel)
	slot_ears = list(/obj/item/device/radio/headset/mail)
	slot_poc1 = list(/obj/item/pinpointer/mail_recepient)
	slot_belt = list(/obj/item/device/pda2/quartermaster)
	items_in_backpack = list(/obj/item/wrapping_paper, /obj/item/satchel/mail, /obj/item/scissors, /obj/item/stamp)
	alt_names = list("Head of Deliverying", "Mail Bringer")
	wiki_link = "https://wiki.ss13.co/Mailman"

/datum/job/civilian/clown
	name = "Clown"
	limit = 1
	wages = PAY_DUMBCLOWN
	request_limit = 3 //this is definitely a bad idea
	request_cost = PAY_TRADESMAN*4
	trait_list = list("training_clown")
	access_string = "Clown"
	linkcolor = MEDICAL_LINK_COLOR // :o)
	slot_back = list()
	slot_belt = list(/obj/item/storage/fanny/funny)
	slot_mask = list(/obj/item/clothing/mask/clown_hat)
	slot_jump = list(/obj/item/clothing/under/misc/clown)
	slot_foot = list(/obj/item/clothing/shoes/clown_shoes)
	slot_lhan = list(/obj/item/instrument/bikehorn)
	slot_poc1 = list(/obj/item/device/pda2/clown)
	slot_poc2 = list(/obj/item/reagent_containers/food/snacks/plant/banana)
	slot_card = /obj/item/card/id/clown
	slot_ears = list(/obj/item/device/radio/headset/clown)
	items_in_belt = list(/obj/item/cloth/towel/clown)
	change_name_on_spawn = TRUE
	wiki_link = "https://wiki.ss13.co/Clown"

	faction = list(FACTION_CLOWN)

// AI and Cyborgs

/datum/job/civilian/AI
	name = "AI"
	linkcolor = SILICON_LINK_COLOR
	limit = 1
	no_late_join = TRUE
	high_priority_job = TRUE
	can_roll_antag = FALSE
	slot_ears = list()
	slot_card = null
	slot_back = list()
	slot_belt = list()
	items_in_backpack = list()
	uses_character_profile = FALSE
	show_in_id_comp = FALSE
	wiki_link = "https://wiki.ss13.co/Artificial_Intelligence"

	special_setup(var/mob/living/carbon/human/M)
		..()
		if (!M)
			return
		M.traitHolder.removeTrait("cyber_incompatible")
		return M.AIize()

/datum/job/civilian/cyborg
	name = "Cyborg"
	linkcolor = SILICON_LINK_COLOR
	limit = 8
	no_late_join = TRUE
	can_roll_antag = FALSE
	slot_ears = list()
	slot_card = null
	slot_back = list()
	slot_belt = list()
	items_in_backpack = list()
	uses_character_profile = FALSE
	show_in_id_comp = FALSE
	wiki_link = "https://wiki.ss13.co/Cyborg"

	special_setup(var/mob/living/carbon/human/M)
		..()
		if (!M)
			return
		var/mob/living/silicon/S = M.Robotize_MK2()
		APPLY_ATOM_PROPERTY(S, PROP_ATOM_ROUNDSTART_BORG, "borg")
		S.traitHolder.removeTrait("cyber_incompatible")
		return S

// Special Cases
ABSTRACT_TYPE(/datum/job/special)
/datum/job/special
	name = "Special Job"
	limit = 0
	wages = PAY_UNTRAINED
	wiki_link = "https://wiki.ss13.co/Jobs#Gimmick_Jobs" // fallback for those without their own page

#ifdef I_WANNA_BE_THE_JOB
/datum/job/special/imcoder
	name = "IMCODER"
	// Used for debug testing. No need to define special landmark, this overrides job picks
	access_string = "Captain"
	limit = -1
	slot_belt = list(/obj/item/storage/belt/utility/prepared/ceshielded)
	slot_jump = list(/obj/item/clothing/under/rank/assistant)
	slot_foot = list(/obj/item/clothing/shoes/magnetic)
	slot_glov = list(/obj/item/clothing/gloves/yellow)
	slot_ears = list(/obj/item/device/radio/headset)
	slot_head = list(/obj/item/clothing/head/helmet/space/light/engineer)
	slot_suit = list(/obj/item/clothing/suit/space/light/engineer)
	slot_back = list(/obj/item/storage/backpack)
	// slot_mask = list(/obj/item/clothing/mask/gas)
	items_in_backpack = list(
		/obj/item/rcd/construction/safe/admin_crimes,
		/obj/item/device/analyzer/atmospheric/upgraded,
		/obj/item/sheet/steel/fullstack,
		/obj/item/storage/box/cablesbox,
		/obj/item/tank/oxygen,
	)
#endif

/datum/job/special/station_builder
	// Used for Construction game mode, where you build the station
	name = "Station Builder"
	can_roll_antag = FALSE
	limit = 0
	wages = PAY_TRADESMAN
	trait_list = list("training_engineer")
	access_string = "Construction Worker"
	slot_belt = list(/obj/item/storage/belt/utility/prepared)
	slot_jump = list(/obj/item/clothing/under/rank/engineer)
	slot_foot = list(/obj/item/clothing/shoes/magnetic)
	slot_glov = list(/obj/item/clothing/gloves/black)
	slot_ears = list(/obj/item/device/radio/headset/engineer)
	slot_rhan = list(/obj/item/tank/jetpack)
	slot_eyes = list(/obj/item/clothing/glasses/construction)
	slot_poc1 = list(/obj/item/currency/spacecash/fivehundred)
	slot_poc2 = list(/obj/item/room_planner)
	slot_suit = list(/obj/item/clothing/suit/space/engineer)
	slot_head = list(/obj/item/clothing/head/helmet/space/engineer)
	slot_mask = list(/obj/item/clothing/mask/breath)
	wiki_link = "https://wiki.ss13.co/Construction_Game_Mode" // ?

	items_in_backpack = list(/obj/item/rcd/construction, /obj/item/rcd_ammo/big, /obj/item/rcd_ammo/big, /obj/item/material_shaper,/obj/item/room_marker)

/datum/job/special/mime
	name = "Mime"
	limit = 1
	request_limit = 2
	linkcolor = SILICON_LINK_COLOR // greyscale mimes
	wages = PAY_DUMBCLOWN*2 // lol okay whatever
	request_cost = PAY_DOCTORATE * 4
	trait_list = list("training_mime")
	access_string = "Mime"
	slot_belt = list(/obj/item/device/pda2)
	slot_head = list(/obj/item/clothing/head/mime_bowler)
	slot_mask = list(/obj/item/clothing/mask/mime)
	slot_jump = list(/obj/item/clothing/under/misc/mime/alt)
	slot_suit = list(/obj/item/clothing/suit/scarf)
	slot_glov = list(/obj/item/clothing/gloves/latex)
	slot_foot = list(/obj/item/clothing/shoes/black)
	slot_poc1 = list(/obj/item/pen/crayon/white)
	slot_poc2 = list(/obj/item/paper)
	items_in_backpack = list(/obj/item/baguette, /obj/item/instrument/whistle/janitor)
	change_name_on_spawn = TRUE
	wiki_link = "https://wiki.ss13.co/Mime"

/datum/job/special/vice_officer
	name = "Vice Officer"
	linkcolor = SECURITY_LINK_COLOR
	limit = 0
	wages = PAY_TRADESMAN
	access_string = "Vice Officer"
	can_roll_antag = FALSE
	badge = /obj/item/clothing/suit/security_badge
	receives_miranda = TRUE
	slot_back = list(/obj/item/storage/backpack/withO2)
	slot_belt = list(/obj/item/device/pda2/security)
	slot_jump = list(/obj/item/clothing/under/misc/vice)
	slot_foot = list(/obj/item/clothing/shoes/brown)
	slot_ears = list( /obj/item/device/radio/headset/security)
	slot_poc1 = list(/obj/item/storage/security_pouch) //replaces sec starter kit
	slot_poc2 = list(/obj/item/requisition_token/security)
	wiki_link = "https://wiki.ss13.co/Part-Time_Vice_Officer"

/datum/job/special/forensic_technician
	name = "Forensic Technician"
	linkcolor = SECURITY_LINK_COLOR
	limit = 0
	wages = PAY_TRADESMAN
	access_string = "Forensic Technician"
	invalid_antagonist_roles = list(ROLE_HEAD_REVOLUTIONARY)
	slot_belt = list(/obj/item/device/pda2/security)
	slot_jump = list(/obj/item/clothing/under/color/darkred)
	slot_foot = list(/obj/item/clothing/shoes/black)
	slot_glov = list(/obj/item/clothing/gloves/latex)
	slot_ears = list(/obj/item/device/radio/headset/security)
	slot_poc1 = list(/obj/item/device/detective_scanner)
	items_in_backpack = list(/obj/item/tank/pocket/oxygen)

/datum/job/special/toxins_researcher
	name = "Toxins Researcher"
	linkcolor = RESEARCH_LINK_COLOR
	limit = 0
	wages = PAY_DOCTORATE
	trait_list = list("training_scientist")
	access_string = "Toxins Researcher"
	slot_belt = list(/obj/item/device/pda2/toxins)
	slot_jump = list(/obj/item/clothing/under/rank/scientist)
	slot_foot = list(/obj/item/clothing/shoes/white)
	slot_mask = list(/obj/item/clothing/mask/gas)
	slot_lhan = list(/obj/item/tank/air)
	slot_ears = list(/obj/item/device/radio/headset/research)

/datum/job/special/chemist
	name = "Chemist"
	linkcolor = RESEARCH_LINK_COLOR
	limit = 0
	wages = PAY_DOCTORATE
	trait_list = "training_scientist"
	access_string = "Chemist"
	slot_belt = list(/obj/item/device/pda2/toxins)
	slot_jump = list(/obj/item/clothing/under/rank/scientist)
	slot_foot = list(/obj/item/clothing/shoes/white)
	slot_ears = list(/obj/item/device/radio/headset/research)
	wiki_link = "https://wiki.ss13.co/Chemist"

/datum/job/special/atmospheric_technician
	name = "Atmospherish Technician"
	linkcolor = ENGINEERING_LINK_COLOR
	limit = 0
	wages = PAY_TRADESMAN
	access_string = "Atmospheric Technician"
	slot_belt = list(/obj/item/device/pda2/atmos)
	slot_eyes = list(/obj/item/clothing/glasses/toggleable/atmos)
	slot_jump = list(/obj/item/clothing/under/misc/atmospheric_technician)
	slot_foot = list(/obj/item/clothing/shoes/black)
	slot_lhan = list(/obj/item/storage/toolbox/mechanical)
	slot_poc1 = list(/obj/item/device/analyzer/atmospheric)
	slot_ears = list(/obj/item/device/radio/headset/engineer)
	items_in_backpack = list(/obj/item/tank/mini/oxygen,/obj/item/crowbar)
	wiki_link = "https://wiki.ss13.co/Atmospheric_Technician"

/datum/job/special/comm_officer
	name = "Communications Officer"
	limit = 0
	wages = PAY_IMPORTANT
	access_string = "Communications Officer"
	announce_on_join = TRUE
	wiki_link = "https://wiki.ss13.co/Communications_Officer"

	slot_ears = list(/obj/item/device/radio/headset/command/comm_officer)
	slot_eyes = list(/obj/item/clothing/glasses/sunglasses)
	slot_jump = list(/obj/item/clothing/under/rank/comm_officer)
	slot_card = /obj/item/card/id/command
	slot_foot = list(/obj/item/clothing/shoes/black)
	slot_back = list(/obj/item/storage/backpack/withO2)
	slot_belt = list(/obj/item/device/pda2/heads)
	slot_poc1 = list(/obj/item/pen/fancy)
	slot_head = list(/obj/item/clothing/head/sea_captain/comm_officer_hat)
	items_in_backpack = list(/obj/item/device/camera_viewer/security, /obj/item/device/audio_log, /obj/item/device/flash)

/datum/job/special/stowaway
	name = "Stowaway"
	limit = 0 // set in New()
	wages = 0
	trait_list = list("stowaway")
	add_to_manifest = FALSE
	low_priority_job = TRUE
	slot_card = null
	slot_head = list(\
	/obj/item/clothing/head/green = 1,
	/obj/item/clothing/head/red = 1,
	/obj/item/clothing/head/constructioncone = 1,
	/obj/item/clothing/head/helmet/welding = 1,
	/obj/item/clothing/head/helmet/hardhat = 1,
	/obj/item/clothing/head/serpico = 1,
	/obj/item/clothing/head/souschefhat = 1,
	/obj/item/clothing/head/maid = 1,
	/obj/item/clothing/head/cowboy = 1)

	slot_mask = list(\
	/obj/item/clothing/mask/gas = 1,
	/obj/item/clothing/mask/surgical = 1,
	/obj/item/clothing/mask/skull = 1,
	/obj/item/clothing/mask/bandana/white = 1)

	slot_ears = list(\
	/obj/item/device/radio/headset/civilian = 8,
	/obj/item/device/radio/headset/engineer = 1,
	/obj/item/device/radio/headset/research = 1,
	/obj/item/device/radio/headset/shipping = 1,
	/obj/item/device/radio/headset/medical = 1,
	/obj/item/device/radio/headset/miner = 1)

	slot_suit = list(\
	/obj/item/clothing/suit/wintercoat/engineering = 1,
	/obj/item/clothing/suit/wintercoat/robotics = 1,
	/obj/item/clothing/suit/labcoat = 1,
	/obj/item/clothing/suit/labcoat/robotics = 1,
	/obj/item/clothing/suit/wintercoat/research = 1)

	slot_jump = list(\
	/obj/item/clothing/under/color/grey = 1,
	/obj/item/clothing/under/rank/security/assistant = 1,
	/obj/item/clothing/under/rank/roboticist = 1,
	/obj/item/clothing/under/rank/engineer = 1,
	/obj/item/clothing/under/rank/orangeoveralls = 1,
	/obj/item/clothing/under/rank/orangeoveralls/yellow = 1,
	/obj/item/clothing/under/gimmick/maid = 1,
	/obj/item/clothing/under/rank/bartender = 1,
	/obj/item/clothing/under/misc/souschef = 1,
	/obj/item/clothing/under/rank/hydroponics = 1,
	/obj/item/clothing/under/rank/rancher = 1,
	/obj/item/clothing/under/rank/overalls = 1,
	/obj/item/clothing/under/rank/cargo = 1,
	/obj/item/clothing/under/rank/assistant = 10,
	/obj/item/clothing/under/rank/janitor = 1)

	slot_glov = list(\
	/obj/item/clothing/gloves/yellow/unsulated = 1,
	/obj/item/clothing/gloves/black = 1,
	/obj/item/clothing/gloves/fingerless = 1,
	/obj/item/clothing/gloves/long = 1)

	slot_foot = list(\
	/obj/item/clothing/shoes/brown = 6,
	/obj/item/clothing/shoes/red = 1,
	/obj/item/clothing/shoes/white = 1,
	/obj/item/clothing/shoes/black = 4,
	/obj/item/clothing/shoes/swat = 1,
	/obj/item/clothing/shoes/orange = 1,
	/obj/item/clothing/shoes/westboot/brown/rancher = 1,
	/obj/item/clothing/shoes/galoshes = 1)

	slot_back = list(\
	/obj/item/storage/backpack = 3,
	/obj/item/storage/backpack/anello = 1,
	/obj/item/storage/backpack/security = 1,
	/obj/item/storage/backpack/engineering = 1,
	/obj/item/storage/backpack/research = 1,
	/obj/item/storage/backpack/salvager = 1,
	/obj/item/storage/backpack/syndie/tactical = 0.2) //hehe

	slot_belt = list(\
	/obj/item/crowbar = 6,
	/obj/item/crowbar/red = 1,
	/obj/item/crowbar/yellow = 1,
	/obj/item/crowbar/blue = 1,
	/obj/item/crowbar/grey = 1,
	/obj/item/crowbar/orange = 1)

	slot_poc1 = list(\
	/obj/item/screwdriver = 1,
	/obj/item/screwdriver/yellow = 1,
	/obj/item/screwdriver/grey = 1,
	/obj/item/screwdriver/orange = 1)

	slot_poc2 = list(\
	/obj/item/scissors = 1,
	/obj/item/wirecutters = 1,
	/obj/item/wirecutters/yellow = 1,
	/obj/item/wirecutters/grey = 1,
	/obj/item/wirecutters/orange = 1,
	/obj/item/scissors/surgical_scissors = 1)

	items_in_backpack = list(\
	/obj/item/currency/buttcoin,
	/obj/item/currency/spacecash/fivehundred)

	New()
		. = ..()
		src.limit = rand(0,3)

// randomizd gimmick jobs

ABSTRACT_TYPE(/datum/job/special/random)
/datum/job/special/random
	limit = 0
	name = "Random"
	request_limit = 2
	request_cost = PAY_IMPORTANT*4

	New()
		..()
		if (src.alt_names.len)
			name = pick(src.alt_names)

/datum/job/special/random/radioshowhost
	name = "Radio Show Host"
	wages = PAY_TRADESMAN
	request_cost = PAY_DOCTORATE * 4
	access_string = "Radio Show Host"
#ifdef MAP_OVERRIDE_OSHAN
	special_spawn_location = null
	linkcolor = CIVILIAN_LINK_COLOR
	limit = 1
#elif defined(MAP_OVERRIDE_NADIR)
	special_spawn_location = null
	linkcolor = CIVILIAN_LINK_COLOR
	limit = 1
#else
	special_spawn_location = LANDMARK_RADIO_SHOW_HOST_SPAWN
#endif
	request_limit = 1 // limited workspace
	slot_ears = list(/obj/item/device/radio/headset/command/radio_show_host)
	slot_eyes = list(/obj/item/clothing/glasses/regular)
	slot_jump = list(/obj/item/clothing/under/shirt_pants)
	slot_card = /obj/item/card/id/civilian
	slot_foot = list(/obj/item/clothing/shoes/brown)
	slot_back = list(/obj/item/storage/backpack/satchel)
	slot_belt = list(/obj/item/device/pda2)
	slot_poc1 = list(/obj/item/reagent_containers/food/drinks/coffee)
	items_in_backpack = list(/obj/item/device/camera_viewer/security, /obj/item/device/audio_log, /obj/item/storage/box/record/radio/host)
	alt_names = list("Radio Show Host", "Talk Show Host")
	change_name_on_spawn = TRUE
	wiki_link = "https://wiki.ss13.co/Radio_Host"

/datum/job/special/random/souschef
	name = "Sous-Chef"
	request_cost = PAY_DOCTORATE * 4
	wages = PAY_UNTRAINED
	trait_list = list("training_chef")
	access_string = "Sous-Chef"
	requires_supervisor_job = "Chef"
	slot_belt = list(/obj/item/device/pda2/chef)
	slot_jump = list(/obj/item/clothing/under/misc/souschef)
	slot_foot = list(/obj/item/clothing/shoes/chef)
	slot_head = list(/obj/item/clothing/head/souschefhat)
	slot_suit = list(/obj/item/clothing/suit/apron)
	slot_ears = list(/obj/item/device/radio/headset/civilian)
	wiki_link = "https://wiki.ss13.co/Chef"

/datum/job/special/random/hall_monitor
	name = "Hall Monitor"
	wages = PAY_UNTRAINED
	access_string = "Hall Monitor"
	invalid_antagonist_roles = list(ROLE_HEAD_REVOLUTIONARY)
	badge = /obj/item/clothing/suit/security_badge/paper
	slot_belt = list(/obj/item/device/pda2)
	slot_jump = list(/obj/item/clothing/under/color/red)
	slot_foot = list(/obj/item/clothing/shoes/brown)
	slot_ears = list(/obj/item/device/radio/headset/civilian)
	slot_head = list(/obj/item/clothing/head/basecap/red)
	slot_poc1 = list(/obj/item/pen/pencil)
	slot_poc2 = list(/obj/item/device/radio/hall_monitor)
	items_in_backpack = list(/obj/item/instrument/whistle,/obj/item/device/ticket_writer/crust)

/datum/job/special/random/hollywood
	name = "Hollywood Actor"
	wages = PAY_UNTRAINED
	slot_foot = list(/obj/item/clothing/shoes/brown)
	slot_jump = list(/obj/item/clothing/under/suit/purple)
	special_spawn_location = LANDMARK_ACTOR_SPAWN

/datum/job/special/random/medical_specialist
	name = "Medical Specialist"
	linkcolor = MEDICAL_LINK_COLOR
	wages = PAY_IMPORTANT
	trait_list = list("training_medical", "training_partysurgeon")
	access_string = "Medical Specialist"
	slot_card = /obj/item/card/id/medical
	slot_belt = list(/obj/item/storage/belt/medical/prepared)
	slot_foot = list(/obj/item/clothing/shoes/brown)
	slot_back = list(/obj/item/storage/backpack/medic)
	slot_jump = list(/obj/item/clothing/under/scrub/maroon)
	slot_suit = list(/obj/item/clothing/suit/apron/surgeon)
	slot_head = list(/obj/item/clothing/head/bouffant)
	slot_ears = list(/obj/item/device/radio/headset/medical)
	slot_rhan = list(/obj/item/storage/firstaid/docbag)
	slot_poc1 = list(/obj/item/device/pda2/medical_director)
	alt_names = list(
		"Acupuncturist",
	  	"Anesthesiologist",
		"Cardiologist",
		"Dental Specialist",
		"Dermatologist",
		"Emergency Medicine Specialist",
		"Hematology Specialist",
		"Hepatology Specialist",
		"Immunology Specialist",
		"Internal Medicine Specialist",
		"Maxillofacial Specialist",
		"Medical Director's Assistant",
		"Neurological Specialist",
		"Ophthalmic Specialist",
		"Orthopaedic Specialist",
		"Otorhinolaryngology Specialist",
		"Plastic Surgeon",
		"Thoracic Specialist",
		"Vascular Specialist",
	)

/datum/job/special/random/vip
	name = "VIP"
	wages = PAY_EXECUTIVE
	access_string = "VIP"
	linkcolor = SECURITY_LINK_COLOR
	request_cost = PAY_EMBEZZLED * 4 // they're on the take
	slot_jump = list(/obj/item/clothing/under/suit/black)
	slot_head = list(/obj/item/clothing/head/that)
	slot_eyes = list(/obj/item/clothing/glasses/monocle)
	slot_foot = list(/obj/item/clothing/shoes/black)
	slot_lhan = list(/obj/item/storage/secure/sbriefcase)
	items_in_backpack = list(/obj/item/baton/cane)
	alt_names = list("Senator", "President", "Board Member", "Mayor", "Vice-President", "Governor")
	wiki_link = "https://wiki.ss13.co/VIP"

	special_setup(var/mob/living/carbon/human/M)
		..()

		var/obj/item/storage/secure/sbriefcase/B = M.find_type_in_hand(/obj/item/storage/secure/sbriefcase)
		if (B && istype(B))
			for (var/i = 1 to 2)
				B.storage.add_contents(new /obj/item/stamped_bullion(B))

		return

/datum/job/special/random/inspector
	name = "Inspector"
	wages = PAY_IMPORTANT
	linkcolor = NANOTRASEN_LINK_COLOR
	request_cost = PAY_EXECUTIVE * 4
	access_string = "Inspector"
	receives_miranda = TRUE
	invalid_antagonist_roles = list(ROLE_HEAD_REVOLUTIONARY)
	badge = /obj/item/clothing/suit/security_badge/nanotrasen
	slot_card = /obj/item/card/id/nanotrasen
	slot_back = list(/obj/item/storage/backpack)
	slot_belt = list(/obj/item/device/pda2/ntofficial)
	slot_jump = list(/obj/item/clothing/under/misc/lawyer/black) // so they can slam tables
	slot_foot = list(/obj/item/clothing/shoes/brown)
	slot_ears = list(/obj/item/device/radio/headset/command/inspector)
	slot_head = list(/obj/item/clothing/head/NTberet)
	slot_suit = list(/obj/item/clothing/suit/armor/NT)
	slot_eyes = list(/obj/item/clothing/glasses/regular)
	slot_lhan = list(/obj/item/storage/briefcase)
	slot_rhan = list(/obj/item/device/ticket_writer)
	items_in_backpack = list(/obj/item/device/flash)
	wiki_link = "https://wiki.ss13.co/Inspector"

	get_default_miranda()
		return "You have been found to be in breach of Nanotrasen corporate regulation [rand(1,100)][pick(uppercase_letters)]. You are allowed a grace period of 5 minutes to correct this infringement before you may be subjected to disciplinary action including but not limited to: strongly worded tickets, reduction in pay, and being buried in paperwork for the next [rand(10,20)] standard shifts."

	special_setup(var/mob/living/carbon/human/M)
		..()
		if (!M)
			return

		var/obj/item/storage/briefcase/B = M.find_type_in_hand(/obj/item/storage/briefcase)
		if (B && istype(B))
			B.storage.add_contents(new /obj/item/instrument/whistle(B))
			var/obj/item/clipboard/with_pen/inspector/clipboard = new /obj/item/clipboard/with_pen/inspector(B)
			B.storage.add_contents(clipboard)
			clipboard.set_owner(M)
		return

/datum/job/special/random/diplomat
	name = "Diplomat"
	wages = PAY_DUMBCLOWN
	access_string = "Diplomat"
	request_limit = 0 // you don't request them, they come to you
	slot_lhan = list(/obj/item/storage/briefcase)
	slot_jump = list(/obj/item/clothing/under/misc/lawyer)
	slot_foot = list(/obj/item/clothing/shoes/brown)
	alt_names = list("Diplomat", "Ambassador")
	invalid_antagonist_roles = list(ROLE_HEAD_REVOLUTIONARY)
	change_name_on_spawn = TRUE

	special_setup(var/mob/living/carbon/human/M)
		..()
		if (!M)
			return
		var/morph = pick(/datum/mutantrace/lizard,/datum/mutantrace/skeleton,/datum/mutantrace/ithillid,/datum/mutantrace/martian,/datum/mutantrace/amphibian,/datum/mutantrace/blob,/datum/mutantrace/cow)
		M.set_mutantrace(morph)
		if (istype(M.mutantrace, /datum/mutantrace/martian) || istype(M.mutantrace, /datum/mutantrace/blob))
			M.equip_if_possible(new /obj/item/device/speech_pro(src), SLOT_IN_BACKPACK)
		else
			if (M.l_store)
				M.stow_in_available(M.l_store)
			M.equip_if_possible(new /obj/item/device/speech_pro(src), SLOT_L_STORE)

/datum/job/special/random/testsubject
	name = "Test Subject"
	wages = PAY_DUMBCLOWN
	slot_jump = list(/obj/item/clothing/under/shorts)
	slot_mask = list(/obj/item/clothing/mask/monkey_translator)
	change_name_on_spawn = TRUE
	starting_mutantrace = /datum/mutantrace/monkey
	wiki_link = "https://wiki.ss13.co/Monkey"

/datum/job/special/random/union
	name = "Union Rep"
	wages = PAY_TRADESMAN
	slot_jump = list(/obj/item/clothing/under/misc/lawyer)
	slot_lhan = list(/obj/item/storage/briefcase)
	slot_foot = list(/obj/item/clothing/shoes/brown)
	alt_names = list("Assistants Union Rep", "Cargo Union Rep", "Catering Union Rep", "Union Rep", "Security Union Rep", "Doctors Union Rep", "Engineers Union Rep", "Miners Union Rep")
	// missing wiki link, parent fallback to https://wiki.ss13.co/Jobs#Gimmick_Jobs

	special_setup(var/mob/living/carbon/human/M)
		..()
		if (!M)
			return

		var/obj/item/storage/briefcase/B = M.find_type_in_hand(/obj/item/storage/briefcase)
		if (B && istype(B))
			B.storage.add_contents(new /obj/item/clipboard/with_pen(B))

		return

/datum/job/special/random/salesman
	name = "Salesman"
	wages = PAY_TRADESMAN
	slot_suit = list(/obj/item/clothing/suit/merchant)
	slot_jump = list(/obj/item/clothing/under/gimmick/merchant)
	slot_head = list(/obj/item/clothing/head/merchant_hat)
	slot_lhan = list(/obj/item/storage/briefcase)
	slot_foot = list(/obj/item/clothing/shoes/brown)
	alt_names = list("Salesman", "Merchant")
	change_name_on_spawn = TRUE
	wiki_link = "https://wiki.ss13.co/Salesman"

	special_setup(var/mob/living/carbon/human/M)
		..()
		if (!M)
			return

		if(prob(33))
			var/morph = pick(/datum/mutantrace/lizard,/datum/mutantrace/skeleton,/datum/mutantrace/ithillid,/datum/mutantrace/martian,/datum/mutantrace/amphibian)
			M.set_mutantrace(morph)

		var/obj/item/storage/briefcase/B = M.find_type_in_hand(/obj/item/storage/briefcase)
		if (B && istype(B))
			for (var/i = 1 to 2)
				B.storage.add_contents(new /obj/item/stamped_bullion(B))

		return

/datum/job/special/random/coach
	name = "Coach"
	wages = PAY_UNTRAINED
	slot_jump = list(/obj/item/clothing/under/jersey)
	slot_suit = list(/obj/item/clothing/suit/armor/vest/macho)
	slot_eyes = list(/obj/item/clothing/glasses/sunglasses)
	slot_foot = list(/obj/item/clothing/shoes/white)
	slot_poc1 = list(/obj/item/instrument/whistle)
	slot_glov = list(/obj/item/clothing/gloves/boxing)
	items_in_backpack = list(/obj/item/football,/obj/item/football,/obj/item/basketball,/obj/item/basketball)
	// missing wiki link, parent fallback to https://wiki.ss13.co/Jobs#Gimmick_Jobs

/datum/job/special/random/journalist
	name = "Journalist"
	wages = PAY_UNTRAINED
	slot_jump = list(/obj/item/clothing/under/suit/red)
	slot_head = list(/obj/item/clothing/head/fedora)
	slot_lhan = list(/obj/item/storage/briefcase)
	slot_poc1 = list(/obj/item/camera)
	slot_foot = list(/obj/item/clothing/shoes/brown)
	items_in_backpack = list(/obj/item/camera_film/large)
	special_spawn_location = LANDMARK_JOURNALIST_SPAWN
	// missing wiki link, parent fallback to https://wiki.ss13.co/Jobs#Gimmick_Jobs

	special_setup(var/mob/living/carbon/human/M)
		..()
		if (!M)
			return

		var/obj/item/storage/briefcase/B = M.find_type_in_hand(/obj/item/storage/briefcase)
		if (B && istype(B))
			B.storage.add_contents(new /obj/item/device/camera_viewer/public(B))
			B.storage.add_contents(new /obj/item/clothing/head/helmet/camera(B))
			B.storage.add_contents(new /obj/item/device/audio_log(B))
			B.storage.add_contents(new /obj/item/clipboard/with_pen(B))

		return

/datum/job/special/random/beekeeper
	name = "Apiculturist"
	wages = PAY_TRADESMAN
	access_string = "Apiculturist"
	slot_jump = list(/obj/item/clothing/under/rank/beekeeper)
	slot_suit = list(/obj/item/clothing/suit/hazard/beekeeper)
	slot_head = list(/obj/item/clothing/head/bio_hood/beekeeper)
	slot_poc1 = list(/obj/item/reagent_containers/food/snacks/beefood)
	slot_poc2 = list(/obj/item/paper/book/from_file/bee_book)
	slot_foot = list(/obj/item/clothing/shoes/black)
	slot_belt = list(/obj/item/device/pda2/botanist)
	slot_foot = list(/obj/item/clothing/shoes/brown)
	slot_glov = list(/obj/item/clothing/gloves/black)
	slot_ears = list(/obj/item/device/radio/headset/civilian)
	items_in_backpack = list(/obj/item/bee_egg_carton, /obj/item/bee_egg_carton, /obj/item/bee_egg_carton, /obj/item/reagent_containers/food/snacks/beefood, /obj/item/reagent_containers/food/snacks/beefood)
	alt_names = list("Apiculturist", "Apiarist")
	// missing wiki link, parent fallback to https://wiki.ss13.co/Jobs#Gimmick_Jobs

	faction = list(FACTION_BOTANY)

	special_setup(var/mob/living/carbon/human/M)
		..()
		if (!M)
			return
		if (prob(15))
			var/obj/critter/domestic_bee/bee = new(get_turf(M))
			bee.beeMom = M
			bee.beeMomCkey = M.ckey
			bee.name = pick_string("bee_names.txt", "beename")
			bee.name = replacetext(bee.name, "larva", "bee")

		M.bioHolder.AddEffect("bee", magical=1) //They're one with the bees!


/datum/job/special/random/angler
	name = "Angler"
	wages = PAY_TRADESMAN
	access_string = "Rancher"
	slot_jump = list(/obj/item/clothing/under/rank/angler)
	slot_head = list(/obj/item/clothing/head/black)
	slot_foot = list(/obj/item/clothing/shoes/galoshes/waders)
	slot_glov = list(/obj/item/clothing/gloves/black)
	slot_ears = list(/obj/item/device/radio/headset/civilian)
	items_in_backpack = list(/obj/item/fishing_rod/basic)


/datum/job/special/random/pharmacist
	name = "Pharmacist"
	wages = PAY_DOCTORATE
	linkcolor = MEDICAL_LINK_COLOR
	request_limit = 1 // limited workspace
	trait_list = list("training_medical")
	access_string = "Pharmacist"
	slot_card = /obj/item/card/id/medical
	slot_belt = list(/obj/item/device/pda2/medical)
	slot_foot = list(/obj/item/clothing/shoes/brown)
	slot_jump = list(/obj/item/clothing/under/shirt_pants)
	slot_suit = list(/obj/item/clothing/suit/labcoat)
	slot_ears = list(/obj/item/device/radio/headset/medical)
	items_in_backpack = list(/obj/item/storage/box/beakerbox, /obj/item/storage/pill_bottle/cyberpunk)

/datum/job/special/random/psychiatrist
	name = "Psychiatrist"
	linkcolor = MEDICAL_LINK_COLOR
	wages = PAY_DOCTORATE
	request_limit = 1 // limited workspace
	access_string = "Psychiatrist"
	slot_eyes = list(/obj/item/clothing/glasses/regular)
	slot_card = /obj/item/card/id/medical
	slot_belt = list(/obj/item/device/pda2/medical)
	slot_foot = list(/obj/item/clothing/shoes/brown)
	slot_jump = list(/obj/item/clothing/under/shirt_pants)
	slot_suit = list(/obj/item/clothing/suit/labcoat)
	slot_ears = list(/obj/item/device/radio/headset/medical)
	slot_poc1 = list(/obj/item/reagent_containers/food/drinks/tea)
	slot_poc2 = list(/obj/item/reagent_containers/food/drinks/bottle/gin)
	items_in_backpack = list(/obj/item/luggable_computer/personal, /obj/item/clipboard/with_pen, /obj/item/paper_bin, /obj/item/stamp, /obj/item/storage/firstaid/mental)
	alt_names = list("Psychiatrist", "Psychologist", "Psychotherapist", "Therapist", "Counselor", "Life Coach") // All with slightly different connotations

/datum/job/special/random/artist
	name = "Artist"
	wages = PAY_UNTRAINED
	slot_foot = list(/obj/item/clothing/shoes/brown)
	slot_jump = list(/obj/item/clothing/under/misc/casualjeansblue)
	slot_head = list(/obj/item/clothing/head/mime_beret)
	slot_ears = list(/obj/item/device/radio/headset/civilian)
	slot_poc1 = list(/obj/item/currency/spacecash/twenty)
	slot_poc2 = list(/obj/item/pen/pencil)
	slot_lhan = list(/obj/item/storage/toolbox/artistic)
	items_in_backpack = list(/obj/item/canvas, /obj/item/canvas, /obj/item/storage/box/crayon/basic ,/obj/item/paint_can/random)
	// missing wiki link, parent fallback to https://wiki.ss13.co/Jobs#Gimmick_Jobs

/datum/job/special/random/foodcritic
	name = "Food Critic"
	wages = PAY_UNTRAINED
	slot_foot = list(/obj/item/clothing/shoes/brown)
	slot_jump = list(/obj/item/clothing/under/shirt_pants_br)
	slot_ears = list(/obj/item/device/radio/headset/civilian)
	slot_poc2 = list(/obj/item/paper)
	slot_lhan = list(/obj/item/clipboard/with_pen)
	items_in_backpack = list(/obj/item/item_box/postit)
	// missing wiki link, parent fallback to https://wiki.ss13.co/Jobs#Gimmick_Jobs

/datum/job/special/random/pestcontrol
	name = "Pest Control Specialist"
	wages = PAY_UNTRAINED
	slot_foot = list(/obj/item/clothing/shoes/brown)
	slot_jump = list(/obj/item/clothing/under/gimmick/safari)
	slot_head = list(/obj/item/clothing/head/safari)
	slot_ears = list(/obj/item/device/radio/headset/civilian)
	slot_lhan = list(/obj/item/pet_carrier)
	items_in_backpack = list(/obj/item/storage/box/mousetraps)
	// missing wiki link, parent fallback to https://wiki.ss13.co/Jobs#Gimmick_Jobs

/datum/job/special/random/vehiclemechanic
	name = "Vehicle Mechanic" // fallback name, gets changed later
	#ifdef UNDERWATER_MAP
	name = "Submarine Mechanic"
	#else
	name = "Pod Mechanic"
	#endif
	wages = PAY_TRADESMAN
	trait_list = list("training_engineer")
	slot_foot = list(/obj/item/clothing/shoes/brown)
	slot_jump = list(/obj/item/clothing/under/rank/mechanic)
	slot_head = list(/obj/item/clothing/head/helmet/hardhat)
	slot_ears = list(/obj/item/device/radio/headset/civilian)
	slot_lhan = list(/obj/item/storage/toolbox/mechanical)
	#ifdef UNDERWATER_MAP
	items_in_backpack = list(/obj/item/preassembled_frame_box/sub, /obj/item/podarmor/armor_light, /obj/item/clothing/head/helmet/welding)
	#else
	items_in_backpack = list(/obj/item/preassembled_frame_box/putt, /obj/item/podarmor/armor_light, /obj/item/clothing/head/helmet/welding)
	#endif
	// missing wiki link, parent fallback to https://wiki.ss13.co/Jobs#Gimmick_Jobs

/datum/job/special/random/phonemerchant
	name = "Phone Merchant"
	wages = PAY_TRADESMAN
	slot_foot = list(/obj/item/clothing/shoes/brown)
	slot_jump = list(/obj/item/clothing/under/gimmick/merchant)
	slot_ears = list(/obj/item/device/radio/headset/civilian)
	slot_poc1 = list(/obj/item/electronics/soldering)
	items_in_backpack = list(/obj/item/electronics/frame/phone, /obj/item/electronics/frame/phone, /obj/item/electronics/frame/phone, /obj/item/electronics/frame/phone)
	// missing wiki link, parent fallback to https://wiki.ss13.co/Jobs#Gimmick_Jobs

// god help us
// hello it's me god, adding an RP define here
#ifndef RP_MODE
/datum/job/special/random/influencer
	name = "Influencer"
	wages = PAY_UNTRAINED
	change_name_on_spawn = TRUE
	slot_foot = list(/obj/item/clothing/shoes/dress_shoes)
	slot_jump = list(/obj/item/clothing/under/misc/casualjeanspurp)
	slot_head = list(/obj/item/clothing/head/basecap/purple)
	slot_ears = list(/obj/item/device/radio/headset/civilian)
	slot_poc1 = list(/obj/item/device/audio_log)
	slot_poc2 = list(/obj/item/camera)
	items_in_backpack = list(/obj/item/storage/box/random_colas, /obj/item/clothing/head/helmet/camera, /obj/item/device/camera_viewer/public)
	special_spawn_location = LANDMARK_INFLUENCER_SPAWN
	// missing wiki link, parent fallback to https://wiki.ss13.co/Jobs#Gimmick_Jobs

#endif

/*
 * Halloween jobs
 */
ABSTRACT_TYPE(/datum/job/special/halloween)
/datum/job/special/halloween
	linkcolor = "#FF7300"
	wiki_link = "https://wiki.ss13.co/Jobs#Spooktober_Jobs"
#ifdef HALLOWEEN
	limit = 1
#else
	limit = 0
#endif

/datum/job/special/halloween/blue_clown
	name = "Blue Clown"
	wages = PAY_DUMBCLOWN
	trait_list = list("training_clown")
	access_string = "Clown"
	change_name_on_spawn = TRUE
	slot_back = list()
	slot_mask = list(/obj/item/clothing/mask/clown_hat/blue)
	slot_ears = list(/obj/item/device/radio/headset/clown)
	slot_jump = list(/obj/item/clothing/under/misc/clown/blue)
	slot_card = /obj/item/card/id/clown
	slot_foot = list(/obj/item/clothing/shoes/clown_shoes/blue)
	slot_belt = list(/obj/item/storage/fanny/funny)
	slot_poc1 = list(/obj/item/bananapeel)
	slot_poc2 = list(/obj/item/device/pda2/clown)
	slot_lhan = list(/obj/item/instrument/bikehorn)

	faction = list(FACTION_CLOWN)

	special_setup(var/mob/living/carbon/human/M)
		..()
		M.bioHolder.AddEffect("regenerator", magical=1)

/datum/job/special/halloween/candy_salesman
	name = "Candy Salesman"
	wages = PAY_UNTRAINED
	access_string = "Salesman"
	slot_head = list(/obj/item/clothing/head/that/purple)
	slot_ears = list(/obj/item/device/radio/headset)
	slot_jump = list(/obj/item/clothing/under/suit/purple)
	slot_foot = list(/obj/item/clothing/shoes/brown)
	slot_belt = list(/obj/item/device/pda2)
	slot_poc1 = list(/obj/item/storage/pill_bottle/cyberpunk)
	slot_poc2 = list(/obj/item/storage/pill_bottle/catdrugs)
	items_in_backpack = list(/obj/item/storage/goodybag, /obj/item/kitchen/everyflavor_box, /obj/item/item_box/heartcandy, /obj/item/kitchen/peach_rings)

/datum/job/special/halloween/pumpkin_head
	name = "Pumpkin Head"
	wages = PAY_UNTRAINED
	access_string = "Staff Assistant"
	change_name_on_spawn = TRUE
	slot_head = list(/obj/item/clothing/head/pumpkin)
	slot_ears = list(/obj/item/device/radio/headset)
	slot_jump = list(/obj/item/clothing/under/color/orange)
	slot_foot = list(/obj/item/clothing/shoes/orange)
	slot_belt = list(/obj/item/device/pda2)
	slot_poc1 = list(/obj/item/reagent_containers/food/snacks/candy/candy_corn)
	slot_poc2 = list(/obj/item/item_box/assorted/stickers/stickers_limited)

	special_setup(var/mob/living/carbon/human/M)
		..()
		if (!M)
			return
		M.bioHolder.AddEffect("quiet_voice", magical=1)

/datum/job/special/halloween/wanna_bee
	name = "WannaBEE"
	wages = PAY_UNTRAINED
	access_string = "Botanist"
	slot_head = list(/obj/item/clothing/head/headband/bee)
	slot_suit = list(/obj/item/clothing/suit/bee)
	slot_ears = list(/obj/item/device/radio/headset)
	slot_jump = list(/obj/item/clothing/under/rank/beekeeper)
	slot_foot = list(/obj/item/clothing/shoes/black)
	slot_belt = list(/obj/item/device/pda2)
	slot_poc1 = list(/obj/item/reagent_containers/food/snacks/ingredient/egg/bee)
	slot_poc2 = list(/obj/item/reagent_containers/food/snacks/ingredient/egg/bee/buddy)
	items_in_backpack = list(/obj/item/reagent_containers/food/snacks/b_cupcake, /obj/item/reagent_containers/food/snacks/ingredient/royal_jelly)

	special_setup(var/mob/living/carbon/human/M)
		..()
		if (!M)
			return
		M.bioHolder.AddEffect("drunk_bee", magical=1)

/datum/job/special/halloween/dracula
	name = "Discount Dracula"
	wages = PAY_UNTRAINED
	access_string = "Staff Assistant"
	change_name_on_spawn = TRUE
	slot_head = list(/obj/item/clothing/head/that)
	slot_suit = list(/obj/item/clothing/suit/gimmick/vampire)
	slot_ears = list(/obj/item/device/radio/headset)
	slot_jump = list(/obj/item/clothing/under/gimmick/vampire)
	slot_foot = list(/obj/item/clothing/shoes/swat)
	slot_belt = list(/obj/item/device/pda2)
	slot_poc1 = list(/obj/item/reagent_containers/syringe)
	slot_poc2 = list(/obj/item/reagent_containers/glass/beaker/large)
	slot_back = list(/obj/item/storage/backpack/satchel)

	special_setup(var/mob/living/carbon/human/M)
		..()
		if (!M)
			return
		M.bioHolder.AddEffect("aura", magical=1)
		M.bioHolder.AddEffect("cloak_of_darkness", magical=1)

/datum/job/special/halloween/werewolf
	name = "Discount Werewolf"
	wages = PAY_UNTRAINED
	access_string = "Staff Assistant"
	change_name_on_spawn = TRUE
	slot_head = list(/obj/item/clothing/head/werewolf)
	slot_jump = list(/obj/item/clothing/under/shorts)
	slot_suit = list(/obj/item/clothing/suit/gimmick/werewolf)
	slot_ears = list(/obj/item/device/radio/headset)
	slot_belt = list(/obj/item/device/pda2)

	special_setup(var/mob/living/carbon/human/M)
		..()
		if (!M)
			return
		M.bioHolder.AddEffect("jumpy", magical=1)

/datum/job/special/halloween/mummy
	name = "Discount Mummy"
	wages = PAY_UNTRAINED
	access_string = "Staff Assistant"
	change_name_on_spawn = TRUE
	slot_mask = list(/obj/item/clothing/mask/mummy)
	slot_jump = list(/obj/item/clothing/under/gimmick/mummy)
	slot_ears = list(/obj/item/device/radio/headset)
	slot_belt = list(/obj/item/device/pda2)

	special_setup(var/mob/living/carbon/human/M)
		..()
		if (!M)
			return
		M.bioHolder.AddEffect("aura", magical=1)
		M.bioHolder.AddEffect("midas", magical=1)

/datum/job/special/halloween/hotdog
	name = "Hot Dog"
	wages = PAY_UNTRAINED
	access_string = "Staff Assistant"
	change_name_on_spawn = TRUE
	slot_jump = list(/obj/item/clothing/under/shorts)
	slot_suit = list(/obj/item/clothing/suit/gimmick/hotdog)
	slot_foot = list(/obj/item/clothing/shoes/black)
	slot_ears = list(/obj/item/device/radio/headset)
	slot_belt = list(/obj/item/device/pda2)
	slot_back = list(/obj/item/storage/backpack/satchel/randoseru)
	slot_poc1 = list(/obj/item/shaker/ketchup)
	slot_poc2 = list(/obj/item/shaker/mustard)

/datum/job/special/halloween/godzilla
	name = "Discount Godzilla"
	wages = PAY_UNTRAINED
	access_string = "Staff Assistant"
	change_name_on_spawn = TRUE
	slot_head = list(/obj/item/clothing/head/biglizard)
	slot_ears = list(/obj/item/device/radio/headset)
	slot_jump = list(/obj/item/clothing/under/color/green)
	slot_suit = list(/obj/item/clothing/suit/gimmick/dinosaur)
	slot_belt = list(/obj/item/device/pda2)
	slot_poc1 = list(/obj/item/toy/figure)
	slot_poc2 = list(/obj/item/toy/figure)

	special_setup(var/mob/living/carbon/human/M)
		..()
		if (!M)
			return
		M.bioHolder.AddEffect("lizard", magical=1)
		M.bioHolder.AddEffect("loud_voice", magical=1)

/datum/job/special/halloween/macho
	name = "Discount Macho Man"
	wages = PAY_UNTRAINED
	access_string = "Staff Assistant"
	change_name_on_spawn = TRUE
	slot_head = list(/obj/item/clothing/head/helmet/macho)
	slot_eyes = list(/obj/item/clothing/glasses/macho)
	slot_ears = list(/obj/item/device/radio/headset)
	slot_jump = list(/obj/item/clothing/under/gimmick/macho)
	slot_foot = list(/obj/item/clothing/shoes/macho)
	slot_belt = list(/obj/item/device/pda2)
	slot_poc1 = list(/obj/item/reagent_containers/food/snacks/ingredient/sugar)
	slot_poc2 = list(/obj/item/sticker/ribbon/first_place)

	special_setup(var/mob/living/carbon/human/M)
		..()
		if (!M)
			return
		M.bioHolder.AddEffect("accent_chav", magical=1)

/datum/job/special/halloween/ghost
	name = "Ghost"
	wages = PAY_UNTRAINED
	change_name_on_spawn = TRUE
	slot_eyes = list(/obj/item/clothing/glasses/regular/ecto/goggles)
	slot_suit = list(/obj/item/clothing/suit/bedsheet)
	slot_ears = list(/obj/item/device/radio/headset)

	special_setup(var/mob/living/carbon/human/M)
		..()
		if (!M)
			return
		M.bioHolder.AddEffect("chameleon", magical=1)

/datum/job/special/halloween/ghost_buster
	name = "Ghost Buster"
	wages = PAY_UNTRAINED
	request_limit = 1
	request_cost = PAY_EXECUTIVE * 4
	access_string = "Staff Assistant"
	change_name_on_spawn = TRUE
	slot_ears = list(/obj/item/device/radio/headset/ghost_buster)
	slot_eyes = list(/obj/item/clothing/glasses/regular/ecto/goggles)
	slot_jump = list(/obj/item/clothing/under/shirt_pants)
	slot_foot = list(/obj/item/clothing/shoes/brown)
	slot_back = list(/obj/item/storage/backpack/satchel)
	slot_belt = list(/obj/item/device/pda2)
	slot_poc1 = list(/obj/item/magnifying_glass)
	slot_poc2 = list(/obj/item/shaker/salt)
	items_in_backpack = list(/obj/item/device/camera_viewer/security, /obj/item/device/audio_log, /obj/item/gun/energy/ghost)
	alt_names = list("Paranormal Activities Investigator", "Spooks Specialist")
	change_name_on_spawn = TRUE

/datum/job/special/halloween/angel
	name = "Angel"
	wages = PAY_UNTRAINED
	trait_list = list("training_chaplain")
	access_string = "Chaplain"
	change_name_on_spawn = TRUE
	slot_head = list(/obj/item/clothing/head/laurels/gold)
	slot_ears = list(/obj/item/device/radio/headset)
	slot_jump = list(/obj/item/clothing/under/gimmick/birdman)
	slot_foot = list(/obj/item/clothing/shoes/sandal)
	slot_belt = list(/obj/item/device/pda2)
	slot_poc1 = list(/obj/item/coin)
	slot_poc2 = list(/obj/item/plant/herb/cannabis/white/spawnable)

	special_setup(var/mob/living/carbon/human/M)
		..()
		if (!M)
			return
		M.bioHolder.AddEffect("shiny", magical=1)
		M.bioHolder.AddEffect("healing_touch", magical=1)

/datum/job/special/halloween/vendor
	name = "Costume Vendor"
	wages = PAY_TRADESMAN
	change_name_on_spawn = TRUE
	slot_jump = list(/obj/item/clothing/under/gimmick/trashsinglet)
	slot_foot = list(/obj/item/clothing/shoes/sandal)
	slot_belt = list(/obj/item/device/pda2)
	slot_back = list(/obj/item/storage/backpack/satchel/anello)
	items_in_backpack = list(/obj/item/storage/box/costume/abomination,
	/obj/item/storage/box/costume/werewolf/odd,
	/obj/item/storage/box/costume/monkey,
	/obj/item/storage/box/costume/eighties,
	/obj/item/clothing/head/zombie)

/datum/job/special/halloween/devil
	name = "Devil"
	wages = PAY_UNTRAINED
	access_string = "Chaplain"
	limit = 0
	change_name_on_spawn = TRUE
	slot_head = list(/obj/item/clothing/head/headband/devil)
	slot_mask = list(/obj/item/clothing/mask/moustache/safe)
	slot_ears = list(/obj/item/device/radio/headset)
	slot_jump = list(/obj/item/clothing/under/misc/lawyer/red/demonic)
	slot_foot = list(/obj/item/clothing/shoes/sandal)
	slot_belt = list(/obj/item/device/pda2)
	slot_poc1 = list(/obj/item/pen/fancy/satan)
	slot_poc2 = list(/obj/item/contract/juggle)

	special_setup(var/mob/living/carbon/human/M)
		..()
		if (!M)
			return
		M.bioHolder.AddEffect("hell_fire", magical=1)

/datum/job/special/halloween/superhero
	name = "Discount Vigilante Superhero"
	wages = PAY_UNTRAINED
	trait_list = list("training_security")
	access_string = "Staff Assistant"
	limit = 0
	change_name_on_spawn = TRUE
	can_roll_antag = FALSE
	receives_miranda = TRUE
	slot_ears = list(/obj/item/device/radio/headset/security)
	slot_eyes = list(/obj/item/clothing/glasses/sunglasses/sechud/superhero)
	slot_glov = list(/obj/item/clothing/gloves/latex/blue)
	slot_jump = list(/obj/item/clothing/under/gimmick/superhero)
	slot_foot = list(/obj/item/clothing/shoes/tourist)
	slot_belt = list(/obj/item/storage/belt/utility/superhero)
	slot_back = list()
	slot_poc2 = list(/obj/item/device/pda2)

	special_setup(var/mob/living/carbon/human/M)
		..()
		if(prob(60))
			var/aggressive = pick("eyebeams","cryokinesis")
			var/defensive = pick("fire_resist","cold_resist","rad_resist","breathless") // no thermal resist, gotta have some sort of comic book weakness
			var/datum/bioEffect/power/be = M.bioHolder.AddEffect(aggressive, do_stability=0)
			if(aggressive == "eyebeams")
				var/datum/bioEffect/power/eyebeams/eb = be
				eb.stun_mode = 1
				eb.altered = 1
			else
				be.power = 1
				be.altered = 1
			be = M.bioHolder.AddEffect(defensive, do_stability=0)
		else
			var/datum/bioEffect/power/shoot_limb/sl = M.bioHolder.AddEffect("shoot_limb", do_stability=0)
			sl.safety = 1
			sl.altered = 1
			sl.cooldown = 300
			sl.stun_mode = 1
			var/datum/bioEffect/regenerator/r = M.bioHolder.AddEffect("regenerator", do_stability=0)
			r.regrow_prob = 10
		var/datum/bioEffect/power/be = M.bioHolder.AddEffect("adrenaline", do_stability=0)
		be.safety = 1
		be.altered = 1

	get_default_miranda()
		return "Evildoer! You have been apprehended by a hero of space justice!"

/datum/job/special/halloween/pickle
	name = "Pickle"
	wages = PAY_DUMBCLOWN
	access_string = "Staff Assistant"
	change_name_on_spawn = TRUE
	slot_ears = list(/obj/item/device/radio/headset)
	slot_suit = list(/obj/item/clothing/suit/gimmick/pickle)
	slot_jump = list(/obj/item/clothing/under/color/green)
	slot_belt = list(/obj/item/device/pda2)
	slot_foot = list(/obj/item/clothing/shoes/black)

	special_setup(var/mob/living/carbon/human/M)
		..()
		if (!M)
			return
		var/obj/item/trinket = M.trinket?.deref()
		trinket?.setMaterial(getMaterial("pickle"))
		for (var/i in 1 to 3)
			var/type = pick(trinket_safelist)
			var/obj/item/pickle = new type(M.loc)
			pickle.setMaterial(getMaterial("pickle"))
			M.equip_if_possible(pickle, SLOT_IN_BACKPACK)
		M.bioHolder.RemoveEffect("midas") //just in case mildly mutated has given us midas I guess?
		M.bioHolder.AddEffect("pickle", magical=TRUE)
		M.blood_id = "juice_pickle"

/datum/job/special/halloween/cowboy
	name = "Space Cowboy"
	linkcolor = CIVILIAN_LINK_COLOR
	wages = PAY_UNTRAINED
	starting_mutantrace = /datum/mutantrace/cow
	badge = /obj/item/clothing/suit/security_badge
	change_name_on_spawn = TRUE
	access_string = "Rancher" // it didnt actually have a unique string
	slot_jump = list(/obj/item/clothing/under/rank/det)
	slot_suit = list(/obj/item/clothing/suit/poncho)
	slot_belt = list(/obj/item/storage/belt/rancher/cowboy)
	slot_head = list(/obj/item/clothing/head/cowboy)
	slot_mask = list(/obj/item/clothing/mask/cigarette/random)
	slot_eyes = list(/obj/item/clothing/glasses/sunglasses)
	slot_foot = list(/obj/item/clothing/shoes/cowboy)
	slot_card = /obj/item/card/id/civilian
	slot_poc1 = list(/obj/item/device/pda2/botanist)
	slot_poc2 = list(/obj/item/device/light/zippo/gold)
	slot_back = list(/obj/item/storage/backpack/satchel/brown)

/datum/job/special/halloween/wizard
	name = "Discount Wizard"
	wages = PAY_UNTRAINED
	change_name_on_spawn = TRUE
	access_string = "Staff Assistant"
	slot_jump = list(/obj/item/clothing/under/shorts/black)
	slot_suit = list(/obj/item/clothing/suit/bathrobe)
	slot_head = list(/obj/item/clothing/head/apprentice)
	slot_foot = list(/obj/item/clothing/shoes/fuzzy)
	items_in_backpack = list(/obj/item/mop)

	special_setup(var/mob/living/carbon/human/M)
		..()
		if (!M)
			return
		M.bioHolder.AddEffect("melt", magical=1)

/datum/job/special/halloween/spy
	name = "Super Spy"
	wages = PAY_UNTRAINED
	access_string = "Staff Assistant"
	slot_jump = list(/obj/item/clothing/under/suit/black)
	slot_eyes = list(/obj/item/clothing/glasses/eyepatch)
	slot_suit = list(/obj/item/clothing/suit/armor/sneaking_suit/costume)
	slot_foot = list(/obj/item/clothing/shoes/swat)
	items_in_backpack = list(/obj/item/clothing/suit/cardboard_box )

	special_setup(var/mob/living/carbon/human/M)
		..()
		if (!M)
			return
		M.bioHolder.AddEffect("chameleon", magical=1)

ABSTRACT_TYPE(/datum/job/special/halloween/critter)
/datum/job/special/halloween/critter
	wages = PAY_DUMBCLOWN
	trusted_only = TRUE
	can_roll_antag = FALSE
	slot_ears = list()
	slot_card = null
	slot_back = list()

	special_setup(var/mob/living/carbon/human/M)
		if (!M)
			return

		..()
		// Deactivate any gene that was activated by Mildly mutated trait
		M.bioHolder.DeactivateAllPoolEffects()

/datum/job/special/halloween/critter/plush
	name = "Plush Toy"
	trusted_only = FALSE
#ifdef HALLOWEEN
	limit = 2
#endif
	special_setup(var/mob/living/carbon/human/M)
		..()
		if (!M)
			return
		M.critterize(/mob/living/critter/small_animal/plush/cryptid)

/datum/job/special/halloween/critter/remy
	name = "Remy"

	special_setup(var/mob/living/carbon/human/M)
		..()
		if (!M)
			return
		var/mob/living/critter/C = M.critterize(/mob/living/critter/small_animal/mouse/remy)
		C.flags = null

/datum/job/special/halloween/critter/bumblespider
	name = "Bumblespider"

	special_setup(var/mob/living/carbon/human/M)
		..()
		if (!M)
			return
		var/mob/living/critter/C = M.critterize(/mob/living/critter/spider/nice)
		C.flags = null

/datum/job/special/halloween/critter/crow
	name = "Crow"

	special_setup(var/mob/living/carbon/human/M)
		..()
		if (!M)
			return
		var/mob/living/critter/C = M.critterize(/mob/living/critter/small_animal/bird/crow)
		C.flags = null

// Spooky time is over. Time for crime.

ABSTRACT_TYPE(/datum/job/special/syndicate)
/datum/job/special/syndicate
	linkcolor = SYNDICATE_LINK_COLOR
	limit = 0
	wages = 0
	name = "YOU SHOULDN'T SEE ME OPERATIVE"
	access_string = "Syndicate Operative" // "All Access" + Syndie Shuttle
	radio_announcement = FALSE
	add_to_manifest = FALSE
	//Always a generic antagonist, don't allow normal antag roles.
	can_roll_antag = FALSE

	slot_back = list(/obj/item/storage/backpack/syndie)
	slot_jump = list(/obj/item/clothing/under/misc/syndicate)
	slot_foot = list(/obj/item/clothing/shoes/swat/noslip)
	slot_glov = list(/obj/item/clothing/gloves/swat/syndicate)
	slot_eyes = list(/obj/item/clothing/glasses/sunglasses)
	slot_mask = list(/obj/item/clothing/mask/gas/swat/syndicate)
	slot_ears = list(/obj/item/device/radio/headset/syndicate) //needs their own secret channel
	slot_belt = null //No PDA
	slot_card = /obj/item/card/id/syndicate //Job setup registers an owner, so custom agent ID setup won't be available.
	slot_poc2 = list(/obj/item/tank/pocket/extended/oxygen)
	faction = list(FACTION_SYNDICATE)

	special_setup(var/mob/living/carbon/human/M)
		..()
		M.mind?.add_generic_antagonist(ROLE_SYNDICATE_AGENT, src.name, source = ANTAGONIST_SOURCE_ADMIN)
		SPAWN(0) //Let the ID actually spawn
			var/obj/item/card/id/ID = M.get_id()
			if(istype(ID))
				ID.icon_state = "id_syndie" //Syndie ID normally starts with basic sprite

/datum/job/special/syndicate/weak
	name = "Junior Syndicate Operative"
	slot_belt = list(/obj/item/gun/kinetic/pistol)
	slot_ears = list() //No Headset
	slot_card = null //No Access
	slot_poc1 = list(/obj/item/storage/pouch/bullet_9mm)
	items_in_backpack = list(
		/obj/item/clothing/head/helmet/space/syndicate,
		/obj/item/clothing/suit/space/syndicate)

/datum/job/special/syndicate/weak/no_ammo
	name = "Poorly Equipped Junior Syndicate Operative"
	slot_poc1 = list() //And also no ammo.

//Specialist operatives using nukie class gear
ABSTRACT_TYPE(/datum/job/special/syndicate/specialist)
/datum/job/special/syndicate/specialist
	name = "Syndicate Specialist"
	special_spawn_location = LANDMARK_SYNDICATE
	receives_implants = list(/obj/item/implant/revenge/microbomb)
	slot_back = list(/obj/item/storage/backpack/syndie/tactical)
	slot_lhan = list(/obj/item/remote/syndicate_teleporter) //To get off the cairngorm with
	slot_rhan = list(/obj/item/tank/jetpack/syndicate) //To get off the listening post with

/datum/job/special/syndicate/specialist/demo
	name = "Syndicate Grenadier"
	slot_head = list(/obj/item/clothing/head/helmet/space/syndicate/specialist)
	slot_suit = list(/obj/item/clothing/suit/space/syndicate/specialist/grenadier)
	slot_poc1 = list(/obj/item/storage/pouch/grenade_round)
	items_in_backpack = list(/obj/item/gun/kinetic/grenade_launcher,
		/obj/item/storage/grenade_pouch/mixed_explosive)

/datum/job/special/syndicate/specialist/heavy
	name = "Syndicate Heavy Weapons Specialist"
	slot_head = list(/obj/item/clothing/head/helmet/space/syndicate/specialist)
	slot_suit = list(/obj/item/clothing/suit/space/syndicate/specialist/heavy)
	slot_poc1 = list(/obj/item/storage/pouch/lmg)
	slot_back = list(/obj/item/gun/kinetic/light_machine_gun)
	slot_belt = list(/obj/item/storage/fanny/syndie/large)
	items_in_belt = list(/obj/item/storage/grenade_pouch/high_explosive)

/datum/job/special/syndicate/specialist/assault
	name = "Syndicate Assault Trooper"
	slot_head = list(/obj/item/clothing/head/helmet/space/syndicate/specialist)
	slot_suit = list(/obj/item/clothing/suit/space/syndicate/specialist)
	slot_poc1 = list(/obj/item/storage/pouch/assault_rifle/mixed)
	items_in_backpack = list(/obj/item/gun/kinetic/assault_rifle,
		/obj/item/storage/grenade_pouch/mixed_standard,
		/obj/item/breaching_charge,
		/obj/item/breaching_charge)

//Incredibly bloated :/
/datum/job/special/syndicate/specialist/infiltrator
	name = "Syndicate Infiltrator"
	slot_head = list(/obj/item/clothing/head/helmet/space/syndicate/specialist/infiltrator)
	slot_suit = list(/obj/item/clothing/suit/space/syndicate/specialist)
	slot_poc1 = list(/obj/item/storage/pouch/tranq_pistol_dart)
	slot_lhan = list(/obj/item/storage/backpack/chameleon)
	items_in_backpack = list(/obj/item/gun/kinetic/tranq_pistol,
		/obj/item/dna_scrambler,
		/obj/item/voice_changer,
		/obj/item/card/emag,
		/obj/item/device/chameleon,
		/obj/item/remote/syndicate_teleporter) //Because their hands are filled with their chameleon gear

	special_setup(var/mob/living/carbon/human/M)
		..()
		var/obj/item/remote/chameleon/remote = locate(/obj/item/remote/chameleon) in M
		M.stow_in_available(remote)

/datum/job/special/syndicate/specialist/scout
	name = "Syndicate Scout"
	slot_head = list(/obj/item/clothing/head/helmet/space/syndicate/specialist/infiltrator)
	slot_suit = list(/obj/item/clothing/suit/space/syndicate/specialist/infiltrator)
	slot_eyes = list(/obj/item/clothing/glasses/nightvision)
	slot_poc1 = list(/obj/item/storage/pouch/bullet_9mm/smg)
	items_in_backpack = list(/obj/item/gun/kinetic/smg,
		/obj/item/card/emag,
		/obj/item/cloaking_device,
		/obj/item/lightbreaker)

/datum/job/special/syndicate/specialist/medic
	name = "Syndicate Field Medic"
	slot_head = list(/obj/item/clothing/head/helmet/space/syndicate/specialist/medic)
	slot_suit = list(/obj/item/clothing/suit/space/syndicate/specialist/medic)
	slot_poc1 = list(/obj/item/storage/pouch/veritate)
	slot_belt = list(/obj/item/storage/belt/syndicate_medic_belt)
	items_in_backpack = list(/obj/item/gun/kinetic/veritate,
		/obj/item/storage/medical_pouch,
		/obj/item/device/analyzer/healthanalyzer/upgraded,
		/obj/item/robodefibrillator,
		/obj/item/extinguisher/large)

/datum/job/special/syndicate/specialist/engineer
	name = "Syndicate Combat Engineer"
	slot_head = list(/obj/item/clothing/head/helmet/space/syndicate/specialist/engineer)
	slot_suit = list(/obj/item/clothing/suit/space/syndicate/specialist/engineer)
	slot_poc1 = list(/obj/item/storage/pouch/shotgun/weak)
	slot_belt = list(/obj/item/storage/belt/utility/prepared)
	items_in_backpack = list(/obj/item/gun/kinetic/spes/engineer,
		/obj/item/turret_deployer/syndicate,
		/obj/item/paper/nast_manual,
		/obj/item/wrench/battle,
		/obj/item/weldingtool/high_cap)

/datum/job/special/syndicate/specialist/firebrand
	name = "Syndicate Firebrand"
	slot_head = list(/obj/item/clothing/head/helmet/space/syndicate/specialist/firebrand)
	slot_suit = list(/obj/item/clothing/suit/space/syndicate/specialist/firebrand)
	slot_poc1 = list(/obj/item/storage/grenade_pouch/napalm)
	slot_belt = list(/obj/item/storage/fanny/syndie/large)
	slot_back = null //flamethrower given in special setup
	slot_rhan = null //napalm tank is a jetpack
	items_in_belt = list(/obj/item/fireaxe,
		/obj/item/storage/grenade_pouch/incendiary)

	special_setup(var/mob/living/carbon/human/M)
		..()
		var/obj/item/gun/flamethrower/backtank/flamethrower = new /obj/item/gun/flamethrower/backtank/napalm(M)
		var/obj/item/tank/jetpack/backtank/our_tank = flamethrower.fueltank
		our_tank.insert_flamer(flamethrower, M)
		M.equip_if_possible(our_tank, SLOT_BACK)

/datum/job/special/syndicate/specialist/marksman
	name = "Syndicate Marksman"
	slot_head = list(/obj/item/clothing/head/helmet/space/syndicate/specialist/sniper)
	slot_suit = list(/obj/item/clothing/suit/space/syndicate/specialist/sniper)
	slot_poc1 = list(/obj/item/storage/pouch/sniper)
	slot_eyes = list(/obj/item/clothing/glasses/thermal/traitor)
	slot_back = list(/obj/item/gun/kinetic/sniper)
	slot_belt = list(/obj/item/storage/fanny/syndie/large)
	items_in_belt = list(/obj/item/storage/grenade_pouch/smoke)

/datum/job/special/syndicate/specialist/knight
	name = "Syndicate Knight"
	slot_head = list(/obj/item/clothing/head/helmet/space/syndicate/specialist/knight)
	slot_suit = list(/obj/item/clothing/suit/space/syndicate/specialist/knight)
	slot_foot = list(/obj/item/clothing/shoes/swat/knight)
	slot_glov = list(/obj/item/clothing/gloves/swat/syndicate/knight)
	slot_back = list(/obj/item/heavy_power_sword)
	slot_belt = list(/obj/item/storage/fanny/syndie/large)

/datum/job/special/syndicate/specialist/bard
	name = "Syndicate Bard"
	slot_head = list(/obj/item/clothing/head/helmet/space/syndicate/specialist/bard)
	slot_suit = list(/obj/item/clothing/suit/space/syndicate/specialist/bard)
	slot_ears = list(/obj/item/device/radio/headset/syndicate/bard)
	slot_back = null //Special setup will put a speaker here
	slot_belt = list(/obj/item/storage/fanny/syndie/large)

	special_setup(var/mob/living/carbon/human/M)
		..()
		var/obj/item/breaching_hammer/rock_sledge/guitar = new /obj/item/breaching_hammer/rock_sledge(M)
		for(var/obj/item/device/radio/nukie_studio_monitor/speaker in guitar.speakers)
			if(!M.equip_if_possible(speaker, SLOT_BACK))
				M.stow_in_available(speaker)
		M.stow_in_available(guitar)

//TEAM RED END. TEAM BLU START.

ABSTRACT_TYPE(/datum/job/special/nt)
/datum/job/special/nt
	linkcolor = NANOTRASEN_LINK_COLOR
	limit = 0
	wages = PAY_IMPORTANT
	//Emergency responders shouldn't be antags
	can_roll_antag = FALSE
	badge = /obj/item/clothing/suit/security_badge/nanotrasen
	receives_implants = list(/obj/item/implant/health/security/anti_mindhack)
	access_string = "Nanotrasen Responder" // "All Access" + Centcom

	slot_back = list(/obj/item/storage/backpack/NT)
	slot_jump = list(/obj/item/clothing/under/misc/turds)
	slot_foot = list(/obj/item/clothing/shoes/swat)
	slot_glov = list(/obj/item/clothing/gloves/swat/NT)
	slot_ears = list(/obj/item/device/radio/headset/command/nt) //needs their own secret channel
	slot_card = /obj/item/card/id/nanotrasen
	faction = list(FACTION_NANOTRASEN)

/datum/job/special/nt/special_operative
	name = "Nanotrasen Special Operative"
	trait_list = list("training_security")
	receives_miranda = TRUE
	slot_belt = list(/obj/item/storage/belt/security/ntso)
	slot_suit = list(/obj/item/clothing/suit/space/ntso)
	slot_head = list(/obj/item/clothing/head/helmet/space/ntso)
	slot_eyes = list(/obj/item/clothing/glasses/nightvision/sechud/flashblocking)
	slot_mask = list(/obj/item/clothing/mask/gas/NTSO)
	slot_poc1 = list(/obj/item/device/pda2/ntso)
	slot_poc2 = list(/obj/item/storage/ntsc_pouch/ntso)
	items_in_backpack = list(/obj/item/storage/firstaid/regular,
							/obj/item/clothing/head/NTberet)

/datum/job/special/nt/commander
	name = "Nanotrasen Commander"
	trait_list = list("training_security", "training_medical")
	wages = PAY_EXECUTIVE //The big boss
	receives_miranda = TRUE
	receives_disk = /obj/item/disk/data/floppy/sec_command

	slot_belt = list(/obj/item/swords_sheaths/ntboss)
	slot_jump = list(/obj/item/clothing/under/misc/NT)
	slot_suit = list(/obj/item/clothing/suit/space/nanotrasen/pilot/commander)
	slot_head = list(/obj/item/clothing/head/NTberet/commander)
	slot_foot = list(/obj/item/clothing/shoes/swat/heavy)
	slot_eyes = list(/obj/item/clothing/glasses/nt_operative)
	slot_ears = list(/obj/item/device/radio/headset/command/nt/commander)
	slot_mask = list(/obj/item/clothing/mask/gas/NTSO)
	slot_poc1 = list(/obj/item/device/pda2/ntso)
	slot_poc2 = list(/obj/item/storage/ntsc_pouch/ntso)
	items_in_backpack = list(/obj/item/storage/firstaid/regular)


/datum/job/special/nt/engineer
	name = "Nanotrasen Emergency Repair Technician"
	trait_list = list("training_engineer")

	slot_belt = list(/obj/item/storage/belt/utility/nt_engineer)
	slot_jump = list(/obj/item/clothing/under/rank/engineer)
	slot_suit = list(/obj/item/clothing/suit/space/industrial/nt_specialist)
	slot_head = list(/obj/item/clothing/head/helmet/space/ntso)
	slot_foot = list(/obj/item/clothing/shoes/magnetic)
	slot_eyes = list(/obj/item/clothing/glasses/toggleable/meson)
	slot_ears = list(/obj/item/device/radio/headset/command/nt/engineer)
	slot_mask = list(/obj/item/clothing/mask/gas/NTSO)
	slot_poc1 = list(/obj/item/tank/pocket/extended/oxygen)
	slot_poc2 = list(/obj/item/device/pda2/nt_engineer)
	items_in_backpack = list(/obj/item/storage/firstaid/regular,
							/obj/item/device/flash,
							/obj/item/sheet/steel/fullstack,
							/obj/item/sheet/glass/reinforced/fullstack)

	special_setup(var/mob/living/carbon/human/M)
		..()
		SPAWN(1)
			var/obj/item/rcd/rcd = locate() in M.belt.storage.stored_items
			rcd.matter = 100
			rcd.max_matter = 100
			rcd.tooltip_rebuild = TRUE
			rcd.UpdateIcon()

/datum/job/special/nt/medic
	name = "Nanotrasen Emergency Medic"
	trait_list = list("training_medical")

	slot_belt = list(/obj/item/storage/belt/medical/prepared)
	slot_jump = list(/obj/item/clothing/under/rank/medical)
	slot_suit = list(/obj/item/clothing/suit/hazard/paramedic/armored)
	slot_head = list(/obj/item/clothing/head/helmet/space/ntso)
	slot_foot = list(/obj/item/clothing/shoes/brown)
	slot_glov = list(/obj/item/clothing/gloves/latex)
	slot_eyes = list(/obj/item/clothing/glasses/healthgoggles/upgraded)
	slot_ears = list(/obj/item/device/radio/headset/command/nt/medic)
	slot_mask = list(/obj/item/clothing/mask/gas/NTSO)
	slot_poc1 = list(/obj/item/tank/pocket/extended/oxygen)
	slot_poc2 = list(/obj/item/device/pda2/nt_medical)
	items_in_backpack = list(/obj/item/storage/firstaid/regular,
							/obj/item/device/flash,
							/obj/item/reagent_containers/glass/bottle/omnizine,
							/obj/item/reagent_containers/glass/bottle/ether)

// Use this one for late respawns to deal with existing antags. they are weaker cause they dont get a laser rifle or frags
/datum/job/special/nt/security_consultant
	name = "Nanotrasen Security Consultant"
	limit = 1 // backup during HELL WEEK. players will probably like it
	unique = TRUE
	wages = PAY_TRADESMAN
	trait_list = list("training_security")
	access_string = "Nanotrasen Security Consultant"
	requires_whitelist = TRUE
	requires_supervisor_job = "Head of Security"
	counts_as = "Security Officer"
	receives_miranda = TRUE

	slot_belt = list(/obj/item/storage/belt/security/ntsc)
	slot_suit = list(/obj/item/clothing/suit/space/ntso)
	slot_head = list(/obj/item/clothing/head/NTberet)
	slot_eyes = list(/obj/item/clothing/glasses/sunglasses/sechud)
	slot_ears = list(/obj/item/device/radio/headset/command/nt/consultant)
	slot_mask = list(/obj/item/clothing/mask/gas/NTSO)
	slot_poc1 = list(/obj/item/storage/ntsc_pouch)
	slot_poc2 = list(/obj/item/device/pda2/ntso)
	items_in_backpack = list(/obj/item/storage/firstaid/regular)
	wiki_link = "https://wiki.ss13.co/Nanotrasen_Security_Consultant"

//NT RESPONDER JOBS END

/datum/job/special/pirate
	linkcolor = SYNDICATE_LINK_COLOR
	name = "Space Pirate"
	limit = 0
	wages = 0
	add_to_manifest = FALSE
	radio_announcement = FALSE
	can_roll_antag = FALSE
	slot_card = /obj/item/card/id
	slot_belt = list()
	slot_back = list()
	slot_jump = list()
	slot_foot = list()
	slot_head = list()
	slot_eyes = list()
	slot_ears = list()
	slot_poc1 = list()
	slot_poc2 = list()
	var/rank = ROLE_PIRATE

	New()
		..()
		src.access = list(access_maint_tunnels, access_pirate )
		return

	special_setup(var/mob/living/carbon/human/M)
		..()
		if (!M)
			return

		for (var/datum/antagonist/antag in M.mind.antagonists)
			if (antag.id == ROLE_PIRATE || antag.id == ROLE_PIRATE_FIRST_MATE || antag.id == ROLE_PIRATE_CAPTAIN)
				antag.give_equipment()
				return
		M.mind.add_antagonist(rank, source = ANTAGONIST_SOURCE_ADMIN)


	first_mate
		name = "Space Pirate First Mate"
		rank = ROLE_PIRATE_FIRST_MATE

	captain
		name = "Space Pirate Captain"
		rank = ROLE_PIRATE_CAPTAIN

/datum/job/special/juicer_specialist
	linkcolor = "#cc8899"
	name = "Juicer Security"
	limit = 0
	wages = 0
	can_roll_antag = FALSE
	add_to_manifest = FALSE

	slot_back = list(/obj/item/gun/energy/blaster_cannon)
	slot_belt = list(/obj/item/storage/fanny)
	//more

/datum/job/special/headminer
	name = "Head of Mining"
	limit = 0
	wages = PAY_IMPORTANT
	trait_list = list("training_miner")
	access_string = "Head of Mining"
	linkcolor = COMMAND_LINK_COLOR
	invalid_antagonist_roles = list(ROLE_HEAD_REVOLUTIONARY, ROLE_GANG_MEMBER, ROLE_GANG_LEADER, ROLE_SPY_THIEF, ROLE_CONSPIRATOR)
	slot_card = /obj/item/card/id/command
	slot_belt = list(/obj/item/device/pda2/mining)
	slot_jump = list(/obj/item/clothing/under/rank/overalls)
	slot_foot = list(/obj/item/clothing/shoes/orange)
	slot_glov = list(/obj/item/clothing/gloves/black)
	slot_ears = list(/obj/item/device/radio/headset/command/ce)
	items_in_backpack = list(/obj/item/tank/pocket/oxygen,/obj/item/crowbar)

/datum/job/special/machoman
	name = "Macho Man"
	linkcolor = "#9E0E4D"
	limit = 0
	slot_ears = list()
	slot_card = null
	slot_back = list()
	items_in_backpack = list()
	wiki_link = "https://wiki.ss13.co/Admin#Special_antagonists"

	special_setup(var/mob/living/carbon/human/M)
		..()
		if (!M)
			return
		M.mind?.add_antagonist(ROLE_MACHO_MAN, source = ANTAGONIST_SOURCE_ADMIN)

/datum/job/special/meatcube
	name = "Meatcube"
	linkcolor = SECURITY_LINK_COLOR
	limit = 0
	can_roll_antag = FALSE
	slot_ears = list()
	slot_card = null
	slot_back = list()
	items_in_backpack = list()
	add_to_manifest = FALSE
	wiki_link = "https://wiki.ss13.co/Critter#Other"

	special_setup(var/mob/living/carbon/human/M)
		..()
		if (!M)
			return
		M.cubeize(INFINITY)

/datum/job/special/ghostdrone
	name = "Drone"
	linkcolor = SILICON_LINK_COLOR
	limit = 0
	wages = 0
	can_roll_antag = FALSE
	slot_ears = list()
	slot_card = null
	slot_back = list()
	items_in_backpack = list()
	wiki_link = "https://wiki.ss13.co/Ghostdrone"

	special_setup(var/mob/living/carbon/human/M)
		..()
		if (!M)
			return
		droneize(M, 0)

ABSTRACT_TYPE(/datum/job/daily)
/datum/job/daily //Special daily jobs
	request_limit = 2
	request_cost = PAY_DOCTORATE*4
	var/day = ""
/datum/job/daily/boxer
	day = "Sunday"
	name = "Boxer"
	wages = PAY_UNTRAINED
	access_string = "Boxer"
	limit = 4
	slot_jump = list(/obj/item/clothing/under/shorts)
	slot_foot = list(/obj/item/clothing/shoes/black)
	slot_glov = list(/obj/item/clothing/gloves/boxing)
	change_name_on_spawn = TRUE
	wiki_link = "https://wiki.ss13.co/Boxer"

/datum/job/daily/dungeoneer
	day = "Monday"
	name = "Dungeoneer"
	limit = 1
	wages = PAY_UNTRAINED
	access_string = "Dungeoneer"
	slot_belt = list(/obj/item/device/pda2)
	slot_mask = list(/obj/item/clothing/mask/skull)
	slot_jump = list(/obj/item/clothing/under/color/brown)
	slot_suit = list(/obj/item/clothing/suit/cultist/nerd)
	slot_glov = list(/obj/item/clothing/gloves/black)
	slot_foot = list(/obj/item/clothing/shoes/brown)
	slot_poc1 = list(/obj/item/pen/omni)
	slot_poc2 = list(/obj/item/paper)
	items_in_backpack = list(/obj/item/storage/box/nerd_kit)
	change_name_on_spawn = TRUE
	wiki_link = "https://wiki.ss13.co/Jobs#Job_of_the_Day" // no wiki page yet

/datum/job/daily/barber
	day = "Tuesday"
	name = "Barber"
	wages = PAY_UNTRAINED
	access_string = "Barber"
	limit = 1
	slot_jump = list(/obj/item/clothing/under/misc/barber)
	slot_head = list(/obj/item/clothing/head/boater_hat)
	slot_foot = list(/obj/item/clothing/shoes/black)
	slot_poc1 = list(/obj/item/scissors)
	slot_poc2 = list(/obj/item/razor_blade)
	slot_ears = list(/obj/item/device/radio/headset/civilian)
	alt_names = list("Barber", "Hairdresser")
	wiki_link = "https://wiki.ss13.co/Barber"

/datum/job/daily/waiter
	day = "Wednesday"
	name = "Waiter"
	wages = PAY_UNTRAINED
	access_string = "Waiter"
	slot_jump = list(/obj/item/clothing/under/rank/bartender)
	slot_suit = list(/obj/item/clothing/suit/wcoat)
	slot_foot = list(/obj/item/clothing/shoes/black)
	slot_ears = list(/obj/item/device/radio/headset/civilian)
	slot_lhan = list(/obj/item/plate/tray)
	slot_poc1 = list(/obj/item/cloth/towel/white)
	items_in_backpack = list(/obj/item/storage/box/glassbox,/obj/item/storage/box/cutlery)
	wiki_link = "https://wiki.ss13.co/Jobs#Job_of_the_Day" // no wiki page yet

/datum/job/daily/lawyer
	day = "Thursday"
	name = "Lawyer"
	linkcolor = SECURITY_LINK_COLOR
	wages = PAY_DOCTORATE
	access_string = "Lawyer"
	limit = 4
	badge = /obj/item/clothing/suit/security_badge/attorney
	slot_jump = list(/obj/item/clothing/under/misc/lawyer)
	slot_foot = list(/obj/item/clothing/shoes/black)
	slot_lhan = list(/obj/item/storage/briefcase)
	slot_ears = list(/obj/item/device/radio/headset/civilian)
	alt_names = list("Lawyer", "Attorney")
	wiki_link = "https://wiki.ss13.co/Lawyer"


/datum/job/daily/tourist
	day = "Friday"
	name = "Tourist"
	limit = 100
	request_limit = 0
	wages = 0
	slot_back = null
	slot_belt = list(/obj/item/storage/fanny)
	slot_jump = list(/obj/item/clothing/under/misc/tourist)
	slot_poc1 = list(/obj/item/camera_film)
	slot_poc2 = list(/obj/item/currency/spacecash/tourist) // Exact amount is randomized.
	slot_foot = list(/obj/item/clothing/shoes/tourist)
	slot_lhan = list(/obj/item/camera)
	slot_rhan = list(/obj/item/storage/photo_album)
	change_name_on_spawn = TRUE
	wiki_link = "https://wiki.ss13.co/Tourist"

	special_setup(var/mob/living/carbon/human/M)
		..()
		if (!M)
			return

		var/morph = null
		if(prob(33))
			morph = pick(/datum/mutantrace/lizard,/datum/mutantrace/skeleton,/datum/mutantrace/ithillid,/datum/mutantrace/martian,/datum/mutantrace/amphibian,/datum/mutantrace/blob,/datum/mutantrace/cow)

		if (morph && (morph == /datum/mutantrace/martian || morph == /datum/mutantrace/blob)) // doesn't wear human clothes
			M.equip_if_possible(new /obj/item/storage/backpack/empty(src), SLOT_BACK)
			var/obj/item/backpack = M.back

			var/obj/item/storage/fanny/belt_storage = M.belt
			if(istype(belt_storage))
				for(var/obj/item/I in belt_storage.storage.get_contents())
					belt_storage.storage.transfer_stored_item(I, backpack, TRUE, M)
			qdel(belt_storage)

			M.equip_if_possible(new /obj/item/device/speech_pro(src), SLOT_IN_BACKPACK)

			M.stow_in_available(M.l_store, FALSE)
			M.stow_in_available(M.r_store, FALSE)

			var/obj/item/shirt = M.get_slot(SLOT_W_UNIFORM)
			M.drop_from_slot(shirt)
			qdel(shirt)

			var/obj/item/shoes = M.get_slot(SLOT_SHOES)
			M.drop_from_slot(shoes)
			qdel(shoes)

		else
			var/obj/item/clothing/lanyard/L = new /obj/item/clothing/lanyard(M.loc)
			var/obj/item/card/id = locate() in M
			if (id)
				L.storage.add_contents(id, M, FALSE)
			if (M.l_store)
				M.stow_in_available(M.l_store)
			M.equip_if_possible(new /obj/item/device/speech_pro(src), SLOT_L_STORE)
			M.equip_if_possible(L, SLOT_WEAR_ID, TRUE)

		if(morph) // now that we've handled weird mutantrace cases, morph them
			M.set_mutantrace(morph)

/datum/job/daily/musician
	day = "Saturday"
	name = "Musician"
	limit = 3
	wages = PAY_UNTRAINED
	slot_jump = list(/obj/item/clothing/under/suit/pinstripe)
	slot_head = list(/obj/item/clothing/head/flatcap)
	slot_foot = list(/obj/item/clothing/shoes/brown)
	slot_ears = list(/obj/item/device/radio/headset/civilian)
	slot_lhan = list(/obj/item/storage/briefcase/instruments)
	change_name_on_spawn = TRUE
	wiki_link = "https://wiki.ss13.co/Musician"

/datum/job/battler
	name = "Battler"
	limit = -1
	wiki_link = "https://wiki.ss13.co/Battler"

/datum/job/slasher
	name = "The Slasher"
	linkcolor = "#02020d"
	limit = 0
	slot_ears = list()
	slot_card = null
	slot_back = list()
	items_in_backpack = list()
	wiki_link = "https://wiki.ss13.co/The_Slasher"

	special_setup(var/mob/living/carbon/human/M)
		..()
		if (!M)
			return
		M.mind?.add_antagonist(ROLE_SLASHER, source = ANTAGONIST_SOURCE_ADMIN)

ABSTRACT_TYPE(/datum/job/special/pod_wars)
/datum/job/special/pod_wars
	name = "Pod_Wars"
#ifdef MAP_OVERRIDE_POD_WARS
	limit = -1
	wages = 0 //Who needs cash when theres a battle to win
#else
	limit = 0
	wages = PAY_IMPORTANT
#endif
	can_roll_antag = FALSE
	var/team = 0 //1 = NT, 2 = SY
	var/overlay_icon
	wiki_link = "https://wiki.ss13.co/Game_Modes#Pod_Wars"

	special_setup(var/mob/living/carbon/human/M)
		..()
		if (!M)
			return

		if (!M.abilityHolder)
			M.abilityHolder = new /datum/abilityHolder/pod_pilot(src)
			M.abilityHolder.owner = src
		else if (istype(M.abilityHolder, /datum/abilityHolder/composite))
			var/datum/abilityHolder/composite/AH = M.abilityHolder
			AH.addHolder(/datum/abilityHolder/pod_pilot)

		if (istype(ticker.mode, /datum/game_mode/pod_wars))
			var/datum/game_mode/pod_wars/mode = ticker.mode
			mode.setup_team_overlay(M.mind, overlay_icon)
			if (team == 1)
				M.mind.special_role = mode.team_NT?.name
			else if (team == 2)
				M.mind.special_role = mode.team_SY?.name

	nanotrasen
		name = "NanoTrasen Pod Pilot"
		linkcolor = NANOTRASEN_LINK_COLOR
		no_jobban_from_this_job = TRUE
		low_priority_job = TRUE
		cant_allocate_unwanted = TRUE
		access = list(access_heads, access_medical, access_medical_lockers, access_mining)
		team = 1
		overlay_icon = "nanotrasen"

		faction = list(FACTION_NANOTRASEN)

		receives_implants = list(/obj/item/implant/pod_wars/nanotrasen)
		slot_back = list(/obj/item/storage/backpack/NT)
		slot_jump = list(/obj/item/clothing/under/misc/turds)
		slot_head = list(/obj/item/clothing/head/helmet/space/pod_wars/NT)
		slot_suit = list(/obj/item/clothing/suit/space/pod_wars/NT)
		slot_foot = list(/obj/item/clothing/shoes/swat)
		slot_card = /obj/item/card/id/pod_wars/nanotrasen
		slot_ears = list(/obj/item/device/radio/headset/pod_wars/nanotrasen)
		slot_mask = list(/obj/item/clothing/mask/gas/swat/NT)
		slot_glov = list(/obj/item/clothing/gloves/swat/NT)
		slot_poc1 = list(/obj/item/tank/pocket/extended/oxygen)
		slot_poc2 = list(/obj/item/requisition_token/podwars/NT)

		commander
			name = "NanoTrasen Pod Commander"
#ifdef MAP_OVERRIDE_POD_WARS
			limit = 1
#else
			limit = 0
#endif
			no_jobban_from_this_job = FALSE
			high_priority_job = TRUE
			cant_allocate_unwanted = TRUE
			overlay_icon = "nanocomm"
			access = list(access_heads, access_captain, access_medical, access_medical_lockers, access_engineering_power, access_mining)

			slot_head = list(/obj/item/clothing/head/helmet/space/pod_wars/NT/commander)
			slot_suit = list(/obj/item/clothing/suit/space/pod_wars/NT/commander)
			slot_card = /obj/item/card/id/pod_wars/nanotrasen/commander
			slot_ears = list(/obj/item/device/radio/headset/pod_wars/nanotrasen/commander)

	syndicate
		name = "Syndicate Pod Pilot"
		linkcolor = SYNDICATE_LINK_COLOR
		no_jobban_from_this_job = TRUE
		low_priority_job = TRUE
		cant_allocate_unwanted = TRUE
		access = list(access_syndicate_shuttle, access_medical, access_medical_lockers, access_mining)
		team = 2
		overlay_icon = "syndicate"
		add_to_manifest = FALSE

		faction = list(FACTION_SYNDICATE)

		receives_implants = list(/obj/item/implant/pod_wars/syndicate)
		slot_back = list(/obj/item/storage/backpack/syndie)
		slot_jump = list(/obj/item/clothing/under/misc/syndicate)
		slot_head = list(/obj/item/clothing/head/helmet/space/pod_wars/SY)
		slot_suit = list(/obj/item/clothing/suit/space/pod_wars/SY)
		slot_foot = list(/obj/item/clothing/shoes/swat)
		slot_card = /obj/item/card/id/pod_wars/syndicate
		slot_ears = list(/obj/item/device/radio/headset/pod_wars/syndicate)
		slot_mask = list(/obj/item/clothing/mask/gas/swat)
		slot_glov = list(/obj/item/clothing/gloves/swat/syndicate)
		slot_poc1 = list(/obj/item/tank/pocket/extended/oxygen)
		slot_poc2 = list(/obj/item/requisition_token/podwars/SY)

		commander
			name = "Syndicate Pod Commander"
#ifdef MAP_OVERRIDE_POD_WARS
			limit = 1
#else
			limit = 0
#endif
			no_jobban_from_this_job = FALSE
			high_priority_job = TRUE
			cant_allocate_unwanted = TRUE
			overlay_icon = "syndcomm"
			access = list(access_syndicate_shuttle, access_syndicate_commander, access_medical, access_medical_lockers, access_engineering_power, access_mining)

			slot_head = list(/obj/item/clothing/head/helmet/space/pod_wars/SY/commander)
			slot_suit = list(/obj/item/clothing/suit/space/pod_wars/SY/commander)
			slot_card = /obj/item/card/id/pod_wars/syndicate/commander
			slot_ears = list(/obj/item/device/radio/headset/pod_wars/syndicate/commander)

/datum/job/football
	name = "Football Player"
	limit = -1
	wiki_link = "https://wiki.ss13.co/Game_Modes#Football"


/datum/job/special/gang_respawn
	name = "Gang Respawn"
	limit = 0
	wages = 0
	access_string = "Staff Assistant"
	slot_card = /obj/item/card/id/civilian
	slot_jump = list(/obj/item/clothing/under/rank/assistant)
	slot_foot = list(/obj/item/clothing/shoes/black)
	slot_ears = list(/obj/item/device/radio/headset/civilian)
	announce_on_join = FALSE
	add_to_manifest = FALSE

	special_setup(var/mob/living/carbon/human/M)
		..()
		SPAWN(0)
			var/obj/item/card/id/C = M.get_slot(SLOT_WEAR_ID)
			C.assignment = "Staff Assistant"
			C.name = "[C.registered]'s ID Card ([C.assignment])"

			M.job = "Staff Assistant" // for observers

			var/obj/item/device/pda2/pda = locate() in M
			pda.assignment = "Staff Assistant"
			pda.ownerAssignment = "Staff Assistant"

/datum/job/special/pathologist
	name = "Pathologist"
	limit = 0
	wages = PAY_DOCTORATE
	access_string = "Pathologist"
	slot_belt = list(/obj/item/device/pda2/genetics)
	slot_jump = list(/obj/item/clothing/under/rank/pathologist)
	slot_foot = list(/obj/item/clothing/shoes/white)
	slot_suit = list(/obj/item/clothing/suit/labcoat/pathology)
	slot_ears = list(/obj/item/device/radio/headset/medical)

/datum/job/special/performer
	name = "Performer"
	access_string = "Staff Assistant"
	limit = 0
	change_name_on_spawn = TRUE
	slot_ears = list(/obj/item/device/radio/headset)
	slot_jump = list(/obj/item/clothing/under/gimmick/black_wcoat)
	slot_foot = list(/obj/item/clothing/shoes/dress_shoes)
	slot_belt = list(/obj/item/device/pda2)
	items_in_backpack = list(/obj/item/storage/box/box_o_laughs, /obj/item/item_box/assorted/stickers/stickers_limited, /obj/item/currency/spacecash/twothousandfivehundred)

	special_setup(var/mob/living/carbon/human/M)
		..()
		if (!M)
			return
		M.bioHolder.AddEffect("accent_goodmin", magical=1)

/datum/job/special/werewolf_hunter
	name = "Werewolf Hunter"
	access_string = "Staff Assistant"
	limit = 0
	change_name_on_spawn = TRUE
	slot_head = list(/obj/item/clothing/head/witchfinder)
	slot_ears = list(/obj/item/device/radio/headset/werewolf_hunter)
	slot_suit = list(/obj/item/clothing/suit/witchfinder)
	slot_jump = list(/obj/item/clothing/under/gimmick/witchfinder)
	slot_glov = list(/obj/item/clothing/gloves/black)
	slot_foot = list(/obj/item/clothing/shoes/witchfinder)
	slot_back = list(/obj/item/quiver/leather/stocked)
	slot_belt = list(/obj/item/storage/belt/crossbow)
	slot_poc1 = list(/obj/item/storage/werewolf_hunter_pouch)

	items_in_belt = list(
		/obj/item/dagger/silver,
		/obj/item/gun/bow/crossbow/wooden,
		/obj/item/gun/bow/crossbow/wooden,
		/obj/item/handcuffs/silver,
		/obj/item/handcuffs/silver,
	)

/*---------------------------------------------------------------*/

/datum/job/created
	name = "Special Job"
	job_category = JOB_CREATED

	//handle special spawn location
	Write(F)
		. = ..()
		if(istext(src.special_spawn_location))
			F["special_spawn_location"] << src.special_spawn_location
		else if(ismovable(src.special_spawn_location) || isturf(src.special_spawn_location))
			var/atom/A = src.special_spawn_location
			var/turf/T = get_turf(A)
			F["special_spawn_location_coords"] << list(T.x, T.y, T.z)

	Read(F)
		. = ..()
		src.special_spawn_location = null
		var/maybe_spawn_loc = null
		F["special_spawn_location"] >> maybe_spawn_loc
		if(istext(maybe_spawn_loc))
			src.special_spawn_location = maybe_spawn_loc
		else
			var/list/maybe_coords = null
			F["special_spawn_location_coords"] >> maybe_coords
			if(islist(maybe_coords))
				src.special_spawn_location = locate(maybe_coords[1], maybe_coords[2], maybe_coords[3])

#undef COMMAND_LINK_COLOR
#undef SECURITY_LINK_COLOR
#undef RESEARCH_LINK_COLOR
#undef MEDICAL_LINK_COLOR
#undef ENGINEERING_LINK_COLOR
#undef CIVILIAN_LINK_COLOR
#undef SILICON_LINK_COLOR
#undef NANOTRASEN_LINK_COLOR
#undef SYNDICATE_LINK_COLOR

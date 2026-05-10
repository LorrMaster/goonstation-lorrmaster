/datum/antagonist/artifact_cyborg
	id = ROLE_ARTIFACT_ROBOT_HARMFUL
	display_name = "\improper Artifact cyborg"
	antagonist_icon = "artifact_cyborg"
	succinct_end_of_round_antagonist_entry = TRUE
	remove_on_death = TRUE
	remove_on_clone = TRUE
	keep_equipment_on_death = TRUE
	has_info_popup = FALSE
	var/artifact_role = ROLE_ARTIFACT_ROBOT_HARMFUL

	is_compatible_with(datum/mind/mind)
		return isrobot(mind.current)

	add_to_image_groups()
		. = ..()
		var/datum/client_image_group/image_group = get_image_group(artifact_role)
		image_group.add_mind_mob_overlay(src.owner, get_antag_icon_image())
		image_group.add_mind(src.owner)

		get_image_group(artifact_role).add_mind(src.owner)

	remove_from_image_groups()
		. = ..()
		var/datum/client_image_group/image_group = get_image_group(artifact_role)
		image_group.remove_mind_mob_overlay(src.owner)
		image_group.remove_mind(src.owner)

		get_image_group(artifact_role).remove_mind(src.owner)

	announce_objectives()
		return

	announce()
		tgui_alert(src.owner.current, "You have been converted into a cyborg by an artifact and have been given new loyalties and laws to follow!", "You have been converted!")

/datum/antagonist/artifact_cyborg/limited
	id = ROLE_ARTIFACT_ROBOT_LIMITED
	display_name = "\improper Artifact cyborg"
	artifact_role = ROLE_ARTIFACT_ROBOT_LIMITED

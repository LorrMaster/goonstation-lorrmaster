
/mob/var/static/datum/forensic_id/drag_mob_print = new("~~~~~")

/datum/track_spreader
	var/tracks_left = 0
	var/track_color = null
	var/datum/forensic_id/dna_signature = null
	var/track_state_R = null
	var/track_state_L = null

	var/static/datum/forensic_id/drag_machine_print = new("=====")
	var/static/datum/forensic_id/drag_item_print = new("-----")

	New(var/tracks_left, var/track_color = null, var/datum/forensic_id/dna_signature = null, var/state_R = null, var/state_L = null)
		..()
		if(!track_color)
			track_color = DEFAULT_BLOOD_COLOR
		src.tracks_left = tracks_left
		src.track_color = track_color
		src.track_state_R = state_R
		src.track_state_L = state_L
		src.dna_signature = dna_signature

	proc/is_tracking()
		return tracks_left != 0

	proc/place_track(turf/T, var/direction, var/datum/forensic_data/multi/tracks = null)
		if(istype_exact(T, /turf/space) || !T) //can't smear blood on space
			return
		var/obj/decal/cleanable/blood/dynamic/tracks/B = null
		if (T.messy > 0)
			B = locate(/obj/decal/cleanable/blood/dynamic) in T
		if (!B)
			if (T.active_liquid)
				return
			B = make_cleanable(/obj/decal/cleanable/blood/dynamic/tracks, T)
			B.set_sample_reagent_custom("blood", 0)

		if(src.track_state_R)
			B.add_volume(src.track_color, "blood", 0.5, 0.5, src.track_state_R, direction, null)
		if(src.track_state_L)
			B.add_volume(src.track_color, "blood", 0.5, 0.5, src.track_state_L, direction, null)
		if(!src.track_state_R && !src.track_state_L)
			var/step_state = "smear[min (3, round(tracks_left/2, 1))]"
			B.add_volume(src.track_color, "blood", 0.5, 0.5, step_state, T, 0)

		/*
		if (states[1] || states[2])
			if (states[1])
				B.add_volume(src.stain_color, src.tracked_blood["sample_reagent"], 0.5, 0.5, src.tracked_blood, states[1], T, 0)
			if (states[2])
				B.add_volume(src.stain_color, src.tracked_blood["sample_reagent"], 0.5, 0.5, src.tracked_blood, states[2], T, 0)
		else
			B.add_volume(src.stain_color, src.tracked_blood["sample_reagent"], 1, 1, src.tracked_blood, "smear2", T, 0)
		*/

		if(!B.forensic_holder)
			B.forensic_holder = new()
		if(tracks)
			B.add_evidence(tracks, FORENSIC_GROUP_TRACKS)
		else
			var/datum/forensic_data/multi/drag_print = new(src.drag_machine_print, src.drag_machine_print)
			B.add_evidence(drag_print, FORENSIC_GROUP_TRACKS)
		if(dna_signature)
			var/datum/forensic_data/dna/dna_data = new(dna_signature, DNA_FORM_BLOOD, TIME)
			B.add_evidence(dna_data, FORENSIC_GROUP_DNA)
		tracks_left--
		return

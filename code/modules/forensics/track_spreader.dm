/datum/track_spreader
	var/tracks_left = 0
	var/track_color = null
	var/datum/forensic_id/dna_signature = null
	var/track_state_R = null
	var/track_state_L = null

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

	proc/place_track(turf/T, var/direction, var/datum/forensic_data/multi/tracks = null, var/state_override = null)
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

		if(state_override)
			B.add_volume(src.track_color, "blood", 0.5, 0.5, state_override, direction, null)
		else
			if(src.track_state_R)
				B.add_volume(src.track_color, "blood", 0.5, 0.5, src.track_state_R, direction, null)
			if(src.track_state_L)
				B.add_volume(src.track_color, "blood", 0.5, 0.5, src.track_state_L, direction, null)
			if(!src.track_state_R && !src.track_state_L)
				var/step_state = "smear[min(3, round(src.tracks_left/2))]" // If tracks are null, smear amount based on tracks left
				B.add_volume(src.track_color, "blood", 0.5, 0.5, step_state, direction, null)

		if(!B.forensic_holder)
			B.forensic_holder = new()
		if(tracks)
			B.add_evidence(tracks, FORENSIC_GROUP_TRACKS)
		else
			var/datum/forensic_id/drag_machine_print = register_id("=====")
			var/datum/forensic_data/multi/drag_print = new(drag_machine_print, drag_machine_print)
			B.add_evidence(drag_print, FORENSIC_GROUP_TRACKS)
		if(dna_signature)
			var/datum/forensic_data/dna/dna_data = new(dna_signature, DNA_FORM_BLOOD, TIME)
			B.add_evidence(dna_data, FORENSIC_GROUP_DNA)
		tracks_left--
		return


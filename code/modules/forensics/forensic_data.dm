
// Note: multiple forensic_holders should not share forensic_data, each should have their own instance of the evidence

ABSTRACT_TYPE(/datum/forensic_data)
datum/forensic_data
	var/time_start = 0 // What time the evidence was first applied, or 0 if not relavent
	var/time_end = 0 // When the evidence was most recently applied
	var/perc_offset = 0 // Error offset multiplier for time estimations
	var/accuracy_mult = 1 // Individual accuracy multiplier for this piece of evidence
	var/flags = 0
	New()
		..()
		src.time_start = TIME
		src.time_end = time_start
		src.perc_offset = (rand() - 0.5) * 2
		src.accuracy_mult *= ((rand() - 0.5) * 0.15) + 1
	proc/scan_display() // The text to display when scanned
		return ""
	proc/should_remove(var/remove_flags) // Compare removable flags
		return HAS_ANY_FLAGS((src.flags & REMOVABLE_ALL), remove_flags)
	proc/mark_as_junk()
		flags = flags | IS_JUNK
	proc/get_time_estimate(var/accuracy) // Return a text estimate for when this evidence might have occured
		if(src.time_start == 0 || accuracy < 0)
			return "" // Negative accuracy -> do not report a time

		var/t_end = (TIME - src.time_end) / (1 MINUTES)
		if(t_end == 0)
			return SPAN_SUBTLE(SPAN_ITALIC(" (Current)"))
		else if(accuracy == 0) // perfect accuracy is zero
			return SPAN_SUBTLE(SPAN_ITALIC(" ([round(t_end)] mins ago)"))
		else
			accuracy = t_end * FORENSIC_BASE_ACCURACY * accuracy * accuracy_mult // Base accuracy: +-25% (20 mins -> 15-25 mins)
			var/offset = accuracy * src.perc_offset
			var/low_est = round(t_end - accuracy + offset)
			var/high_est = round(t_end + accuracy + offset)
			if(low_est == high_est)
				return SPAN_SUBTLE(SPAN_ITALIC(" ([low_est] mins ago)"))
			else
				return SPAN_SUBTLE(SPAN_ITALIC(" ([low_est] to [high_est] mins ago)"))


datum/forensic_data/basic // Evidence that can just be stored as a single ID. Flags not included.
	var/static/datum/forensic_display/disp_empty = new("@F")
	var/datum/forensic_id/evidence = null
	var/datum/forensic_display/display = null

	New(var/datum/forensic_id/id, var/datum/forensic_display/disp = disp_empty, var/flags = 0)
		..()
		src.evidence = id
		src.display = disp
		src.flags = flags

	scan_display()
		var/scan_text = replacetext(display.display_text, "@F", evidence.id)
		var/time_text = null
		if(time_start == 0)
			time_text = ""
		else
			time_text = "TTTTT"
		scan_text = replacetext(scan_text, "@T", time_text) // Change this to just add a timestamp at the end
		return scan_text

datum/forensic_data/multi // Two or three different pieces of evidence that are linked together. Flags not included.
	var/static/datum/forensic_display/disp_double = new("@A [SPAN_NOTICE("|")] @B")
	var/static/datum/forensic_display/disp_pair = new("@A @B")
	var/static/datum/forensic_display/disp_pair_double = new("@C [SPAN_NOTICE("|")] @A @B") // Easier to get pair A&B first
	var/static/datum/forensic_id/organ_empty = new("_____")
	var/datum/forensic_display/display = null // @A, @B, @C
	var/datum/forensic_id/evidence_A = null
	var/datum/forensic_id/evidence_B = null
	var/datum/forensic_id/evidence_C = null
	var/mirror_B = FALSE // Mirror evidence B when displayed. Used for retinas.

	New(var/datum/forensic_id/idA, var/datum/forensic_id/idB, var/datum/forensic_id/idC = null, var/datum/forensic_display/disp = disp_double)
		..()
		src.evidence_A = idA
		src.evidence_B = idB
		src.evidence_C = idC
		src.display = disp
	scan_display()
		var/scan_text = display.display_text
		if(!evidence_A)
			scan_text = replacetextEx(scan_text, "@A", "")
		else
			scan_text = replacetextEx(scan_text, "@A", evidence_A.id)
		if(!evidence_B)
			scan_text = replacetextEx(scan_text, "@B", "")
		else if(mirror_B)
			scan_text = replacetextEx(scan_text, "@B", evidence_B.get_retina_mirror())
		else
			scan_text = replacetextEx(scan_text, "@B", evidence_B.id)
		if(!evidence_C)
			scan_text = replacetextEx(scan_text, "@C", "")
		else
			scan_text = replacetextEx(scan_text, "@C", evidence_C.id)
		return scan_text
	proc/is_same(datum/forensic_data/multi/other)
		return src.evidence_A == other.evidence_A && src.evidence_B == other.evidence_B && src.evidence_C == other.evidence_C

datum/forensic_data/text
	var/evidence = ""

	proc/is_same(datum/forensic_data/text/other)
		return cmptextEx(src.evidence, other.evidence)

datum/forensic_data/fingerprint // An individual fingerprint applied to an item
	flags = REMOVABLE_CLEANING
	var/datum/forensic_id/print = null // The original fingerprint
	var/datum/forensic_id/glove_print = null // The glove fibres & ID
	var/datum/forensic_id/print_mask = null // The mask that the gloves apply to the print
	var/static/datum/forensic_id/empty_mask = new("") // Used to mark fingerless gloves that can still leave behind fibers

	scan_display()
		if(!src.print)
			return "FP not found: Please report as bug"
		if(!src.glove_print)
			return print.id
		if(!src.print_mask)
			return "([glove_print.id])"
		return get_print() + " ([glove_print.id])"

	proc/get_print() // return the fingerprint, which could be obscured by gloves
		if(src.print_mask == empty_mask)
			return print.id
		var/final_print = "..."
		var/bunch_char = 0
		var/bunch_num = 0
		// var/last_shown = FALSE // Used for inserting the hyphens
		for(var/i=1, i<= FINGERPRINT_LENGTH, i++)
			switch(copytext(print_mask.id, i, i+1))
				if("?")
					final_print += "?"
				if("x")
					final_print += copytext(print.id, i + bunch_num, i + bunch_num + 1)
			bunch_char++
			if(bunch_char >= FINGERPRINT_BUNCH_SIZE)
				bunch_char = 0
				bunch_num++
		return final_print + "...";

	proc/is_same(datum/forensic_data/fingerprint/other)
		return src.print == other.print && src.glove_print == other.glove_print

datum/forensic_data/dna // An individual dna sample
	var/static/datum/forensic_id/dna_unknown = new("unknown")
	flags = REMOVABLE_CLEANING
	var/datum/forensic_id/pattern = null
	var/form = DNA_FORM_NONE // Where did the DNA come from? Use DNA_FORM_NONE if not relevant
	// var/decomp_stage = DECOMP_STAGE_NO_ROT

	New(var/datum/forensic_id/dna, var/form = DNA_FORM_NONE)
		..()
		src.pattern = dna
		if(!src.pattern)
			src.pattern = dna_unknown
		src.form = form
		if(form == DNA_FORM_BLOOD)
			src.accuracy_mult *= 0.75

	scan_display()
		if(HAS_FLAG(src.flags, IS_TRACE)) // Luminol regent
			// Color should be set to "#3399FF" to represent luminol. Not sure how to do this.
			return pattern.id + " (" + SPAN_HINT("blood traces") + ")"
		switch(src.form)
			if(DNA_FORM_NONE)
				return pattern.id
			if(DNA_FORM_BLOOD)
				return pattern.id + " ([SPAN_ALERT("blood")])"
			if(DNA_FORM_HAIR)
				return pattern.id + " (hair)"
			if(DNA_FORM_TISSUE)
				return pattern.id + " (tissue)"
			if(DNA_FORM_BONE)
				return pattern.id + " (bone)"
			if(DNA_FORM_SALIVA)
				return pattern.id + " (saliva)"
			if(DNA_FORM_VOMIT)
				return pattern.id + " (vomit)"
			else
				return pattern.id

	proc/is_same(datum/forensic_data/dna/other)
		return src.pattern == other.pattern && src.form == other.form

datum/forensic_data/projectile_hit // Bullet holes, laser marks, and the like (Replaced by notes for now)
	accuracy_mult = 1
	var/datum/forensic_id/proj_id = null // Which bullet created this, if it still exists
	var/turf/start_turf // Where the projectile was fired / last deflected
	var/turf/hit_turf // Where it was when it hit
	var/impact_type = 0 // What the projectile did to the crime scene. Pass through, bounce, burn marks, etc.
	var/deflection_angle = 0 // What direction did the projectile leave (if relevant)
	var/cone_of_tolerance = 10 // Base accuracy in determining the angle of the bullet in degrees

	scan_display()
		var/scan_text = "Bullet ID: [proj_id.id]"
		switch(src.impact_type)
			if(PROJ_BULLET_THROUGH)
				return scan_text
			if(PROJ_BULLET_EMBEDDED)
				return scan_text
			if(PROJ_BULLET_BOUNCE)
				return scan_text
			if(PROJ_LASER_BURN_MARK)
				return scan_text
			else
				return "Dev Coding Error: Impact type missing"

	// Bullet Obj
		// Rifling, or which barrel the bullet came from
		// Deformation, how the bullet changed (flattened, dented, fragmentation)
	// Footprint
		// The two footprint ids
		// The original direction?

datum/forensic_data/adminprint
	accuracy_mult = 0
	var/client/client

	New(var/client/print_client)
		..()
		src.client = print_client

	scan_display()
		var/p_name = "Test: [client.ckey]"
		return p_name

	proc/is_same(datum/forensic_data/adminprint/other)
		return src.client == other.client


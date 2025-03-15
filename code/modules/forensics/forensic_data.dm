estimate_counter
// Note: multiple forensic_holders should not share forensic_data, each should have their own instance of the evidence

/datum/forensic_data
	var/category = FORENSIC_GROUP_NONE
	var/time_start = 0 // What time the evidence was first applied, or 0 if not relavent
	var/time_end = 0 // When the evidence was most recently applied
	var/perc_offset = 0 // Error offset multiplier for time estimations
	var/accuracy_mult = 1 // Individual accuracy multiplier for this piece of evidence
	var/flags = 0
	// var/user = null // The player responsible for this evidence (for admins)
	New()
		..()
		src.time_start = TIME
		src.time_end = time_start
		src.perc_offset = (rand() - 0.5) * 2
		src.accuracy_mult *= ((rand() - 0.5) * 0.15) + 1
	proc/get_text() // The text to display when scanned
		return ""
	proc/should_remove(var/remove_flags) // Should this evidence be removed?
		var/remove = HAS_ANY_FLAGS(src.flags & (REMOVABLE_ALL & !REMOVABLE_HEAL), remove_flags)
		remove |= HAS_ALL_FLAGS(src.flags & REMOVABLE_HEAL, remove_flags & REMOVABLE_HEAL) // Need full healing to remove
		return remove
	proc/mark_as_junk()
		flags = flags | IS_JUNK
	proc/get_copy()
		return null

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


/datum/forensic_data/basic // Evidence that can just be stored as a single ID. Flags not included.
	var/static/datum/forensic_display/disp_empty = new("@F")
	var/datum/forensic_id/evidence = null
	var/datum/forensic_display/display = null

	New(var/datum/forensic_id/id, var/datum/forensic_display/disp = disp_empty, var/flags = 0)
		..()
		src.evidence = id
		src.display = disp
		src.flags = flags

	get_text()
		var/scan_text = replacetext(display.display_text, "@F", evidence.id)
		return scan_text

	get_copy()
		var/datum/forensic_data/basic/c_data = new(src.evidence, src.display, src.flags)
		c_data.category = src.category
		c_data.accuracy_mult = src.accuracy_mult
		c_data.time_start = src.time_start
		c_data.time_end = src.time_end
		c_data.perc_offset = src.perc_offset
		return c_data

/datum/forensic_data/multi // Two or three different pieces of evidence that are linked together. Flags not included.
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
	get_text()
		var/scan_text = display.display_text
		if(!evidence_A)
			scan_text = replacetextEx(scan_text, "@A", "")
		else
			scan_text = replacetextEx(scan_text, "@A", evidence_A.id)
		if(!evidence_B)
			scan_text = replacetextEx(scan_text, "@B", "")
		else if(mirror_B)
			scan_text = replacetextEx(scan_text, "@B", get_retina_mirror(evidence_B.id))
		else
			scan_text = replacetextEx(scan_text, "@B", evidence_B.id)
		if(!evidence_C)
			scan_text = replacetextEx(scan_text, "@C", "")
		else
			scan_text = replacetextEx(scan_text, "@C", evidence_C.id)
		return scan_text

	get_copy()
		var/datum/forensic_data/multi/c_data = new(src.evidence_A, src.evidence_B, src.evidence_C, src.display)
		c_data.category = src.category
		c_data.flags = src.flags
		c_data.time_start = src.time_start
		c_data.time_end = src.time_end
		c_data.accuracy_mult = src.accuracy_mult
		c_data.perc_offset = src.perc_offset
		return c_data

	proc/is_same(datum/forensic_data/multi/other)
		return src.evidence_A == other.evidence_A && src.evidence_B == other.evidence_B && src.evidence_C == other.evidence_C

/*
/datum/forensic_data/value // Forensic data that holds a value to be incremented
	// Example: counter for the number of times an item has been used
	var/datum/forensic_id/label // Both an identifier and a label for this value when displayed
	var/value = 0

	New(var/datum/forensic_id/label, var/value_init)
		src.label = label
		src.value = value_init
		..()

	get_text()
		// return estimate_counter(label.id, value, src.accuracy)
		return "[capitalize(label.id)]: [value]"

	get_copy()
		var/datum/forensic_data/value/c_data = new(src.label, src.value)
		return c_data

	proc/is_same(datum/forensic_data/value/other)
		return src.label == other.label

	proc/estimate_counter(var/text, var/actual, var/accuracy, var/offset)
		if(actual <= 0)
			return "[text]: [actual]"

		var/note = null
		if(accuracy < 0 || accuracy > FORENSIC_BASE_ACCURACY)
			accuracy = FORENSIC_BASE_ACCURACY
		var/high_est = round(actual + (actual * accuracy * offset))
		var/low_est = max(0, round(actual - (actual * accuracy * (1 - offset))))
		if(high_est == low_est)
			note = "[text]: [actual]"
		else
			note = "[text]: [low_est] to [high_est]"
		return note
*/

/datum/forensic_data/text
	var/forensic_text

	New(var/f_text = "", var/flags = 0)
		..()
		src.forensic_text = f_text
		src.flags = flags

	get_text()
		return forensic_text

	get_copy()
		var/datum/forensic_data/text/t_data = new(src.forensic_text, src.flags)
		t_data.category = src.category
		t_data.time_start = src.time_start
		t_data.time_end = src.time_end
		t_data.accuracy_mult = src.accuracy_mult
		t_data.perc_offset = src.perc_offset
		return t_data

	proc/is_same(datum/forensic_data/text/other)
		return src.forensic_text == other.forensic_text

/datum/forensic_data/fingerprint // An individual fingerprint applied to an item
	flags = REMOVABLE_CLEANING
	var/datum/forensic_id/print = null // The original fingerprint
	var/datum/forensic_id/glove_print = null // The glove fibres & ID
	var/datum/forensic_id/print_mask = null // The mask that the gloves apply to the print

	get_text()
		var/print = get_fingerprint()
		var/fibers = get_fibers()
		if(print && fibers)
			if(!src.print_mask)
				print = SPAN_SUBTLE(print)
			return "([print]) [fibers]"
		return print + fibers

	get_copy()
		var/datum/forensic_data/fingerprint/c_data = new()
		c_data.category = src.category
		c_data.print = src.print
		c_data.glove_print = src.glove_print
		c_data.print_mask = src.print_mask
		c_data.flags = src.flags
		c_data.time_start = src.time_start
		c_data.time_end = src.time_end
		c_data.accuracy_mult = src.accuracy_mult
		c_data.perc_offset = src.perc_offset
		return c_data

	proc/get_fingerprint()
		if(!src.print)
			return ""
		if(!src.print_mask)
			return src.print.id
		var/fp = ""
		for(var/i=1; i<=length(src.print_mask.id); i++)
			var/char = copytext(src.print_mask.id, i, i+1)
			if(is_hex(char))
				var/index = hex2num(char) + 1
				index += floor(index / 4)
				fp += copytext(src.print.id, index, index + 1)
			else
				fp += char
		return fp

	proc/get_fibers()
		if(!src.glove_print)
			return ""
		return glove_print.id

	proc/is_same(datum/forensic_data/fingerprint/other)
		return src.print == other.print && src.glove_print == other.glove_print

/datum/forensic_data/dna // An individual dna sample
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
		switch(src.form)
			if(DNA_FORM_BLOOD)
				src.accuracy_mult *= 0.75
			if(DNA_FORM_HAIR)
				src.accuracy_mult *= 1.25
			if(DNA_FORM_BONE)
				src.accuracy_mult *= 1.5
			if(DNA_FORM_VOMIT)
				src.accuracy_mult *= 0.8

	get_text()
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

	get_copy()
		var/datum/forensic_data/dna/c_data = new(src.pattern, src.form)
		c_data.category = src.category
		c_data.flags = src.flags
		c_data.time_start = src.time_start
		c_data.time_end = src.time_end
		c_data.accuracy_mult = src.accuracy_mult
		c_data.perc_offset = src.perc_offset
		return c_data

	proc/is_same(datum/forensic_data/dna/other)
		return src.pattern == other.pattern && src.form == other.form

/datum/forensic_data/projectile_hit // Bullet holes, laser marks, and the like (Replaced by notes for now)
	accuracy_mult = 1
	var/datum/forensic_id/proj_id = null // Which bullet created this, if it still exists
	var/turf/start_turf // Where the projectile was fired / last deflected
	var/turf/hit_turf // Where it was when it hit
	var/impact_type = 0 // What the projectile did to the crime scene. Pass through, bounce, burn marks, etc.
	var/deflection_angle = 0 // What direction did the projectile leave (if relevant)
	var/cone_of_tolerance = 10 // Base accuracy in determining the angle of the bullet in degrees

	get_text()
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

	get_copy()
		var/datum/forensic_data/projectile_hit/c_data = new()
		c_data.category = src.category
		c_data.proj_id = src.proj_id
		c_data.start_turf = src.start_turf
		c_data.hit_turf = src.hit_turf
		c_data.impact_type = src.impact_type
		c_data.deflection_angle = src.deflection_angle
		c_data.cone_of_tolerance = src.cone_of_tolerance
		c_data.flags = src.flags
		c_data.time_start = src.time_start
		c_data.time_end = src.time_end
		c_data.accuracy_mult = src.accuracy_mult
		c_data.perc_offset = src.perc_offset
		return c_data

	// Bullet Obj
		// Rifling, or which barrel the bullet came from
		// Deformation, how the bullet changed (flattened, dented, fragmentation)
	// Footprint
		// The two footprint ids
		// The original direction?

/proc/estimate_counter(var/text, var/actual, var/accuracy, var/offset)
	if(actual <= 0)
		return "[text]: [actual]"

	var/note = null
	if(accuracy < 0 || accuracy > FORENSIC_BASE_ACCURACY)
		accuracy = FORENSIC_BASE_ACCURACY
	var/high_est = round(actual + (actual * accuracy * offset))
	var/low_est = max(0, round(actual - (actual * accuracy * (1 - offset))))
	if(high_est == low_est)
		note = "[text]: [actual]"
	else
		note = "[text]: [low_est] to [high_est]"
	return note

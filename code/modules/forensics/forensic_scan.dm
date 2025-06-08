
/datum/forensic_scan
	var/datum/forensic_holder/scan_holder = new() //! Stores data that the scanner was able to obtain
	var/scan_time = 0 //! The time that the scan was performed

	New()
		..()
		src.scan_time = TIME

	///
	proc/add_text(var/text, var/text_group = FORENSIC_GROUP_NOTES)
		return

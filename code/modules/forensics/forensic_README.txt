
---------- What is what? ----------
	datum/forensic_id:
		- A specific forensic ID (such as a specific fingerprint pattern). Passed by reference.
		- Use register_id(text) to ensure that an ID is unique. It is the reference that matters here.

	datum/forensic_data:
		- A specific piece of evidence that was left behind (such as an individual fingerprint)
		- Should normally contain the "real" data, which could then be manipulated with a mask or such
			- Exception is data created from scans, which should be from the POV of the scanner
		- Should not be shared with other groups or holders. Use get_copy() instead.

	datum/forensic_group:
		- A collection of forensic evidence that follows the same rules (all the physical fingerprints on an object)
		- Only one type of group per forensic_holder
			- Groups were originally created with the intent that you could have multiple of the same type in a single forensic holder
			- However that kind of functionality can now be better achieved by combining/managing multiple forensic holders
			- Pointing this out so that their necessity can be debated

	datum/forensic_holder:
		- All the forensic evidence on an object, or in some cases multiple objects (all Bibles share the same forensic_holder!)
		- You can also create a variable of type forensic_holder if you want multiple sets of forensics informations
			- Use on_forensic_scan(var/.../scan_builder) to control how the scan is performed

	datum/forensic_scan_builder:
		- The builder determines how your forensics is scanned and presented
		- on_forensic_scan(var/.../scan_builder) is called before any data has been gathered
			- You can take that opportunity to change the scanned forensic_holder or add an additional one as a seperate region
			- Can add notes / additional data during scanning
			- Can add other forensic_holders to be scanned, or scan a different atom instead of this one

---------- How to... ----------
	How to leave evidence behind:
		- Create a new forensic_data with the information that you want to place
			- In most cases you will need one or more forensic_id's from whatever is leaving the evidence
			- If you want a repeatable text string as an ID, you can use register_id(text)
			- For creating an ID, the forensic_id file has some useful procs for creating various patterns
		- Use add_evidence() on the atom you want to place the data on

	How to create a new type of evidence
		- First check if one of the existing evidence types will do
			- FORENSIC_GROUP_NOTES is useful for simple binary information
		- If not, you need to create a new type of forensic_group
			- The group's category needs a unique FORENSIC_GROUP_XXX number
			- Add the group to the forensic_group_create() proc (until someone points out a better solution to that)
		- Probably want a forensic_data datum to hold your evidence
			- Can use basic/multi forensic_data datums and/or their respective primary groups in most cases
			- If those options aren't ideal, then create your own

	How to manage multiple forensic holders
		- Use holder.copy_evidence(target_holder) to combine or create copies of forensic holders
		- on_forensic_scan(var/.../scan_builder)
			- Use "add_holder(holder, text_title)" in forensic_scan_builder to scan multiple forensic holders separately
			- Use "replace_holder(holder)" or "replace_scan_target(atom)" to scan something else entirely


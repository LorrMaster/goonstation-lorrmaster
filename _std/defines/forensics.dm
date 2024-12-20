
#define FORENSIC_GROUP_NONE 0
#define FORENSIC_GROUP_NOTE 1
#define FORENSIC_GROUP_FINGERPRINT 2
#define FORENSIC_GROUP_DNA 3
#define FORENSIC_GROUP_SCAN 4
#define FORENSIC_GROUP_COMPUTER_LOG 5
#define FORENSIC_GROUP_SHOES 6
#define FORENSIC_GROUP_RETINA 7
#define FORENSIC_GROUP_HEALTH_FLOOR 8

/proc/forensic_group_create(var/category, var/area) // Create a new group from its unique variable
	// Is there a better way to do this? IDK.
	var/datum/forensic_group/G
	switch(category)
		if(FORENSIC_GROUP_NOTE)
			G = new/datum/forensic_group/notes
		if(FORENSIC_GROUP_FINGERPRINT)
			G = new/datum/forensic_group/fingerprints
		if(FORENSIC_GROUP_DNA)
			G = new/datum/forensic_group/dna
		if(FORENSIC_GROUP_SCAN)
			G = new/datum/forensic_group/basic_list/scanner
		if(FORENSIC_GROUP_SHOES)
			G = new/datum/forensic_group/basic_list/footprints
		if(FORENSIC_GROUP_RETINA)
			G = new/datum/forensic_group/double_list/retinas
		if(FORENSIC_GROUP_HEALTH_FLOOR)
			G = new/datum/forensic_group/double_list/log_health_floor
	G.area = area
	return G

#define IS_HIDDEN (1 << 1) // If true, only admins can see this evidence
#define IS_JUNK (1 << 2) // If true, this evidence is fake / planted (and should be ignored by admins)
#define REMOVABLE_CLEANING (1 << 3) // Can this evidence be washed away?
#define REMOVABLE_DATA (1 << 4) // Can this evidence be deleted from a computer?

#define DNA_FORM_NONE 1
#define DNA_FORM_BLOOD 2
#define DNA_FORM_HAIR 3
#define DNA_FORM_TISSUE 4
#define DNA_FORM_BONE 5
#define DNA_FORM_SALIVA 6

#define HEADER_NOTES "Notes"
#define HEADER_FINGERPRINTS "Fingerprints"
#define HEADER_DNA "DNA Samples"

#define CHAR_LIST_UPPER list("A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z")
#define CHAR_LIST_LOWER list("a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z")
#define CHAR_LIST_NUM list("0","1","2","3","4","5","6","7","8","9")
#define CHAR_LIST_SYMBOLS list("#","_","%","&","+","=","-") // "<", ">"
#define CHAR_LIST_HEX list("0","1","2","3","4","5","6","7","8","9","A","B","C","D","E","F")

// Remove letters that can be confused with numbers at a glance
#define CHAR_LIST_UPPER_LIMIT CHAR_LIST_UPPER - list("D","I","O","Q")
#define CHAR_LIST_LOWER_LIMIT CHAR_LIST_LOWER - list("i","j","l","o")

// chars_fingerprint is limited to 'round-ish' letters (with a few exceptions)
#define CHAR_LIST_FINGERPRINT list("a","b","c","d","e","g","n","o","p","r","s","u","v","x","y")
#define CHAR_LIST_FIBERS list("c","f","h","i","j","k","l","n","o","r","s","t","u","v","y","z")

#define CHAR_LIST_RETINA_L list("(","{",@"[","|") // ("(","{",@"[","|","<",@"/",@"\")
#define CHAR_LIST_RETINA_R list(")","}",@"]","|") // (")","}",@"]","|",">",@"\",@"/")

#define CHAR_LIST_RETINA_CENTER list("a","c","C","D","e","Q","u","U","v","V","0")
#define CHAR_LIST_RETINA_CAT list("|","i","I","j","J","k","l","!",":",";")
#define CHAR_LIST_RETINA_COW list("-","=","~","m","M","w","W")
#define CHAR_LIST_RETINA_SYNTH list("b","d","p","P","q")
#define CHAR_LIST_RETINA_ARTIFACT list("Y","H","K","A")

//-----------------------| Footprints |------------------
// Leg: sllll
// arm: sll
// Synthetic Leg: lllll
// Flippers: sssslll
// Shackles: =-(shoe id)-=
//--------------------| Fingerprints |--------------
// Changling arms: letters+symbols (different for each arm)
// Cyborg light: numbers
// Cyborg standard: hex
//--------------------| Serial Numbers |--------------
// Cyborg: S# XXXX-XXXX-XXXX-XXXX
// Items: XXXX-XXXX
// -----------------------| Tails |----------------------
// Tails should lean towards some repition (pick 3, or something)
// Tail Thin: <>-=+o,
// Tail Fluffy: K,O,H, ???: (),{},[],
// Tail End: (Tail Center) + (E,H,K,3,)
// +>>>o>>- | oKHOHKHK+

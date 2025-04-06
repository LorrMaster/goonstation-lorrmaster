/*
TODO:
 - Fix dna sample duplicates
 - Remove & replace all the old forensics stuff in general
 - Contraband
 - Take another look at autopsy implementation
 - Temperary evidence disable?
 - admin scans

Bugs:
 - Forensics does not carry over to final stage of ship construction
 - Blood time issues?
 - Check if spamming forensic scanner leads to bugs?
 - Scanning storage message removal. Low priority.
 - 

Lower Priority
 - Forensic_holder starts as null?
 - Forensic scanner emag effect?
 - DNA scramblers change DNA and fingerprints of regrown limbs, but not the current ones
 - Leave behind hair while in pods, bed, barber, etc
 - Go through machinery for potential forensic notes to add
	- Use limb/organ on item to place evidence (arm, leg(s), head, eye(s))
 - Bullet holes, burn marks from lasers (include goggles for laser eyes)
 - Hold towels / handkerchief to prevent fingerprints
 - Evidence for stackables
 	- Attach cleanables to floor tiles
 - Photographic Analysis, Audio Analysis (detect whispers), types of dust
 - Reagents
 	- Luminol should glow and work on mobs/turf
		- Rework luminol timer.
	- Hairgrowium: Hair sample accuracy x0.5
		- Super Hairgrowium: Hair sample perfect accuracy
		- Omega Hairgrownium: ???
	- Black Powder: Scan stickers on items?
	- Cryostylane: ???
	- Charcoal: Burn marks source
	- Magnesium Chloride: Remove ice?
	- Unstable Mutagen: Mess with DNA samples
	- Mutadone: Restore DNA samples damaged by unstable mutagen
	- Stable Mutagen + blood: Replace all DNA samples with the blood's DNA
	- Marsh test (nitric acid / zinc)
	- Necroni: Show a dead body's last words


 - Damage Sources
	- Radiation: Randomized? Variable based on intensity?
	- Vacuum suffocation: ???
	- Non-vacuum suffocation: Depends on gas
	- Burn marks: Explosion / fire evidence lead?
	- Tissue damage/reaction
	- Brute damage
	- Pathogens
*/

// Notes for various stuff in the detective office?
// Done: Deerstalker, det scanner, cig box
// Detective hat, VR goggles, Detective Shoes, Detective coat, Winter coat, Detective's headset
// 0.38 ammo, Revolver, Luminol grenades, Ceiling fan, Detective Computer, Alcohol 1, Det Closet

// List of types of organ damage. I don't know which, if any, make sense.
// Phlebitis, Fibrosis, Pulmonary edema, Inflammation

#define FORENSIC_GROUP_NONE 0
#define FORENSIC_GROUP_ADMINPRINT 1 // unused
#define FORENSIC_GROUP_PRODUCER 2 // Hold data that this object creates. For the fingerprinter to find.
#define FORENSIC_GROUP_NOTE 3 // Basically a misc section
#define FORENSIC_GROUP_FINGERPRINT 4
#define FORENSIC_GROUP_DNA 5
#define FORENSIC_GROUP_SCAN 6 // Scanner particles
#define FORENSIC_GROUP_COMPUTER_LOG 7
#define FORENSIC_GROUP_TRACKS 8 // Footprints and the like
#define FORENSIC_GROUP_RETINA 9
#define FORENSIC_GROUP_HEALTH_FLOOR 10 // DNA + Footprints
#define FORENSIC_GROUP_HEALTH_ANALYZER 11 // DNA + retina scan
#define FORENSIC_GROUP_SLEUTH_COLOR 12 // Pug sleuthing
#define FORENSIC_GROUP_PROJ_HIT 13
#define FORENSIC_GROUP_DAMAGE 14 // Anything that can be categorized under injuries, data corruption, or breakages
#define FORENSIC_GROUP_POLLEN 15 // Pollen, spores
#define FORENSIC_GROUP_GENE_BOOTH 16 // DNA + Number of genes bought
// #define FORENSIC_GROUP_SEC_SCANNER 17 // Footprints + Max contraband detected

/proc/forensic_group_create(var/category) // Create a new group from its unique variable
	// Is there a better way to do this? IDK
	var/datum/forensic_group/G
	switch(category)
		if(FORENSIC_GROUP_NOTE) G = new/datum/forensic_group/notes
		if(FORENSIC_GROUP_FINGERPRINT) G = new/datum/forensic_group/fingerprints
		if(FORENSIC_GROUP_DNA) G = new/datum/forensic_group/dna
		if(FORENSIC_GROUP_SCAN) G = new/datum/forensic_group/basic_list/scanner
		if(FORENSIC_GROUP_TRACKS) G = new/datum/forensic_group/multi_list/footprints
		if(FORENSIC_GROUP_RETINA) G = new/datum/forensic_group/multi_list/retinas
		if(FORENSIC_GROUP_HEALTH_FLOOR) G = new/datum/forensic_group/multi_list/log_health_floor
		if(FORENSIC_GROUP_HEALTH_ANALYZER) G = new/datum/forensic_group/multi_list/log_health_analyzer
		if(FORENSIC_GROUP_SLEUTH_COLOR) G = new/datum/forensic_group/basic_list/sleuth_color
		if(FORENSIC_GROUP_DAMAGE) G = new/datum/forensic_group/basic_list/damage
		if(FORENSIC_GROUP_POLLEN) G = new/datum/forensic_group/basic_list/pollen
		if(FORENSIC_GROUP_GENE_BOOTH) G = new/datum/forensic_group/basic_list/gene_booth
	return G

#define IS_HIDDEN (1 << 1) // Only admins can see this evidence
#define IS_JUNK (1 << 2) // This evidence is fake / planted (and should be ignored by admins)
#define IS_TRACE (1 << 3) // Forensics scanners cannot detect this evidence by default
// #define CANNOT_PLANT (1 << 4) // Fingerprinter cannot read this
#define REMOVABLE_CLEANING (1 << 5) // Can this evidence be washed away?
#define REMOVABLE_DATA (1 << 6) // Can this evidence be deleted from a computer?
#define REMOVABLE_REPAIR (1 << 7) // Can this evidence be fixed up
#define REMOVABLE_HEAL_BRUTE (1 << 8) // Can this evidence be healed
#define REMOVABLE_HEAL_BURN (1 << 9)
#define REMOVABLE_HEAL_TOXIN (1 << 10)
#define REMOVABLE_HEAL_OXYGEN (1 << 11)
// #define REMOVABLE_TIME (1 << 12) // Does this evidence only last for a limited amount of time?
// #define REMOVABLE_HEAL_HOLD (1 << 12)
#define REMOVABLE_HEAL REMOVABLE_HEAL_BRUTE | REMOVABLE_HEAL_BURN | REMOVABLE_HEAL_TOXIN | REMOVABLE_HEAL_OXYGEN
#define REMOVABLE_ALL REMOVABLE_CLEANING | REMOVABLE_DATA | REMOVABLE_REPAIR | REMOVABLE_HEAL

#define FORENSIC_BASE_ACCURACY 0.35 // Base modifier for how accurate timestamp estimates are
#define FORENSIC_HEAL_THRESHOLD 5

#define FORENSIC_VALUE_IGNORE 1 // When duplicate evidence is added, how will the evidence value be affected?
#define FORENSIC_VALUE_SUM 2
#define FORENSIC_VALUE_MULT 3
#define FORENSIC_VALUE_MAX 4
#define FORENSIC_VALUE_MIN 5

#define DNA_FORM_NONE 1
#define DNA_FORM_BLOOD 2
#define DNA_FORM_HAIR 3
#define DNA_FORM_TISSUE 4
#define DNA_FORM_BONE 5
#define DNA_FORM_SALIVA 6
#define DNA_FORM_VOMIT 7

#define PROJ_BULLET_THROUGH 1
#define PROJ_BULLET_EMBEDDED 2
#define PROJ_BULLET_BOUNCE 3
#define PROJ_LASER_BURN_MARK 4
#define PROJ_LASER_REFLECT 5

#define HEADER_NOTES "Notes"
#define HEADER_FINGERPRINTS "Fingerprints"
#define HEADER_DNA "DNA Samples"
#define HEADER_SCANNER "Scan Particles"
#define HEADER_DAMAGE "Damage"
#define HEADER_HEALTH_FLOOR "Scan Log: DNA | Footprints"
#define HEADER_HEALTH_ANALYZER "Scan Log: DNA | Retina Scan"
#define HEADER_TRACKS "Footprints"
#define HEADER_RETINA "Retina Scans"
#define HEADER_POLLEN "Palynomorphs"
#define HEADER_GENE_BOOTH "Booth Log: DNA | Gene Counter"

#define CHAR_LIST_UPPER list("A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z")
#define CHAR_LIST_LOWER list("a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z")
#define CHAR_LIST_NUM list("0","1","2","3","4","5","6","7","8","9")
#define CHAR_LIST_SYMBOLS list("#","_","%","&","+","=","-","*","~") // "<", ">"
#define CHAR_LIST_HEX list("0","1","2","3","4","5","6","7","8","9","A","B","C","D","E","F")
// Remove letters that can be confused with numbers at a glance
#define CHAR_LIST_UPPER_LIMIT CHAR_LIST_UPPER - list("D","I","O","Q")
#define CHAR_LIST_LOWER_LIMIT CHAR_LIST_LOWER - list("i","j","l","o")

// chars_fingerprint are mostly 'round-ish' letters, chars_fibers are zig-zaggy letters
#define CHAR_LIST_FINGERPRINT list("a","b","c","d","e","g","n","o","p","q","r","s","u","v","x","y")
#define CHAR_LIST_FIBERS list("c","f","h","i","j","k","l","n","o","r","s","t","u","v","y","z")
#define CHAR_LIST_GUN list("=","=","=","=","=","-","-","-","0","8","U","V","C","S","#","_","%","&","+","*","~")
#define CHAR_LIST_BITE list("O","O","O","o","o","o","o","o","u","u","u","U","U","-","n","c","c","C","w","W","M","m","Y","Q","~","#","d","p","b","q")

#define CHAR_LIST_RETINA_L list("(","{",@"[","|") // ("(","{",@"[","|","<",@"/",@"\")
#define CHAR_LIST_RETINA_R list(")","}",@"]","|") // (")","}",@"]","|",">",@"\",@"/")

#define CHAR_LIST_RETINA_CENTER list("a","c","C","D","e","Q","u","U","v","V","0")
#define CHAR_LIST_RETINA_CAT list("|","i","I","j","J","k","!",":",";")
#define CHAR_LIST_RETINA_COW list("-","=","~","m","M","w","W")
#define CHAR_LIST_RETINA_SYNTH list("b","d","p","P","q")
#define CHAR_LIST_RETINA_ARTIFACT list("Y","H","K","A","E","F","R")

//--------------------| Fingerprints |--------------
// Changling arms: letters with repeat? (different for each arm)
//--------------------| Serial Numbers |--------------
// Cyborg: S# XXXX-XXXX-XXXX-XXXX
// Items: XXXX-XXXX

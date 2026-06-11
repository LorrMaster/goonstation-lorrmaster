#define ORGAN_BROKEN (1 << 0)
#define ORGAN_ROBOTIC (1 << 1)
#define ORGAN_PLANT (1 << 2)

/datum/component/organ
	dupe_mode = COMPONENT_DUPE_UNIQUE
	var/datum/organHolder/holder = null
	var/flags_organ = 0 //! Whether this organ is robotic, etc
	var/flags_surgery = SURGERY_NONE //! How to remove this organ via surgery
	var/region //! In which region is this organ supposed to be implanted? E.g. RIBS for the heart and lungs

	var/mob/doner_original = null
	var/datum/appearanceHolder/donor_appearance

	var/failure_disease = null		//! The organ failure disease associated with this organ. Not used for Heart atm.
	var/list/organ_abilities = null //! Abilities that this organ will give when attached somewhere

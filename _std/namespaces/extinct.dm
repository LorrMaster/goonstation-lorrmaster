CREATE_NAMESPACE(EXTINCT)

/// Used to give different body parts the same color when generating the creature
CREATE_NAMESPACE(EXTINCT, COLOR)
ADD_TO_NAMESPACE(EXTINCT, COLOR)(var/const/RANDOM = 0)
ADD_TO_NAMESPACE(EXTINCT, COLOR)(var/const/PRIMARY = 1)
ADD_TO_NAMESPACE(EXTINCT, COLOR)(var/const/SECONDARY = 2)
ADD_TO_NAMESPACE(EXTINCT, COLOR)(var/const/HIGHLIGHT = 3)
ADD_TO_NAMESPACE(EXTINCT, COLOR)(var/const/BLACK = 4)

/// Returns a random type of extinct niche that spawns the specified type of critter.
/// Used for cases where the critter is spawned without a specified species so you need to generate one that matches.
proc/extinct_niche_ofmobtype(var/mob_type)
	var/list/niches = concrete_typesof(/datum/extinct_niche)
	var/list/potential_niches = list()
	for(var/niche_type in niches)
		var/datum/extinct_niche/niche = niche_type
		if(initial(niche.critter_type) == mob_type)
			potential_niches += niche_type
	if(length(potential_niches) == 0)
		return null
	return pick(potential_niches)

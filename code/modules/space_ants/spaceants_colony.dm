
#define SPACEANT_CHAMBER_QUEEN = 1
#define SPACEANT_CHAMBER_FOOD = 2
#define SPACEANT_CHAMBER_EGG = 3
#define SPACEANT_CHAMBER_LARVA = 4
#define SPACEANT_CHAMBER_HIGHWAY = 5
#define SPACEANT_CHAMBER_DESTROYED = 6

// Temp scent system
#define SPACEANT_SCENT_NONE = 0
#define SPACEANT_SCENT_FOOD_THISWAY = 1

/datum/spaceant_colony
	var/alist/obj/reagent_dispensers/cleanable/chambers = list()

	proc/pathfind_colony(var/datum/spaceant_colony/origin, var/dest_chamber_type)
		return



/datum/spaceant_chamber
	var/datum/spaceant_colony/colony = null
	var/colony_dirs = 0 // directions that this colony exists in
	var/ant_count = 0 // The number of ants in this chamber
	var/scents = "test" // What the ants on this tile are doing
	var/scent_dirs = 0 // Directions that the scent is pointed towards, if any (Example: "Go north to find food")
	var/scent_strength = 0

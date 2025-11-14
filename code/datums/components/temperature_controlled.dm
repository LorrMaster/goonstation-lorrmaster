#define TEMP_CONTROL_HEATER 1
#define TEMP_CONTROL_COOLER 2
#define TEMP_CONTROL_NO_STACK 4 // If this is a heater/cooler, do not stack temperature if affected by another heater/cooler

TYPEINFO(/datum/component/temperature_controlled)
	initialization_args = list(
		ARG_INFO("controller", DATA_INPUT_REF, "Additional controller if this controller is inside another one.", null),
		ARG_INFO("temperature", DATA_INPUT_NUM, "Temperature this thing is being kept at.", T0C),
		ARG_INFO("flags", DATA_INPUT_BITFIELD, "Is this a heater, cooler, or neither.", 0),
	)

// Marks an atom as being maintained at a certain temperature.
/datum/component/temperature_controlled
	dupe_mode = COMPONENT_DUPE_UNIQUE_PASSARGS
	var/datum/component/temperature_controlled/controller = null
	var/temperature = T0C //! Controlled temperature if this is a heater/cooler
	var/flags = 0 //! Marks this as a heater/cooler

	Initialize(var/controller = null, var/temperature = T0C, var/flags = 0)
		..()
		if(!isatom(src.parent))
			return COMPONENT_INCOMPATIBLE
		src.controller = controller
		src.temperature = temperature
		src.flags = flags

	RegisterWithParent()
		for(var/atom/movable/AM in src.parent)
			src.control_temperature(AM)
		RegisterSignal(src.parent, COMSIG_ATOM_ENTERED, PROC_REF(control_temperature))

	UnregisterFromParent()
		UnregisterSignal(src.parent, COMSIG_ATOM_ENTERED)
		for(var/atom/movable/AM in src.parent)
			src.remove_control(AM)

	InheritComponent(var/datum/component/temperature_controlled/dup_comp, var/i_am_original, var/datum/component/temperature_controlled/controller, var/temperature, var/flags)
		if(!i_am_original)
			return
		if(src.is_controller())
			if(!HAS_FLAG(src.flags, TEMP_CONTROL_NO_STACK) && controller)
				src.temperature += controller.temperature
		else if(HAS_ANY_FLAGS(flags, TEMP_CONTROL_HEATER & TEMP_CONTROL_COOLER)) // Temperature controllers take priority
			src.temperature = temperature
			src.flags = flags
		return ..()

	proc/is_controller()
		return HAS_ANY_FLAGS(src.flags, TEMP_CONTROL_HEATER & TEMP_CONTROL_COOLER)

	proc/control_temperature(atom/old_loc, atom/movable/thing)
		if(!thing)
			return
		if(thing.loc != src.parent)
			return
		thing.AddComponent(/datum/component/temperature_controlled, src.temperature, FALSE)
		RegisterSignal(thing, COMSIG_MOVABLE_SET_LOC, PROC_REF(remove_control))

	proc/remove_control(var/atom/movable/thing)
		var/datum/component/temperature_controlled/temp_comp = thing.GetComponent(/datum/component/temperature_controlled)
		if(!temp_comp)
			return
		if(temp_comp.is_controller())
			return
		temp_comp.RemoveComponent()
		src.UnregisterSignal(thing, COMSIG_MOVABLE_SET_LOC)

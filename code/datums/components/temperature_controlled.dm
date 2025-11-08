TYPEINFO(/datum/component/temperature_controlled)
	initialization_args = list(
		ARG_INFO("temperature", DATA_INPUT_NUM, "Temperature this thing is being kept at.", T0C),
		ARG_INFO("is_controller", DATA_INPUT_BOOL, "Marks this thing as being a heater/cooler.", FALSE),
	)

// Component used by freezers to mark ice (or ice inside other storage) and prevent melting
/datum/component/temperature_controlled
	dupe_mode = COMPONENT_DUPE_UNIQUE_PASSARGS
	var/temperature = T0C //! Temperature this thing is marked as being kept at
	var/is_controller = FALSE //! Marks this as a heater/cooler

	Initialize(var/temperature = T0C, var/is_controller = FALSE)
		..()
		if(!isatom(src.parent))
			return COMPONENT_INCOMPATIBLE
		src.temperature = temperature
		src.is_controller = is_controller

	RegisterWithParent()
		for(var/atom/movable/AM in src.parent)
			src.control_temperature(AM)
		RegisterSignal(src.parent, COMSIG_ATOM_ENTERED, PROC_REF(control_temperature))

	UnregisterFromParent()
		UnregisterSignal(src.parent, COMSIG_ATOM_ENTERED)
		for(var/atom/movable/AM in src.parent)
			src.remove_control(AM)

	InheritComponent(var/datum/component/temperature_controlled/dup_comp, var/i_am_original, var/temperature, var/is_controller)
		if(!i_am_original)
			return
		if(!src.is_controller && is_controller) // Temperature controllers take priority
			src.temperature = temperature
			src.is_controller = is_controller
		return ..()

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
		if(temp_comp.is_controller)
			return
		temp_comp.RemoveComponent()
		src.UnregisterSignal(thing, COMSIG_MOVABLE_SET_LOC)

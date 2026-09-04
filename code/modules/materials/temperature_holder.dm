/// Get our psudo-scientific heat capacity for whatever this is
/atom/proc/calc_heat_capacity()
	var/datum/material/material = src.material
	if(!material)
		material = getMaterial("steel")
	var/density = material.getProperty("density")
	// Mass doesn't really exist, so we're just going to have to guesstimate a value
	var/mass = src.material_amt * density
	if(ismob(src))
		mass *= 10
	else if(isitem(src))
		var/obj/item/I = src
		mass *= I.w_class
	return mass * MATERIAL::SPECIFIC_HEAT_CAPACITY::STEEL // Specific heat capacity of steel for everyone!

/// Temperature holder
/datum/temperature_holder
	VAR_PROTECTED/temperature = T20C //! The current temperature
	VAR_PROTECTED/heat_flow_net = 0 //! How much heat is currently entering/leaving per second?
	VAR_PROTECTED/heat_flow_net_change = 0 //! Change in heat flow over time
	VAR_PROTECTED/heat_capacity = INFINITY //! How much heat (in joules) does it take to change the temperature by 1 Kelvin?
	VAR_PROTECTED/conductivity_mult = 1 //! How easily this thing transfers heat

	VAR_PROTECTED/time_update_last = 0 //! Time of the last update.
	/// Time that the info in this holder will become out-of-date and the modifiers will have to be reapplied.
	VAR_PROTECTED/time_update_modify = INFINITY
	VAR_PROTECTED/list/datum/temperature_modifier/modifiers = null

	New()
		. = ..()
		src.time_update_last = TIME

	proc/getTemperature()
		src.update()
		return src.temperature

	proc/addModifier(var/datum/temperature_modifier/modifier)
		if(!src.modifiers)
			src.modifiers = list()
		src.modifiers[modifier.source] = modifier

	proc/getModifier(var/source)
		RETURN_TYPE(/datum/temperature_modifier)
		if(!src.modifiers)
			return
		return src.modifiers[source]

	/// Our heat capacity has changed for some reason.
	proc/change_heat_capacity(var/amount)
		src.heat_capacity += amount

	proc/update(var/modifiers_changed)
		var/time = TIME
		var/time_change = time - src.time_update_last
		if((time_change == 0) && !modifiers_changed)
			return // Everything is already up-to-date

		var/heat_flow_current = src.heat_flow_net + (src.heat_flow_net_change * time_change)
		var/heat_change = ((src.heat_flow_net + heat_flow_current) / 2) * time_change
		src.temperature += heat_change / heat_capacity
		src.heat_flow_net = heat_flow_current

		src.time_update_last = time // Needs to be done BEFORE the modifiers get updated to avoid infinite update loops.
		if(time != time_update_modify && !modifiers_changed)
			return // Everything is up-to-date now
		src.time_update_modify = INFINITY
		for(var/datum/temperature_modifier/modifier in src.modifiers)
			modifier.modify(src)

// =============================================================================================================
// ===================================== Temperature Modifiers =================================================
// =============================================================================================================

ABSTRACT_TYPE(/datum/temperature_modifier)
/// Temperature modifiers tell the temperature holder how it will change in the future.
/// These SHOULD NOT change the current temperature.
/datum/temperature_modifier
	var/source //! The thing that is causing the temperature change.

	proc/modify(var/datum/temperature_holder/holder)
		return

/// These two holders are in contact with each other and will transfer heat between each other until reaching an equilibrium
/datum/temperature_modifier/transfer
	var/datum/temperature_holder/holderA = null
	var/datum/temperature_holder/holderB = null
	var/transfer_mult = 1

	modify(var/datum/temperature_holder/holder)
		var/datum/temperature_holder/other = holderA
		if(holderA == holder)
			other = holderB
		var/temp_this = holder.getTemperature()
		var/temp_other = other.getTemperature()
		var/temp_difference = temp_this - temp_other

/// Something is moving heat from one holder to another.
/datum/temperature_modifier/pump
	var/datum/temperature_holder/holder_source = null
	var/datum/temperature_holder/holder_dest = null
	var/pump_rate = 0 //! Amount of heat being pumped per second

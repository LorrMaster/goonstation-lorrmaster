/obj/item/weldingtool
	name = "weldingtool"
	desc = "A tool that, when turned on, uses fuel to emit a concentrated flame, welding metal together or slicing it apart."
	icon = 'icons/obj/items/tools/weldingtool.dmi'
	inhand_image_icon = 'icons/mob/inhand/tools/weldingtool.dmi'
	icon_state = "weldingtool-off"
	item_state = "weldingtool-off"

	var/icon_state_variant_suffix = null
	var/item_state_variant_suffix = null

	var/welding = FALSE
	flags = TABLEPASS | CONDUCT
	c_flags = ONBELT
	tool_flags = TOOL_WELDING
	force = 3
	throwforce = 5
	throw_speed = 1
	throw_range = 5
	health = 5
	w_class = W_CLASS_SMALL
	m_amt = 30
	g_amt = 30
	stamina_damage = 10
	stamina_cost = 18
	stamina_crit_chance = 0
	rand_pos = TRUE
	inventory_counter_enabled = TRUE
	burn_possible = FALSE
	var/fuel_capacity = 20

	New()
		..()
		if(src.fuel_capacity)
			src.create_reagents(src.fuel_capacity)
			src.reagents.add_reagent("fuel", src.fuel_capacity)
			src.inventory_counter.update_number(src.get_fuel())

		src.setItemSpecial(/datum/item_special/flame)

		var/datum/component/welding/weld_comp = src.AddComponent(/datum/component/welding, src, WELDER_TYPE_FUEL)
		src.AddComponent(/datum/component/loctargeting/simple_light, 255, 110, 135, 125, weld_comp.is_welding)
		// Welder + rods  -> Welder/Rods Assembly
		src.AddComponent(/datum/component/assembly, /obj/item/rods, PROC_REF(welder_rod_construction), TRUE)

// ----------------------- Assembly-procs -----------------------
	///Begin of the flamethrower assembly
	proc/welder_rod_construction(var/atom/to_combine_atom, var/mob/user)
		var/datum/component/welding/weld_comp = src.GetComponent(/datum/component/welding)
		if (weld_comp.is_welding)
			return
		boutput(user, SPAN_NOTICE("You attach the rod to the welding tool."))
		var/obj/item/rods/handled_rods = to_combine_atom
		handled_rods.add_fingerprint(user)
		user.u_equip(src)
		src.add_fingerprint(user)
		if(handled_rods.amount > 1)
			handled_rods = handled_rods.split_stack(1)
			handled_rods.add_fingerprint(user)
		else
			user.u_equip(handled_rods)
		var/obj/item/flamethrower_construction/new_construction = new /obj/item/flamethrower_construction(null, src, handled_rods, null)
		user.put_in_hand_or_drop(new_construction)
		return TRUE
// ----------------------- -------------- -----------------------


	examine()
		. = ..()
		if (src.fuel_capacity)
			. += "It has [src.get_fuel()] units of fuel left!"

	attack(mob/target, mob/user, def_zone, is_special = FALSE, params = null)
		if (is_special)
			return ..()
		if(ishuman(target))
			var/mob/living/carbon/human/H = target
			var/datum/component/welding/weld_comp = src.GetComponent(/datum/component/welding)
			if(!weld_comp.welder_surgery(H, user))
				return ..()

	afterattack(obj/O, mob/user)
		if ((istype(O, /obj/reagent_dispensers/fueltank) || istype(O, /obj/item/reagent_containers/food/drinks/fueltank)) && BOUNDS_DIST(src, O) == 0)
			if  (!O.reagents.total_volume)
				boutput(user, SPAN_ALERT("The [O.name] is empty!"))
				return
			if ("fuel" in O.reagents.reagent_list)
				O.reagents.trans_to(src, fuel_capacity, 1, do_fluid_react = TRUE, index = O.reagents.reagent_list.Find("fuel"))
				src.inventory_counter.update_number(get_fuel())
				boutput(user, SPAN_NOTICE("Welder refueled"))
				playsound(src.loc, 'sound/effects/zzzt.ogg', 50, 1, -6)
				return
			else
				src.inventory_counter.update_number(get_fuel())
		if (src.welding)
			use_fuel((ismob(O) || istype(O, /obj/blob) || istype(O, /obj/critter)) ? 2 : 0.2)
			if (get_fuel() <= 0)
				src.set_state(on = FALSE, user = user)
			var/turf/location = user.loc
			if (istype(location, /turf))
				location.hotspot_expose(700, 50, 1)
			if (istype(O, /turf))
				var/turf/target_turf = O
				target_turf.hotspot_expose(4000, 50, 1)
			if (O && !ismob(O) && O.reagents)
				boutput(user, SPAN_NOTICE("You heat \the [O.name]."))
				O.reagents.temperature_reagents(4000,50, 100, 100, 1)

	attack_self(mob/user as mob)
		src.firesource = !(src.firesource)
		tooltip_rebuild = TRUE
		src.set_state(on = !src.welding, user = user)

	blob_act(var/power)
		if (prob(power * 0.5))
			qdel(src)

	temperature_expose(datum/gas_mixture/air, exposed_temperature, exposed_volume, cannot_be_cooled = FALSE)
		if (exposed_temperature > 1000)
			return ..()

	firesource_interact()
		if (reagents.get_reagent_amount("fuel"))
			reagents.remove_reagent("fuel", 1)

	process()
		var/datum/component/welding/weld_comp = src.GetComponent(/datum/component/welding)
		weld_comp.weld_process()

	proc/get_fuel()
		var/datum/component/welding/weld_comp = src.GetComponent(/datum/component/welding)
		weld_comp.get_fuel()

	proc/use_fuel(var/amount)
		var/datum/component/welding/weld_comp = src.GetComponent(/datum/component/welding)
		weld_comp.use_fuel(amount)

	on_reagent_change(add)
		. = ..()
		src.inventory_counter.update_number(src.get_fuel())

#define EYE_DAMAGE_IMMUNE 2
#define EYE_DAMAGE_MINOR 1
#define EYE_DAMAGE_NORMAL 0
#define EYE_DAMAGE_EXTRA -1

	proc/eyecheck(mob/user as mob)
		var/datum/component/welding/weld_comp = src.GetComponent(/datum/component/welding)
		weld_comp.eyecheck(user)

#undef EYE_DAMAGE_IMMUNE
#undef EYE_DAMAGE_MINOR
#undef EYE_DAMAGE_NORMAL
#undef EYE_DAMAGE_EXTRA

	proc/attach_robopart(mob/living/carbon/human/H as mob, mob/living/carbon/user as mob, var/part)
		var/datum/component/welding/weld_comp = src.GetComponent(/datum/component/welding)
		weld_comp.attach_robopart(H, user, part)

	proc/try_weld(mob/user, var/fuel_amt = 2, var/use_amt = -1, var/noisy=1, var/burn_eyes=1)
		var/datum/component/welding/weld_comp = src.GetComponent(/datum/component/welding)
		weld_comp.try_weld(user, fuel_amt, use_amt, noisy, burn_eyes)

	/** Set the stats for the weldingtool and handles side effects when transitioning on->off or off->on
	  * `on` - TRUE for welding, FALSE for not welding
	  * `user` - mob toggling the welder, if applicable. Can be null. Currently only used to send chat feedback
	  */
	proc/set_state(on, mob/user)
		var/datum/component/welding/weld_comp = src.GetComponent(/datum/component/welding)
		weld_comp.set_state(on, user)


/obj/item/weldingtool/yellow
	desc = "A tool that, when turned on, uses fuel to emit a concentrated flame, welding metal together or slicing it apart, all while having a yellow handle."
	icon_state = "weldingtool-off-yellow"
	icon_state_variant_suffix = "-yellow"

/obj/item/weldingtool/grey
	desc = "A tool that, when turned on, uses fuel to emit a concentrated flame, welding metal together or slicing it apart, with a boring grey handle."
	icon_state = "weldingtool-off-grey"
	icon_state_variant_suffix = "-grey"

/obj/item/weldingtool/orange
	desc = "A tool that, when turned on, uses fuel to emit a concentrated flame, welding metal together or slicing it apart, with an added efficiently orange handle."
	icon_state = "weldingtool-off-orange"
	icon_state_variant_suffix = "-orange"

/obj/item/weldingtool/green
	desc = "A tool that, when turned on, uses fuel to emit a concentrated flame, welding metal together or slicing it apart, with a green handle."
	icon_state = "weldingtool-off-green"
	icon_state_variant_suffix = "-green"

/obj/item/weldingtool/purple
	desc = "A tool that, when turned on, uses fuel to emit a concentrated flame, welding metal together or slicing it apart, with an eccentric purple handle."
	icon_state = "weldingtool-off-purple"
	icon_state_variant_suffix = "-purple"


/obj/item/weldingtool/vr
	icon_state = "weldingtool-off-vr"
	icon_state_variant_suffix = "-vr"

/obj/item/weldingtool/high_cap
	name = "high-capacity weldingtool"
	fuel_capacity = 100

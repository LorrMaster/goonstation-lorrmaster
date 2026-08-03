#define WELDER_TYPE_INFINITE 1 // Unlimted fuel!
#define WELDER_TYPE_FUEL 2 // Fuel comes from fuel reagents
#define WELDER_TYPE_POWER 3 // Fuel comes from power cell

#define EYE_DAMAGE_IMMUNE 2
#define EYE_DAMAGE_MINOR 1
#define EYE_DAMAGE_NORMAL 0
#define EYE_DAMAGE_EXTRA -1

TYPEINFO(/datum/component/welding)
	initialization_args = list(
		ARG_INFO("fuel_container", DATA_INPUT_REF, "The item to get fuel from.", null),
		ARG_INFO("fuelType", DATA_INPUT_NUM, "Type of fuel being used.", WELDER_TYPE_INFINITE),
		ARG_INFO("fuelConversion", DATA_INPUT_NUM, "Fuel efficiency and/or unit conversion.", 1),
		ARG_INFO("isWelding", DATA_INPUT_BOOL, "Is the welder on.", FALSE),
	)

/datum/component/welding
	var/is_welding = FALSE //! Has the welder been lit?
	var/atom/fuel_container = null //! Where the fuel is getting used from, if anywhere
	var/fuel_type = WELDER_TYPE_INFINITE //! What is the welder being fueled with?
	var/fuel_conversion = 1 //! How efficient the welder is and/or convert to the proper units
	var/passive_fuel_consumption = 0.1 //! Fuel consumption while lit
	var/temperature = 700 KELVIN

	var/sound_ignite = 'sound/effects/welder_ignite.ogg'
	var/list/sound_noisey = list('sound/items/Welder.ogg', 'sound/items/Welder2.ogg')

	Initialize(fuel_container=null, fuelType=WELDER_TYPE_INFINITE, fuelConversion=1, isWelding=FALSE)
		..()
		src.fuel_container = fuel_container
		src.fuel_type = fuelType
		src.fuel_conversion = fuelConversion
		src.is_welding = isWelding

	/// Returns TRUE if state is sucessfully set. Should only be called by the welder item.
	proc/set_state(var/welding_state, mob/user)
		if(src.is_welding == welding_state)
			return FALSE
		src.is_welding = welding_state
		if(!src.is_welding)
			if(!src.fuel_container)
				return TRUE
			if (get_fuel() <= 0)
				if(user)
					boutput(user, SPAN_NOTICE("Need more fuel!"))
				src.is_welding = FALSE
				return FALSE
			SEND_SIGNAL(src.parent, COMSIG_LIGHT_ENABLE)
		else
			if(user)
				boutput(user, SPAN_NOTICE("Not welding anymore."))
			SEND_SIGNAL(src.fuel_container, COMSIG_LIGHT_DISABLE)
		return TRUE

	/// fuel_amount is how much fuel is needed to weld.
	/// use_amount is how much fuel is used per action.
	proc/try_weld(mob/user, var/fuel_amount = 2, var/use_amount = -1, var/noisy=1, var/burn_eyes=TRUE)
		if(!src.is_welding)
			return FALSE // not welding
		if(use_amount < 0)
			use_amount = fuel_amount
		if (src.get_fuel() < fuel_amount)
			boutput(user, SPAN_NOTICE("Need more fuel!"))
			return FALSE //welding, doesnt have fuel
		src.use_fuel(use_amount)
		if(noisy)
			playsound(user.loc, sound_noisey[noisy], 40, 1)
		if(burn_eyes)
			src.eyecheck(user)
		return TRUE //welding, has fuel

	/// Returns the amount of fuel/power in the welder
	proc/get_fuel()
		switch(src.fuel_type)
			if(WELDER_TYPE_INFINITE)
				return INFINITY
			if(WELDER_TYPE_FUEL)
				return src.fuel_container?.reagents?.get_reagent_amount("fuel")
			if(WELDER_TYPE_POWER)
				if(!src.fuel_container)
					return 0
				var/list/ret = list()
				if(SEND_SIGNAL(src.parent, COMSIG_CELL_CHECK_CHARGE, ret) & CELL_RETURNED_LIST)
					. = ret["charge"] / src.fuel_conversion
			else
				return 0

	proc/use_fuel(var/use_amount)
		if(!src.fuel_container || src.fuel_conversion == 0)
			return
		switch(src.fuel_type)
			if(WELDER_TYPE_FUEL)
				use_amount = min(get_fuel(), use_amount * src.fuel_conversion)
				if(src.fuel_container.reagents)
					src.fuel_container.reagents.remove_reagent("fuel", use_amount)
				src.fuel_container.inventory_counter.update_number(get_fuel())
			if(WELDER_TYPE_POWER)
				use_amount = min(get_fuel(), use_amount)
				use_amount *= src.fuel_conversion
				SEND_SIGNAL(src.parent, COMSIG_CELL_USE, use_amount)

	proc/eyecheck(mob/user as mob)
		if(user.isBlindImmune())
			return
		/// Checks eye protection; positive value for protecting eyes, negative for increasing damage (thermals)
		var/safety = EYE_DAMAGE_NORMAL
		if (ishuman(user))
			var/mob/living/carbon/human/H = user
			if (!H.sight_check()) //don't blind if we're already blind
				safety = EYE_DAMAGE_IMMUNE
			// we want to check for the thermals first so having a polarized eye doesn't protect you if you also have a thermal eye
			else if (istype(H.glasses, /obj/item/clothing/glasses/thermal) || H.eye_istype(/obj/item/organ/eye/cyber/thermal) || istype(H.glasses, /obj/item/clothing/glasses/nightvision) || H.eye_istype(/obj/item/organ/eye/cyber/nightvision))
				safety = EYE_DAMAGE_EXTRA
			else if (istype(H.head, /obj/item/clothing/head/helmet/welding))
				var/obj/item/clothing/head/helmet/welding/WH = H.head
				if(!WH.up)
					safety = EYE_DAMAGE_IMMUNE
				else
					safety = EYE_DAMAGE_NORMAL
			else if (istype(H.head, /obj/item/clothing/head/helmet/space/industrial))
				var/obj/item/clothing/head/helmet/space/industrial/helmet = H.head
				if (helmet.has_visor && helmet.visor_enabled)
					safety = EYE_DAMAGE_EXTRA
				else
					safety = EYE_DAMAGE_IMMUNE
			else if (istype(H.head, /obj/item/clothing/head/helmet/space))
				safety = EYE_DAMAGE_IMMUNE
			else if (istype(H.glasses, /obj/item/clothing/glasses/sunglasses) || H.eye_istype(/obj/item/organ/eye/cyber/sunglass))
				safety = EYE_DAMAGE_MINOR
		switch (safety)
			// IMMUNE means nothing happens

			if (EYE_DAMAGE_MINOR)
				boutput(user, SPAN_ALERT("Your eyes sting a little."))
				user.take_eye_damage(rand(1, 2))
			if (EYE_DAMAGE_NORMAL)
				boutput(user, SPAN_ALERT("Your eyes burn."))
				user.take_eye_damage(rand(2, 4))
			if (EYE_DAMAGE_EXTRA)
				boutput(user, SPAN_ALERT("<b>Your goggles intensify the welder's glow. Your eyes itch and burn severely.</b>"))
				user.change_eye_blurry(rand(12, 20))
				user.take_eye_damage(rand(12, 16))

	/// Called regularly while the welder is lit.
	proc/weld_process()
		if(!src.is_welding)
			return
		var/atom/location = src.parent.loc
		if (isturf(location))
			var/turf/T = location
			T.hotspot_expose(src.temperature, 5, electric = (src.fuel_type == WELDER_TYPE_POWER))
		if(src.fuel_type == WELDER_TYPE_INFINITE)
			return
		src.use_fuel(src.passive_fuel_consumption)
		if (!get_fuel())
			src.set_state(FALSE, ismob(src.parent.loc) ? src.parent.loc : null)

	proc/welder_attack(var/atom/target, var/mob/user)
		if(!src.is_welding)
			return

	proc/welder_surgery(var/mob/living/carbon/human/H, var/mob/user)
		if(H.bleeding || (H.organHolder?.back_op_stage > BACK_SURGERY_OPENED && user.zone_sel.selecting == "chest"))
			if(!src.cautery(H, user, 15))
				return FALSE
		else if(user.zone_sel.selecting != "chest" && user.zone_sel.selecting != "head" && H.limbs.vars[user.zone_sel.selecting])
			if(!(locate(/obj/machinery/optable, H.loc) && H.lying) && !(locate(/obj/table, H.loc) && (H.getStatusDuration("unconscious") || H.stat)) && !(H.reagents && H.reagents.get_reagent_amount("ethanol") > 10 && H == user))
				return FALSE
			switch(user.zone_sel.selecting)
				if("l_arm")
					if (istype(H.limbs.l_arm, /obj/item/parts/robot_parts) && H.limbs.l_arm.remove_stage > 0)
						attach_robopart("l_arm")
					else
						boutput(user, SPAN_ALERT("[H.name]'s left arm doesn't need welding on!"))
						return TRUE
				if("r_arm")
					if (istype(H.limbs.r_arm, /obj/item/parts/robot_parts) && H.limbs.r_arm.remove_stage > 0)
						attach_robopart("r_arm")
					else
						boutput(user, SPAN_ALERT("[H.name]'s right arm doesn't need welding on!"))
						return TRUE
				if("l_leg")
					if (istype(H.limbs.l_leg, /obj/item/parts/robot_parts) && H.limbs.l_leg.remove_stage > 0)
						attach_robopart("l_leg")
					else
						boutput(user, SPAN_ALERT("[H.name]'s left leg doesn't need welding on!"))
						return TRUE
				if("r_leg")
					if (istype(H.limbs.r_leg, /obj/item/parts/robot_parts) && H.limbs.r_leg.remove_stage > 0)
						attach_robopart("r_leg")
					else
						boutput(user, SPAN_ALERT("[H.name]'s right leg doesn't need welding on!"))
						return TRUE
				else return FALSE
		else return FALSE

	proc/attach_robopart(mob/living/carbon/human/H as mob, mob/living/carbon/user as mob, var/part)
		if (!istype(H) || !part || !H.bioHolder.HasEffect("loose_robot_[part]"))
			return

		if(!src.try_weld(user, 5))
			return
		H.TakeDamage("chest",0,20)
		if (prob(50))
			H.emote("scream")
		if(user)
			user.visible_message(SPAN_ALERT("[user.name] welds [H.name]'s robotic part to their stump with [src.parent]."), SPAN_ALERT("You weld [H.name]'s robotic part to their stump with [src.parent]."))
		H.bioHolder.RemoveEffect("loose_robot_[part]")
		return

/datum/component/welding/proc/cautery(var/mob/living/carbon/human/patient as mob, var/mob/surgeon as mob, var/damage as num)
	if(!ishuman(patient))
		return FALSE
	if(!surgeon)
		surgeon = patient
	if(!src.is_welding)
		surgeon.tri_message(patient, "<b>[surgeon]</b> tries to use [src.parent] on [patient == surgeon ? "[his_or_her(patient)]" : "[patient]'s"] incision, but [src.parent] isn't lit! Sheesh.",\
			"You try to use [src.parent] on [surgeon == patient ? "your" : "[patient]'s"] incision, but [src.parent] isn't lit! Sheesh.",\
			"[patient == surgeon ? "You try" : "<b>[surgeon]</b> tries"] to use [src.parent] on your incision, but [src.parent] isn't lit! Sheesh.")
			return FALSE
	if(patient.is_heat_resistant())
		patient.visible_message(SPAN_ALERT("<b>Nothing happens!</b>"))
		return FALSE

	if(!damage)
		damage = rand(5, 15)
	if(surgeon.bioHolder.HasEffect("clumsy") && prob(33))
		surgeon.visible_message(SPAN_ALERT("<b>[surgeon]</b> burns [him_or_her(surgeon)]self with [src.parent]!"),\
		SPAN_ALERT("You burn yourself with [src.parent]"))

		JOB_XP(surgeon, "Clown", 1)
		surgeon.changeStatus("knockdown", 4 SECONDS)
		random_burn_damage(surgeon, damage)
		return TRUE
	parent.add_fingerprint(surgeon)

	var/quick_surgery = FALSE
	if(surgeryCheck(patient, surgeon))
		quick_surgery = TRUE

	// ----- Cautery: Head -----
	if(surgeon.zone_sel.selecting == "head" && patient.organHolder?.head && patient.organHolder.head.op_stage > 0.0)
		random_burn_damage(patient, damage)
		if (quick_surgery)
			surgeon.tri_message(patient, SPAN_NOTICE("<b>[surgeon]</b> cauterizes the incision on [patient == surgeon ? "[his_or_her(patient)]" : "[patient]'s"] neck closed with [src.parent]."),\
				SPAN_NOTICE("You cauterize the incision on [surgeon == patient ? "your" : "[patient]'s"] neck closed with [src.parent]."),\
				SPAN_NOTICE("[patient == surgeon ? "You cauterize" : "<b>[surgeon]</b> cauterizes"] the incision on your neck closed with [src.parent]."))

			patient.organHolder.head.op_stage = 0
			if (patient.bleeding)
				repair_bleeding_damage(patient, 50, rand(1,3))
		else
			surgeon.tri_message(patient, SPAN_NOTICE("<b>[surgeon]</b> begins cauterizing the incision on [patient == surgeon ? "[his_or_her(patient)]" : "[patient]'s"] neck closed with [src.parent]."),\
				SPAN_NOTICE("You begin cauterizing the incision on [surgeon == patient ? "your" : "[patient]'s"] neck closed with [src.parent]."),\
				SPAN_NOTICE("[patient == surgeon ? "You begin" : "<b>[surgeon]</b> begins"] cauterizing incision on your neck closed with [src.parent]."))

			if (do_mob(patient, surgeon, max(100 - (damage * 2)), 0))
				surgeon.tri_message(patient, SPAN_NOTICE("<b>[surgeon]</b> cauterizes the incision on [patient == surgeon ? "[his_or_her(patient)]" : "[patient]'s"] neck closed with [src.parent]."),\
					SPAN_NOTICE("You cauterize the incision on [surgeon == patient ? "your" : "[patient]'s"] neck closed with [src.parent]."),\
					SPAN_NOTICE("[patient == surgeon ? "You cauterize" : "<b>[surgeon]</b> cauterizes"] the incision on your neck closed with [src.parent]."))

				patient.organHolder.head.op_stage = 0
				if (patient.bleeding)
					repair_bleeding_damage(patient, 50, rand(1,3))

			else
				surgeon.show_text("<b>You were interrupted!</b>", "red")
		return TRUE

	// ----- Cautery: Butt -----
	else if (surgeon.zone_sel.selecting == "chest" && patient.organHolder.back_op_stage > BACK_SURGERY_CLOSED)
		random_burn_damage(patient, damage)
		if (quick_surgery)
			surgeon.tri_message(patient, SPAN_NOTICE("<b>[surgeon]</b> cauterizes the incision on [patient == surgeon ? "[his_or_her(patient)]" : "[patient]'s"] butt closed with [src.parent]."),\
				SPAN_NOTICE("You cauterize the incision on [surgeon == patient ? "your" : "[patient]'s"] butt closed with [src.parent]."),\
				SPAN_NOTICE("[patient == surgeon ? "You cauterize" : "<b>[surgeon]</b> cauterizes"] the incision on your butt closed with [src.parent]."))

			patient.organHolder.back_op_stage = BACK_SURGERY_CLOSED
			if (patient.bleeding)
				repair_bleeding_damage(patient, 50, rand(1,3))
		else
			surgeon.tri_message(patient, SPAN_NOTICE("<b>[surgeon]</b> begins cauterizing the incision on [patient == surgeon ? "[his_or_her(patient)]" : "[patient]'s"] butt closed with [src.parent]."),\
				SPAN_NOTICE("You begin cauterizing the incision on [surgeon == patient ? "your" : "[patient]'s"] butt closed with [src.parent]."),\
				SPAN_NOTICE("[patient == surgeon ? "You begin" : "<b>[surgeon]</b> begins"] cauterizing incision on your butt closed with [src.parent]."))

			if (do_mob(patient, surgeon, max(100 - (damage * 2)), 0))
				surgeon.tri_message(patient, SPAN_NOTICE("<b>[surgeon]</b> cauterizes the incision on [patient == surgeon ? "[his_or_her(patient)]" : "[patient]'s"] butt closed with [src.parent]."),\
					SPAN_NOTICE("You cauterize the incision on [surgeon == patient ? "your" : "[patient]'s"] butt closed with [src.parent]."),\
					SPAN_NOTICE("[patient == surgeon ? "You cauterize" : "<b>[surgeon]</b> cauterizes"] the incision on your butt closed with [src.parent]."))

				patient.organHolder.back_op_stage = BACK_SURGERY_CLOSED
				if (patient.bleeding)
					repair_bleeding_damage(patient, 50, rand(1,3))
			else
				surgeon.show_text("<b>You were interrupted!</b>", "red")
		return TRUE

	// ----- Bleeding -----
	else if (patient.bleeding)
		random_burn_damage(patient, damage)
		if (quick_surgery)
			surgeon.tri_message(patient, SPAN_NOTICE("<b>[surgeon]</b> cauterizes [patient == surgeon ? "[his_or_her(patient)]" : "[patient]'s"] wounds closed with [src.parent]."),\
				SPAN_NOTICE("You cauterize [surgeon == patient ? "your" : "[patient]'s"] wounds closed with [src.parent]."),\
				SPAN_NOTICE("[patient == surgeon ? "You cauterizes" : "<b>[surgeon]</b> cauterizes"] your wounds closed with [src.parent]."))

			repair_bleeding_damage(patient, 100, 10)
		else
			surgeon.tri_message(patient, SPAN_NOTICE("<b>[surgeon]</b> begins cauterizing [patient == surgeon ? "[his_or_her(patient)]" : "[patient]'s"] wounds closed with [src.parent]."),\
				SPAN_NOTICE("You begin cauterizing [surgeon == patient ? "your" : "[patient]'s"] wounds closed with [src.parent]."),\
				SPAN_NOTICE("[patient == surgeon ? "You begin" : "<b>[surgeon]</b> begins"] cauterizing your wounds closed with [src.parent]."))

			var/dur = max(patient.bleeding * 2 - damage * 0.2, 0) SECONDS
			if (dur == 0)
				repair_bleeding_damage(patient, 100, 10)
			else
				SETUP_GENERIC_ACTIONBAR(patient, src.parent, dur, /datum/component/welding/proc/cauterize_wound, list(surgeon, patient), src.parent.icon, src.parent.icon_state, null,
					INTERRUPT_ACT | INTERRUPT_ACTION | INTERRUPT_MOVE | INTERRUPT_ATTACKED | INTERRUPT_STUNNED)
		return TRUE
	else
		return FALSE

/datum/component/welding/proc/cauterize_wound(mob/surgeon, mob/living/carbon/human/patient)
	surgeon.tri_message(patient, SPAN_NOTICE("<b>[surgeon]</b> cauterizes [patient == surgeon ? "[his_or_her(patient)]" : "[patient]'s"] wounds closed with [src.parent]."),
		SPAN_NOTICE("You cauterize [surgeon == patient ? "your" : "[patient]'s"] wounds closed with [src.parent]."),
		SPAN_NOTICE("[patient == surgeon ? "You cauterize" : "<b>[surgeon]</b> cauterizes"] your wounds closed with [src.parent]."))

	repair_bleeding_damage(patient, 100, 10)

#undef EYE_DAMAGE_IMMUNE
#undef EYE_DAMAGE_MINOR
#undef EYE_DAMAGE_NORMAL
#undef EYE_DAMAGE_EXTRA

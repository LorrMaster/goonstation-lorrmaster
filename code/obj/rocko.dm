#define ROCKO_ALT_MATERIAL_CHANCE 100

// CE's pet rock! A true hellburn companion
/obj/item/rocko
	name = "Rocko"
	icon = 'icons/obj/items/materials/rocks.dmi'
	icon_state = "rock1"
	w_class = W_CLASS_TINY
	force = 10
	throwforce = 15
	throw_range = 3
	material_amt = 10
	can_arcplate = FALSE
	uses_default_material_appearance = TRUE

	var/list/rocko_is
	var/smile = TRUE
	var/painted
	var/bright = FALSE
	var/mob/living/holder
	var/obj/item/clothing/head/hat
	var/material_desc = null
	var/rock_scale = 1.3
	var/rock_offset = -3

	New()
		. = ..()
		if(prob(20))
			src.bright = TRUE
		src.rocko_is = list("a great listener", "a good friend", "trustworthy", "wise", "sweet", "great at parties")
		src.hat = new /obj/item/clothing/head/helmet/hardhat(src)

		choose_rocko_material()
		setup_rocko_material()

		UpdateIcon()
		START_TRACKING_CAT(TR_CAT_PETS)
		START_TRACKING_CAT(TR_CAT_GHOST_OBSERVABLES)
		processing_items |= src

	disposing()
		processing_items -= src
		STOP_TRACKING_CAT(TR_CAT_PETS)
		STOP_TRACKING_CAT(TR_CAT_GHOST_OBSERVABLES)

		var/turf/where = get_turf(src)
		var/where_text = "Unknown (?, ?, ?)"
		if (where)
			where_text = "<b>[where.loc]</b> [showCoords(where.x, where.y, where.z, ghostjump=TRUE)]"
		message_ghosts("<b>[src.name]</b> has died in ([where_text]).")
		..()

	proc/can_mob_observe(mob/M)
		// ignore things we don't care about
		if(isnull(M.client))
			return FALSE

		var/view_chance = 0
		if(M.job == "Chief Engineer")
			view_chance += 2
			if(src.holder == M)
				view_chance += 5
		else if(M.job in list("Engineer"))
			view_chance += 1
			if(src.holder == M)
				view_chance += 1

		// whoa dude!
		if(M.reagents?.total_volume && (M.reagents.has_reagent("LSD") || M.reagents.has_reagent("lsd_bee") || M.reagents.has_reagent("psilocybin") || M.reagents?.has_reagent("bathsalts") || M.reagents?.has_reagent("THC")) )
			view_chance += 20
		if(M.hasStatus("drunk"))
			view_chance += 5

		return prob(view_chance)

	process()
		if(prob(95))
			return

		switch(pick( 200;1, 200;2, 50;3, 10;4, 100;5))
			if(1)
				emote("<B>[src]</B> winks.", "<I>winks</I>")
			if(2)
				if(holder) boutput(src.holder,"<B>[src]</B> feels warm.")
			if(3)
				emote("<B>[src]</B> whispers something about a hellburn.", "<I>whispers something about a hellburn</I>")
			if(4)
				emote("<B>[src]</B> rants about job site safety.", "<I>Goes on about job safety</I>")
			if(5)
				if (!src.holder)
					return
				src.say("We really need to do something about the [pick("captain", "head of personnel", "clown", "research director", "head of security", "medical director", "AI")].", atom_listeners_override = list(src.holder))

	emote(message, maptext_out)
		. = ..()

		var/list/mob/targets
		if(!src.holder)
			targets = viewers(src, null)
		else
			targets = list(src.holder)

		var/list/mob/recipients = list()
		for (var/mob/M as anything in targets)
			if(!src.can_mob_observe(M))
				continue

			recipients += M
			M.show_message(SPAN_EMOTE("[message]"))

		DISPLAY_MAPTEXT(src, recipients, MAPTEXT_MOB_RECIPIENTS_WITH_OBSERVERS, /image/maptext/emote, maptext_out)

	update_icon()
		var/image/smiley = image('icons/misc/rocko.dmi', src.smile ? "smile" : "frown")
		if(bright)
			painted = pick(list("#EE2","#2EE", "#E2E","#EEE"))
		else
			painted = pick(list("#000","#151","#514","#511","#218"))

		smiley.color = painted
		smiley.appearance_flags = RESET_COLOR | RESET_ALPHA | RESET_TRANSFORM | PIXEL_SCALE

		src.UpdateOverlays(smiley, "face")
		update_hat()

	proc/update_hat()
		if(istype(src.hat))
			var/icon/working_icon = icon(src.hat.wear_image_icon, src.hat.icon_state, SOUTH )
			working_icon.Shift(SOUTH, 10)
			var/image/working_hat = image(working_icon)
			working_hat.appearance_flags = RESET_COLOR | RESET_ALPHA | RESET_TRANSFORM | PIXEL_SCALE
			src.UpdateOverlays(working_hat, "hat")
		else
			src.UpdateOverlays(null, "hat")

	get_desc(dist, mob/user)
		if(ismob(user) &&	user.job == "Chief Engineer")
			. = "A rock but also [pick(rocko_is)]."
		else if(ismob(user) && (user.job in list("Engineer", "Quartermaster", "Captain")))
			. = "The Chief Engineer loves this rock.  Maybe it's to make up for their lack of a pet."
		else
			. = "A rock with a [src.smile ? "smiley" : "frowny"] face painted on it."

		if (src.material_desc)
			. += "<br>[src.material_desc]"

	attackby(obj/item/W, mob/living/user)
		if(istype(W,/obj/item/clothing/head))
			if(src.hat)
				src.hat.set_loc(get_turf(src))

			src.hat = W
			user.drop_item(W)
			W.set_loc(src)
			user.visible_message("[user] manages to fit [W] snugly on top of [src].")
			update_hat()
		if(istype(W, /obj/item/pet_carrier))
			var/obj/item/pet_carrier/carrier = W
			carrier.trap_mob(src, user)
			user.visible_message(SPAN_ALERT("[user] places [src] into [carrier]."))
			return
		. = ..()

	attack_self(mob/user as mob)
		. = "[user] shakes [src]"
		if(src.hat && prob(40))
			. += " and knocks [src.hat] off"
			src.hat.set_loc(get_turf(src))
			src.hat = null
			update_hat()
		user.visible_message("[.].")

	afterattack(atom/target, mob/user, reach, params)
		if(src.smile && ismob(target) && prob(10))
			src.smile = FALSE
			UpdateIcon()

	proc/choose_rocko_material()
		src.icon_state = pick("rock1","rock1b","rock1c","rock1d")
		src.transform = matrix(1.3,0,0,0,1.3,-3) // Scale 1.3 and Shift Down 3
		// src.color = "#CCC" // Darken slightly to allow lighter colors to be more visibile
		if(prob(100 - ROCKO_ALT_MATERIAL_CHANCE))
			src.setMaterial(getMaterial("rock"), appearance = FALSE, setname = FALSE)
			return

		// We want to give rocko a special material! Find a suitable type of rock.
		var/list/material_list = childrentypesof(/datum/material)
		// Lots of types of gemstones. Make them more common.
		var/rock_list = list("gemstone","gemstone","gemstone","plastic","plutonium")
		for(var/mat in material_list)
			var/datum/material/dummy = new mat
			if(HAS_FLAG(dummy.getMaterialFlags(), MATERIAL_ROCK) && !istype(dummy, /datum/material/crystal/gemstone))
				if(dummy.getID() != "rock")
					rock_list += dummy.getID()

		var/chosen_material = pick(rock_list)
		switch(chosen_material)
			if("gemstone")
				var/chosen_gem = pick(childrentypesof(/datum/material/crystal/gemstone))
				var/datum/material/dummy = new chosen_gem
				src.icon = 'icons/obj/items/materials/materials.dmi'
				src.icon_state = pick("gem1","gem2","gem3")
				src.setMaterial(getMaterial(dummy.getID()), TRUE, FALSE)
				material_desc = "This is a large [dummy.getName()]! It likes to be the center of attention."
				return
			if("plastic")
				src.setMaterial(getMaterial(chosen_material), FALSE, FALSE)
				src.color = list(1.05,0,0,0,1.05,0,0,0,1.05) // Brighten it a bit
				material_desc = "This isn't a rock, it's just a piece of plastic! It looks like it came out of a gift shop."
				src.rocko_is = list("a penny-pincher")
				return
			if("slag")
				src.icon = 'icons/obj/items/materials/materials.dmi'
				src.icon_state = "wad"
				src.setMaterial(getMaterial(chosen_material), setname = FALSE)
				src.rock_scale = 1
				src.rock_offset = -4
				src.bright = TRUE
				material_desc = "This isn't a rock, it's just a pile of slag! It looks a bit bland."
				return
			if("yuranite")
				src.icon = 'icons/obj/items/materials/materials.dmi'
				src.icon_state = "ore$$yuranite"
				src.rock_offset = -1
				src.bright = TRUE
				material_desc = "This is a hunk of yuranite!"
				return

		// Get a sprite for Rocko that matches its material. Also give it some relevant info.
		var/datum/material/material = getMaterial(chosen_material)
		var/sprite_prefix = "ore"
		var/sprite_value = pick(1,2,3,4,5,6)
		var/list/sprite_variants = list("")
		src.icon = material.getIconFile()
		switch(chosen_material)
			if("bohrum")
				sprite_value = pick(1,2,3,4) // Larger bohrum stack sizes are more piles of rocks than rocks
			if("char")
				sprite_value = pick(1,2) // Remove char piles. Want the rock
			if("miracle")
				sprite_value = pick(1,2,3,4,5)
				sprite_prefix = miraclium_shape
			if("plutonium")
				sprite_prefix = "scrap"
		switch(sprite_value)
			if(1) src.rock_scale = 1.3
			if(2) src.rock_scale = 1.15
			if(3) src.rock_scale = 1
			if(4) src.rock_scale = 0.95
			if(5) src.rock_scale = 0.9
			if(6) src.rock_scale = 0.85
		// Include variants of ores if they exist
		for(var/letter in list("b","c","d"))
			if(is_valid_icon_state("[sprite_prefix][sprite_value][letter]_$$[chosen_material]"))
				sprite_variants += letter
			else
				break
		src.icon_state = "[sprite_prefix][sprite_value][pick(sprite_variants)]_$$[chosen_material]"

		if(!is_valid_icon_state(src.icon_state) && !is_valid_icon_state("[src.icon_state]$$[chosen_material]"))
			// Something went wrong and Rocko is now invisible! Just color a normal rock sprite and hope no one notices.
			src.icon = 'icons/obj/items/materials/rocks.dmi'
			src.icon_state = pick("rock1","rock1b","rock1c","rock1d")
			src.rock_scale = initial(src.rock_scale)
			src.rock_offset = initial(src.rock_offset)
			src.color = "#CCC"
			src.setMaterial(material, TRUE, FALSE)
			return
		src.setMaterial(material, FALSE, FALSE)
		return

	proc/setup_rocko_material()
		var/material_name = src.material.getName()
		switch(src.material.getID())
			if("batiline")
				src.bright = TRUE
				src.rock_offset = -4
				material_desc = "This is a hunk of [material_name]! It can be a bit toxic, but is also very protective of others."
				src.rocko_is = list("reminding you to drink water","a good swimmer",
					"shielding you from the worst the world has to offer")
			if("bohrum")
				src.bright = TRUE
				material_desc = "This is a chunk of [material_name]! It is every bit as tough as it looks."
				src.rocko_is = list("the backbone of this station","a solid companion")
			if("cerenkite")
				material_desc = "This is a hunk of [material_name]!"
				src.rocko_is = list("practically glowing","a bright mind","outgoing","optimistic","radiating kindness")
			if("char")
				src.bright = TRUE
				material_desc = "This is a bunch of [material_name]!"
				src.rocko_is = list("a flame in your heart")
			if("claretine")
				src.rock_offset = -2
				material_desc = "This is a pile of [material_name]! It tends to fall apart under pressure."
				src.rocko_is = list("a wizard with electronics","enchanting","magnificent","an engineer's best apprentice")
			if("erebite")
				src.bright = TRUE
				material_desc = "This is a piece of [material_name]! It feels like it could explode at any moment."
				src.rocko_is = list("ready to burst","spicing things up","pretty hot","somehow keeping it together")
			if("fibrilith")
				src.rock_scale = 1
				material_desc = "This is a pile of [material_name]! It can be incredibly irritating sometimes."
				src.rocko_is = list("insulative","a great builder","being difficult","gonna be the death of you","a bundle of fun")
			if("gold")
				material_desc = "This is a huge nugget of [material_name]! It is a treasured crewmember."
				src.rocko_is = list("a heart of gold","a valuable friend","the pride of the station")
			if("ice")
				material_desc = "This is a block of [material_name]! It tends to melt into the crowd."
				src.rocko_is = list("giving you the cold shoulder","keeping it cool","cool under pressure",
					"still warming up to the crew","pretty chilling","cold hearted")
			if("koshmarite")
				src.bright = TRUE
				material_desc = "This is a piece of [material_name]! It looks a bit gloomy."
			if("mauxite")
				src.bright = TRUE
				material_desc = "This is a piece of [material_name]! A bit rusty, but the station couldn't ask for a better pet."
			if("miracle")
				if(src.rock_scale < 1)
					src.rock_scale -= 0.05
				material_desc = "This is a [miraclium_shape] of [material_name]! It likes to keep people guessing."
				src.rocko_is = list("talking nonsense","a miracle worker","dreamy","colorful","doing the impossible","silly","a goofball")
			if("molitz")
				src.rock_scale = max(src.rock_scale, 1)
				material_desc = "This is a piece of [material_name]! It likes to be transparent with people."
				src.rocko_is = list("clear-eyed","always open","a sharp mind","insightful","an open book")
			if("molitz_beta")
				src.bright = TRUE
				src.rock_scale = max(src.rock_scale, 1)
				material_desc = "This is a piece of [material_name]!"
			if("molitz_expended")
				src.bright = TRUE
				src.rock_scale = max(src.rock_scale, 1)
				material_desc = "This is a chunk of [material_name]! It feels drained for most of the day."
				src.rocko_is = list("not up to it right now","hardworking","giving it its all","trying its best","pushing itself too hard")
			if("plasmastone")
				src.bright = TRUE
				material_desc = "This is a sparkling sphere of [material_name]! It is very pretty, but can also be quite dangerous."
				src.rocko_is = list("sparkling","going with the flow","always ready to light up the room","a fluid assistant")
			if("plutonium")
				material_desc = "This isn't a rock! This is a scrap of [material_name]!"
				src.rocko_is = list("a blast to be around","radiating optimism","a launchpad for good ideas")
			if("starstone")
				if(src.rock_scale < 1)
					src.rock_scale = 1
				material_desc = "This is an unbelievable piece of [material_name]! How did the Chief Engineer even find this?"
				src.rocko_is = list("punctual","a movie star","a sharp mind","always has a twinkle in its eye")
			if("syreline")
				material_desc = "This is a pile of [material_name]! It likes to be the center of attention."
				src.rocko_is = list("fashionable","a pretty face","fabulously wealthy","a gittering smile")
			if("telecrystal")
				material_desc = "This is an cut of [material_name]! It has a hard time keeping still."
				src.rocko_is = list("always there for you","a good travel companion","an explorer","hard to keep up with","an adventurer")
			if("veranium")
				src.bright = TRUE
				material_desc = "This is a bolt of [material_name]! It likes to shock people when they least expect it."
				src.rocko_is = list("good with arcfiends","eccentric","always alert","shockingly beautiful","attentive")
			if("viscerite")
				material_desc = "This is a clunk of [material_name]! It may look tough, but it's actually just a big softie."
				src.rocko_is = list("a kindred spirit","a flexible assistant")
			if("uqill")
				src.bright = TRUE
				rock_scale += 0.2
				material_desc = "This is a chunk of [material_name]! It can be very dense sometimes."
				src.rocko_is = list("hard to read","tight-lipped")
			else
				material_desc = "This is a hunk of [material_name]!"
				if(istype(src.material, /datum/material/crystal/gemstone))
					material_desc = "This is a [material_name]!"
		src.transform = matrix(src.rock_scale,0,0,0,src.rock_scale,src.rock_offset)

#undef ROCKO_ALT_MATERIAL_CHANCE

/obj/item/lorrcard
	name = "Filter Copier"
	icon = 'icons/obj/items/card.dmi'
	icon_state = "id_basic"
	wear_image_icon = 'icons/mob/clothing/card.dmi'
	w_class = W_CLASS_TINY
	var/paste_color
	var/paste_alpha = 0
	var/paste_appearance_flags = 0
	var/list/paste_filters
	var/paste = FALSE

	afterattack(atom/target, mob/user, reach, params)
		. = ..()
		if(!paste)
			src.paste_color = target.color
			src.paste_filters = target.filters?.Copy()
			src.paste_alpha = target.alpha
			toggle_paste()
		else
			target.color = src.paste_color
			target.alpha = src.paste_alpha
			target.filters = src.paste_filters?.Copy()

	attack_self(mob/user)
		. = ..()
		toggle_paste()

	proc/toggle_paste()
		if(paste)
			paste = FALSE
			icon_state = "id_basic"
			src.color = null
			src.alpha = 255
			src.filters = list()
		else
			paste = TRUE
			icon_state = "id_sec"
			src.color = src.paste_color
			src.alpha = src.paste_alpha
			src.filters = src.paste_filters?.Copy()




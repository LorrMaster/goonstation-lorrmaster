// File for blood updating procs, full build and individual.
/**
 * Updates all the blood overlays on the human
 * Currently the things that can have overlays are
 * Hands, Head, Mask, Uniform, Suit, Shoes, Feet, Hands and Gloves
 * Made to be cheaper than calling update_x() when adding blood.
 *
 * Consider changing the overlays to use a mask like items since this only looks right for human proportions
 */
/mob/living/carbon/human/proc/update_blood_all()
	src.update_bloody_suit()
	src.update_bloody_uniform()
	src.update_bloody_mask()
	src.update_bloody_head()
	src.update_bloody_gloves()
	src.update_bloody_hands()
	src.update_bloody_shoes()
	src.update_bloody_feet()

/mob/living/carbon/human/proc/update_bloody_suit()
	if (src.wear_suit)
		if(src.wear_suit.forensic_holder?.is_stained)
			var/image/blood_image = src.SafeGetOverlayImage("wear_suit_bloody", 'icons/obj/decals/blood/blood.dmi', layer=EFFECTS_LAYER_UNDER_1 - 1)
			if (src.wear_suit.bloodoverlayimage & SUITBLOOD_ARMOR)
				blood_image.icon_state = "armorblood_c"
			else if (src.wear_suit.bloodoverlayimage & SUITBLOOD_COAT)
				blood_image.icon_state = "coatblood_c"
			else
				blood_image.icon_state = "suitblood_c"
			switch (src.wear_suit.wear_image.layer)
				if (MOB_OVERLAY_BASE)
					blood_image.layer = MOB_OVERLAY_BASE + 0.1
				if (MOB_ARMOR_LAYER)
					blood_image.layer = MOB_ARMOR_LAYER + 0.1
			blood_image.color = src.wear_suit.forensic_holder.stain_color
			src.AddOverlays(blood_image, "wear_suit_bloody")
			return
	src.ClearSpecificOverlays("wear_suit_bloody")

/mob/living/carbon/human/proc/update_bloody_uniform()
	if (src.w_uniform)
		if(src.w_uniform.forensic_holder?.is_stained)
			var/image/blood_image = src.SafeGetOverlayImage("suit_image_blood", 'icons/obj/decals/blood/blood.dmi', layer=EFFECTS_LAYER_UNDER_1 - 1)
			blood_image.icon_state = "uniformblood_c"
			blood_image.color = src.w_uniform.forensic_holder.stain_color
			blood_image.layer = src.w_uniform.wear_layer + 0.1
			src.AddOverlays(blood_image, "suit_image_blood")
			return
	src.ClearSpecificOverlays("suit_image_blood")

/mob/living/carbon/human/proc/update_bloody_mask()
	var/head_offset = src.mutantrace?.head_offset
	if (src.wear_mask)
		if (src.wear_mask.use_bloodoverlay && src.forensic_holder?.is_stained)
			var/image/blood_image = src.SafeGetOverlayImage("wear_mask_blood", 'icons/obj/decals/blood/blood.dmi', layer=EFFECTS_LAYER_UNDER_1 - 1)
			blood_image.icon_state = "maskblood_c"
			blood_image.color = src.wear_mask.forensic_holder.stain_color
			blood_image.layer = MOB_HEAD_LAYER1 + 0.1
			blood_image.pixel_x = 0
			blood_image.pixel_y = head_offset
			src.AddOverlays(blood_image, "wear_mask_blood")
			return
	src.ClearSpecificOverlays("wear_mask_blood")

/mob/living/carbon/human/proc/update_bloody_head()
	var/head_offset = src.mutantrace?.head_offset
	if (src.head)
		if(src.head.forensic_holder?.is_stained)
			var/image/blood_image = src.SafeGetOverlayImage("wear_head_blood", 'icons/obj/decals/blood/blood.dmi', layer=EFFECTS_LAYER_UNDER_1 - 1)
			blood_image.icon_state = "helmetblood_c"
			blood_image.color = src.head.forensic_holder.stain_color
			blood_image.layer = MOB_HEAD_LAYER2 + 0.1
			blood_image.pixel_x = 0
			blood_image.pixel_y = head_offset
			src.AddOverlays(blood_image, "wear_head_blood")
			blood_image.pixel_x = 0
			blood_image.pixel_y = 0
			return
	src.ClearSpecificOverlays("wear_head_blood")

/mob/living/carbon/human/proc/update_bloody_gloves()
	var/hand_offset = src.mutantrace?.hand_offset
	if (src.gloves)
		if(src.gloves.forensic_holder?.is_stained)
			var/image/blood_image = src.SafeGetOverlayImage("bloody_gloves_l", 'icons/obj/decals/blood/blood.dmi', layer=MOB_HAND_LAYER2 + 0.1)
			blood_image.pixel_y = hand_offset
			if (src.limbs && src.limbs.l_arm && src.limbs.l_arm.accepts_normal_human_overlays)
				blood_image.color = src.gloves.forensic_holder.stain_color
				blood_image.icon_state = "left_bloodygloves_c"
				src.AddOverlays(blood_image, "bloody_gloves_l")
			else
				src.ClearSpecificOverlays("bloody_gloves_l")

			blood_image = src.SafeGetOverlayImage("bloody_gloves_r", 'icons/obj/decals/blood/blood.dmi', layer=MOB_HAND_LAYER2 + 0.1)
			blood_image.pixel_y = hand_offset
			if (src.limbs && src.limbs.r_arm && src.limbs.r_arm.accepts_normal_human_overlays)
				blood_image.color = src.gloves.forensic_holder.stain_color
				blood_image.icon_state = "right_bloodygloves_c"
				src.AddOverlays(blood_image, "bloody_gloves_r")
			else
				src.ClearSpecificOverlays("bloody_gloves_r")
			return
	src.ClearSpecificOverlays("bloody_gloves_l", "bloody_gloves_r")

/mob/living/carbon/human/proc/update_bloody_shoes()
	if (src.shoes)
		if(src.shoes.forensic_holder?.is_stained)
			if (src.limbs && src.limbs.l_leg && src.limbs.l_leg.accepts_normal_human_overlays)
				var/image/blood_image = src.SafeGetOverlayImage("bloody_shoes_l", 'icons/obj/decals/blood/blood.dmi', layer=src.shoes.wear_layer + 0.1)
				blood_image.color = src.shoes.forensic_holder.stain_color
				blood_image.icon_state = "left_shoeblood_c"
				src.AddOverlays(blood_image, "bloody_shoes_l")
			else
				src.ClearSpecificOverlays("bloody_shoes_l")
			if (src.limbs && src.limbs.r_leg && src.limbs.r_leg.accepts_normal_human_overlays)
				var/image/blood_image = src.SafeGetOverlayImage("bloody_shoes_r", 'icons/obj/decals/blood/blood.dmi', layer=src.shoes.wear_layer + 0.1)
				blood_image.color = src.shoes.forensic_holder.stain_color
				blood_image.icon_state = "right_shoeblood_c"
				src.AddOverlays(blood_image, "bloody_shoes_r")
			else
				src.ClearSpecificOverlays("bloody_shoes_r")
			return
	src.ClearSpecificOverlays("bloody_shoes_l", "bloody_shoes_r")

/mob/living/carbon/human/proc/update_bloody_hands()
	var/hand_offset = src.mutantrace?.hand_offset
	if (!src.gloves && src.limbs)
		if(src.limbs.l_arm && src.limbs.l_arm.accepts_normal_human_overlays && src.limbs.l_arm.forensic_holder?.is_stained)
			var/image/blood_image = src.SafeGetOverlayImage("bloody_hands_l", 'icons/obj/decals/blood/blood.dmi', layer=MOB_HAND_LAYER2 + 0.1)
			blood_image.pixel_y = hand_offset
			blood_image.color = src.limbs.l_arm.forensic_holder.stain_color
			blood_image.icon_state = "left_bloodyhands_c"
			src.AddOverlays(blood_image, "bloody_hands_l")
		else
			src.ClearSpecificOverlays("bloody_hands_l")

		if (src.limbs.r_arm && src.limbs.r_arm.accepts_normal_human_overlays && src.limbs.r_arm.forensic_holder?.is_stained)
			var/image/blood_image = src.SafeGetOverlayImage("bloody_hands_r", 'icons/obj/decals/blood/blood.dmi', layer=MOB_HAND_LAYER2 + 0.1)
			blood_image.pixel_y = hand_offset
			blood_image.color = src.limbs.r_arm.forensic_holder.stain_color
			blood_image.icon_state = "right_bloodyhands_c"
			src.AddOverlays(blood_image, "bloody_hands_r")
		else
			src.ClearSpecificOverlays("bloody_hands_r")
		return
	src.ClearSpecificOverlays("bloody_hands_l", "bloody_hands_r")

/mob/living/carbon/human/proc/update_bloody_feet()
	if (!src.shoes && src.limbs && islist(src.tracked_blood))
		if (src.limbs.l_leg && src.limbs.l_leg.accepts_normal_human_overlays && src.limbs.l_leg.forensic_holder?.is_stained)
			var/image/blood_image = src.SafeGetOverlayImage("bloody_feet_l", 'icons/obj/decals/blood/blood.dmi', layer=MOB_CLOTHING_LAYER + 0.1)
			blood_image.color = src.limbs.l_leg.forensic_holder.stain_color
			blood_image.icon_state = "left_shoeblood_c"
			src.AddOverlays(blood_image, "bloody_feet_l")
		else
			src.ClearSpecificOverlays("bloody_feet_l")

		if (src.limbs.r_leg && src.limbs.r_leg.accepts_normal_human_overlays && src.limbs.r_leg.forensic_holder?.is_stained)
			var/image/blood_image = src.SafeGetOverlayImage("bloody_feet_r", 'icons/obj/decals/blood/blood.dmi', layer=MOB_CLOTHING_LAYER + 0.1)
			blood_image.color = src.limbs.r_leg.forensic_holder.stain_color
			blood_image.icon_state = "right_shoeblood_c"
			src.AddOverlays(blood_image, "bloody_feet_r")
		else
			src.ClearSpecificOverlays("bloody_feet_r")
		return
	src.ClearSpecificOverlays("bloody_feet_l", "bloody_feet_r")

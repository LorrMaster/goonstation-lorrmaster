/* 	Small storage ammo pouches for storing multiple magazines on your person.
	Can fit in pockets allowing folks to carry more ammo at the expense of taking a little longer to acces it.
	Less messy than having people spawn with 5 magazines in their backpack.	*/

/obj/item/storage/pouch
	name = "ammo pouch"
	icon_state = "ammopouch"
	desc = "A sturdy fabric pouch designed for carrying ammunition. Can be attatched to the webbing of a uniform to allow for quick access during combat."
	health = 6
	w_class = W_CLASS_TINY
	max_wclass = W_CLASS_TINY
	slots = 5
	opens_if_worn = TRUE
	can_hold = list(/obj/item/ammo)
	prevent_holding = list(/obj/item/storage)

	assault_rifle
		name = "rifle magazine pouch"
		icon_state = "ammopouch-large"
		spawn_contents = list(/obj/item/ammo/bullets/assault_rifle = 5)

		mixed
			spawn_contents = list(/obj/item/ammo/bullets/assault_rifle = 3, /obj/item/ammo/bullets/assault_rifle/armor_piercing = 2)

	bullet_9mm
		name = "pistol magazine pouch"
		icon_state = "ammopouch-double"
		spawn_contents = list(/obj/item/ammo/bullets/bullet_9mm = 5)

		small
			name = "small pistol magazine pouch"
			spawn_contents = list(/obj/item/ammo/bullets/bullet_9mm = 2)

		smg
			name = "smg magazine pouch"
			spawn_contents = list(/obj/item/ammo/bullets/bullet_9mm/smg = 5)

	tranq_pistol_dart
		name = "tranq pistol dart pouch"
		icon_state = "ammopouch-double"
		slots = 4
		spawn_contents = list(/obj/item/ammo/bullets/tranq_darts/syndicate/pistol = 4)

	poison_dart
		name = "poison dart pouch"
		icon_state = "ammopouch-double"
		can_hold = list(/obj/item/gun/kinetic/blowgun, /obj/item/ammo/bullets/tranq_darts)
		spawn_contents = list(/obj/item/ammo/bullets/tranq_darts/blow_darts = 2, /obj/item/ammo/bullets/tranq_darts/blow_darts/madness = 1, /obj/item/ammo/bullets/tranq_darts/blow_darts/ls_bee = 1)

	det_38
		name = ".38 rounds pouch"
		icon_state = "ammopouch-double"
		spawn_contents = list(/obj/item/ammo/bullets/a38/stun = 3)

	clock
		name = "9mm rounds pouch"
		icon_state = "ammopouch-double"
		spawn_contents = list(/obj/item/ammo/bullets/nine_mm_NATO = 5)

	veritate
		name = "PDW magazine pouch"
		icon_state = "ammopouch-double"
		spawn_contents = list(/obj/item/ammo/bullets/veritate = 5)


	powercell_medium
		name = "power cell pouch"
		icon_state = "ammopouch-cell"
		spawn_contents = list(/obj/item/ammo/power_cell/med_power = 5)

	sniper
		name = "sniper magazine pouch"
		icon_state = "ammopouch-double"
		slots = 6
		spawn_contents = list(/obj/item/ammo/bullets/rifle_762_NATO = 6)

	shotgun
		name = "shotgun shell pouch"
		icon_state = "ammopouch-large"
		spawn_contents = list(/obj/item/ammo/bullets/a12 = 5)

		weak
			spawn_contents = list(/obj/item/ammo/bullets/a12/weak = 5)

	revolver
		name = "revolver speedloader pouch"
		icon_state = "ammopouch-double"
		spawn_contents = list(/obj/item/ammo/bullets/a357=5)

	grenade_round
		name = "grenade round pouch"
		slots = 4
		spawn_contents = list(/obj/item/ammo/bullets/grenade_round/explosive = 2,
		/obj/item/ammo/bullets/grenade_round/high_explosive = 2)

	rpg
		name = "MPRT rocket pouch"
		slots = 4
		spawn_contents = list(/obj/item/ammo/bullets/rpg = 2)

	lmg
		name = "LMG belt pouch"
		icon_state = "ammopouch-double"
		spawn_contents = list(/obj/item/ammo/bullets/lmg = 5)

	shuriken
		name = "shuriken pouch"
		desc = "A pouch for carrying shurikens. Guaranteed to not shred."
		slots = 4
		can_hold = list(/obj/item/implant/projectile/shuriken)
		spawn_contents = list(/obj/item/implant/projectile/shuriken = 4)

/obj/item/storage/grenade_pouch
	name = "grenade pouch"
	icon_state = "ammopouch"
	desc = "A sturdy fabric pouch used to carry several grenades."
	health = 6
	w_class = W_CLASS_TINY
	slots = 6
	can_hold = list(/obj/item/old_grenade, /obj/item/chem_grenade)
	opens_if_worn = TRUE
	prevent_holding = list(/obj/item/storage)

	frag
		name = "frag grenade pouch"
		spawn_contents = list(/obj/item/old_grenade/stinger/frag = 6)

	stinger
		name = "stinger grenade pouch"
		spawn_contents = list(/obj/item/old_grenade/stinger = 6)

	incendiary
		name = "incendiary supplies pouch"
		can_hold = list(/obj/item/old_grenade, /obj/item/chem_grenade, /obj/item/firebot_deployer)
		spawn_contents = list(/obj/item/chem_grenade/incendiary = 3,
		/obj/item/chem_grenade/very_incendiary = 2,
		/obj/item/firebot_deployer = 1)

	high_explosive
		name = "high explosive grenade pouch"
		spawn_contents = list(/obj/item/old_grenade/high_explosive = 6)

	smoke
		name = "smoke grenade pouch"
		spawn_contents = list(/obj/item/old_grenade/smoke = 6)

	mixed_standard
		name = "mixed grenade pouch"
		spawn_contents = list(/obj/item/chem_grenade/flashbang = 2,
		/obj/item/old_grenade/stinger/frag = 2,
		/obj/item/old_grenade/stinger = 2)

	mixed_explosive
		name = "mixed grenade pouch"
		spawn_contents = list(/obj/item/old_grenade/stinger/frag = 3,
		/obj/item/old_grenade/stinger = 3)
	napalm
		name = "napalm smoke grenade pouch"
		spawn_contents = list(/obj/item/chem_grenade/napalm = 6)

	oxygen
		name = "oxygen grenade pouch"
		spawn_contents = list(/obj/item/old_grenade/oxygen = 6)

	metal_foam
		name = "metal foam grenade pouch"
		spawn_contents = list(/obj/item/chem_grenade/metalfoam = 6)
	repair
		name = "repair grenade pouch"
		spawn_contents = list(/obj/item/old_grenade/oxygen = 3,
		/obj/item/chem_grenade/metalfoam = 3)

// dumb idiot gannets shouldn't have called these "ammo_pouches" if he was gonna make pouches for non-ammo things. wow.

/obj/item/storage/medical_pouch
	name = "trauma field kit"
	icon_state = "ammopouch-medic"
	health = 6
	w_class = W_CLASS_TINY
	slots = 4
	opens_if_worn = TRUE
	spawn_contents = list(/obj/item/reagent_containers/mender/brute/high_capacity,
	/obj/item/reagent_containers/mender/burn/high_capacity)
	prevent_holding = list(/obj/item/storage)

/obj/item/storage/security_pouch
	name = "security pouch"
	desc = "A small pouch containing some essential security supplies. Keep out of reach of the clown."
	icon_state = "ammopouch-sec"
	health = 6
	w_class = W_CLASS_SMALL
	slots = 6
	opens_if_worn = TRUE
	spawn_contents = list(/obj/item/handcuffs = 2,\
	/obj/item/device/flash,\
	/obj/item/reagent_containers/food/snacks/donut,\
	/obj/item/instrument/whistle/security,
	/obj/item/device/panicbutton)
	prevent_holding = list(/obj/item/storage)

	empty
		spawn_contents = list()

/obj/item/storage/security_pouch/assistant
	spawn_contents = list(/obj/item/handcuffs = 2,\
	/obj/item/device/flash = 1,\
	/obj/item/instrument/whistle/security,\
	/obj/item/reagent_containers/food/snacks/donut/custom/frosted,
	/obj/item/device/panicbutton)

/obj/item/storage/ntsc_pouch
	name = "tacticool pouch"
	desc = "A dump pouch for various security accessories, partially-loaded magazines, or maybe even a snack! Attaches to virtually any webbing system through an incredibly complex and very patented Nanotrasen design."
	icon_state = "ammopouch-ntsc"
	health = 6
	w_class = W_CLASS_SMALL
	slots = 5
	opens_if_worn = TRUE
	prevent_holding = list(/obj/item/storage)
	spawn_contents = list(/obj/item/handcuffs/ = 1,
	/obj/item/handcuffs/guardbot = 1,
	/obj/item/device/flash,
	/obj/item/instrument/whistle/security,
	/obj/item/device/panicbutton)


	ntso
		spawn_contents = list(/obj/item/gun/kinetic/clock_188/boomerang/ntso,
		/obj/item/ammo/bullets/bullet_9mm = 4)

/obj/item/storage/emp_grenade_pouch
	name = "EMP grenade pouch"
	desc = "A pouch designed to hold EMP grenades."
	icon_state = "ammopouch-emp"
	health = 6
	w_class = W_CLASS_SMALL
	slots = 5
	opens_if_worn = TRUE
	prevent_holding = list(/obj/item/storage)
	spawn_contents = list(/obj/item/old_grenade/emp = 5)

/obj/item/storage/wasp_grenade_pouch
	name = "experimental biological grenade pouch"
	desc = "A pouch designed to hold experimental biological grenades."
	icon_state = "ammopouch-wasp"
	health = 6
	w_class = W_CLASS_SMALL
	slots = 5
	opens_if_worn = TRUE
	prevent_holding = list(/obj/item/storage)
	spawn_contents = list(/obj/item/old_grenade/spawner/wasp = 5)

/obj/item/storage/custom_chem_grenade_pouch
	name = "chemical grenade pouch"
	desc = "A pouch designed to hold chemical grenades."
	icon_state = "ammopouch-customchem"
	health = 6
	w_class = W_CLASS_SMALL
	slots = 5
	opens_if_worn = TRUE
	prevent_holding = list(/obj/item/storage)
	spawn_contents = list(/obj/item/chem_grenade/custom = 5)


/obj/item/storage/tactical_grenade_pouch
	name = "tactical grenade pouch"
	desc = "A pouch designed to hold assorted special-ops grenades."
	icon_state = "ammopouch-grenade"
	health = 6
	w_class = W_CLASS_SMALL
	slots = 7
	opens_if_worn = TRUE
	prevent_holding = list(/obj/item/storage)
	spawn_contents = list(/obj/item/chem_grenade/incendiary = 2,\
	/obj/item/chem_grenade/shock,\
	/obj/item/old_grenade/smoke = 1,\
	/obj/item/old_grenade/stinger/frag,\
	/obj/item/chem_grenade/flashbang,\
	/obj/item/old_grenade/graviton)

/obj/item/storage/sonic_grenade_pouch
	name = "sonic grenade pouch"
	desc = "A pouch designed to hold sonic grenades, and a pair of earplugs. Wear the earplugs before using the grenades."
	icon_state = "ammopouch-sonic"
	health = 6
	w_class = W_CLASS_SMALL
	slots = 6
	opens_if_worn = TRUE
	prevent_holding = list(/obj/item/storage)
	spawn_contents = list(/obj/item/old_grenade/sonic = 5,\
	/obj/item/clothing/ears/earmuffs/earplugs)

/obj/item/storage/concussion_grenade_pouch
	name = "concussion grenade pouch"
	desc = "A pouch full of odd energy-based concussion grenades. Likely dusty old surplus from the corporate wars."
	icon_state = "ammopouch-quad"
	health = 6
	w_class = W_CLASS_SMALL
	slots = 6
	opens_if_worn = TRUE
	prevent_holding = list(/obj/item/storage)
	spawn_contents = list(/obj/item/old_grenade/energy_concussion = 5)

/obj/item/storage/banana_grenade_pouch
	name = "banana grenade pouch"
	desc = "A fun pouch designed to hold banana grenades."
	icon_state = "ammopouch-banana"
	health = 6
	w_class = W_CLASS_SMALL
	slots = 7 //bonus two slots for the banana grenade kit
	opens_if_worn = TRUE
	prevent_holding = list(/obj/item/storage)
	spawn_contents = list(/obj/item/old_grenade/spawner/banana = 5)

/obj/item/storage/beartrap_pouch
	name = "beartrap pouch"
	desc = "A large pouch for safely storing unarmed beartraps."
	icon_state = "ammopouch-large"
	w_class = W_CLASS_SMALL
	slots = 4
	opens_if_worn = TRUE
	prevent_holding = list(/obj/item/storage)
	spawn_contents = list(/obj/item/beartrap = 4)

/obj/item/storage/landmine_pouch
	name = "landmine pouch"
	desc = "A large pouch for keeping your highly unethical landmines in."
	icon_state = "ammopouch-large"
	w_class = W_CLASS_SMALL
	slots = 3
	opens_if_worn = TRUE
	prevent_holding = list(/obj/item/storage)
	can_hold = list(/obj/item/mine)
	var/static/list/possible_contents = list(/obj/item/mine/radiation, /obj/item/mine/incendiary, /obj/item/mine/stun, /obj/item/mine/blast)

	make_my_stuff()
		..()
		var/obj/item/mine/random_mine
		for (var/i = 1 to src.slots)
			random_mine = pick(src.possible_contents)
			src.storage.add_contents(new random_mine(src))

/obj/item/storage/pouch/highcap
	name = "tactical pouch"
	desc = "A large pouch for carrying multiple miscellaneous things at once."
	icon_state = "ammopouch-quad"
	w_class = W_CLASS_SMALL
	slots = 6
	opens_if_worn = TRUE
	can_hold = list(/obj/item/ammo, /obj/item/old_grenade, /obj/item/chem_grenade, /obj/item/reagent_containers, /obj/item/deployer/barricade, /obj/item/tool, /obj/item/breaching_charge, /obj/item/pinpointer, /obj/item/mine, /obj/item/remote, /obj/item/device/)
	midcap //! weaker pouch for gangs
		desc = "A moderately sized pouch for carrying multiple miscellaneous things at once."
		slots = 4

/obj/item/storage/sawfly_pouch
	name = "sawfly pouch"
	desc = "A pouch for carrying three compact sawflies and a remote."
	icon_state = "ammopouch-sawflies"
	health = 6
	w_class = W_CLASS_SMALL
	slots = 4
	opens_if_worn = TRUE
	prevent_holding = list(/obj/item/storage)
	spawn_contents = list(
		/obj/item/old_grenade/sawfly/firsttime = 3,
		/obj/item/remote/sawflyremote
	)

/obj/item/storage/werewolf_hunter_pouch
	name = "werewolf hunter's pouch"
	desc = "A pouch for carrying some useful herbal grenades."
	icon_state = "ammopouch"
	health = 6
	w_class = W_CLASS_SMALL
	slots = 4
	opens_if_worn = TRUE
	prevent_holding = list(/obj/item/storage)
	spawn_contents = list(
		/obj/item/old_grenade/thing_thrower/aconite = 2,
		/obj/item/old_grenade/thing_thrower/garlic
	)

// Pod wars pouches
/obj/item/storage/pw_medical_pouch
	name = "injector pouch"
	icon_state = "ammopouch-medic"
	health = 6
	w_class = W_CLASS_TINY
	slots = 4
	opens_if_worn = TRUE
	spawn_contents = list(/obj/item/reagent_containers/emergency_injector/bloodbak,
	/obj/item/reagent_containers/emergency_injector/qwikheal,
	/obj/item/reagent_containers/emergency_injector/painstop,
	/obj/item/reagent_containers/emergency_injector/bringbak)
	prevent_holding = list(/obj/item/storage)

// End of pod wars pouches

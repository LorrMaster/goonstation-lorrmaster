TYPEINFO(/datum/component/contaminated)
	initialization_args = list(
		ARG_INFO("ailment_list", DATA_INPUT_REF, "List of diseases to spread.", null),
		ARG_INFO("spread_type", DATA_INPUT_TEXT, "Limit to specific spread type or null for any ailments.", null)
	)

/datum/component/contaminated
	dupe_mode = COMPONENT_DUPE_UNIQUE
	var/list/datum/ailment_data/strains = null
	var/spread_type = null

	Initialize(list/datum/ailment_data/ailments, spread_type = null)
		if(!istype(parent,/atom))
			return COMPONENT_INCOMPATIBLE
		. = ..()
		src.spread_type = spread_type
		src.contaminate(ailments)

	InheritComponent(datum/component/contaminated/C, i_am_original)
		if (!i_am_original)
			return
		if(!src.spread_type && C.spread_type)
			src.spread_type = C.spread_type
		for(var/datum/ailment_data/disease/strain in C.strains)
			src.contaminate(strain)

	///
	proc/contaminate(datum/ailment_data/ailment)
		if(src.spread_type && ailment.spread != src.spread_type)
			return
		for(var/datum/ailment_data/D in src.strains)
			if(D.master == ailment.master)
				return

		var/datum/ailment_data/new_data = new ailment.type()
		new_data.copy_other(ailment)
		src.strains += new_data

	proc/spread_to(var/mob/living/target)
		var/atom/PA = src.parent
		var/spread_chance = 100
		if(PA.material?.hasTrigger(/datum/materialProc/anticontaminant_add))
			spread_chance = 100 - (PA.material.getProperty("chemical") * 10)
		for(var/datum/ailment_data/disease/strain in src.strains)
			if(!prob(spread_chance))
				continue
			var/datum/ailment_data/new_data = new strain.type()
			new_data.copy_other(strain)
			target.contract_disease(null,null,new_data,0)

	proc/scan_info()
		var/report
		for(var/datum/ailment_data/disease/strain in src.strains)
			report += strain.scan_info()
		return report

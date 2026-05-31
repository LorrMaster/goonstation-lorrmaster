TYPEINFO(/datum/component/contaminated)
	initialization_args = list(
		ARG_INFO("disease_name", DATA_INPUT_TEXT, "Name of the disease to spread.", null),
		ARG_INFO("contamination_time", DATA_INPUT_NUM, "How long the disease will be able to spread for.", INFINITY),
	)
/// Marks an atom as being contaminated with one or more diseases.
/datum/component/contaminated
	dupe_mode = COMPONENT_DUPE_UNIQUE
	var/list/datum/contaminated_disease/disease_list

	Initialize(disease_name = null, contamination_time = INFINITY)
		if(!istype(parent,/atom) || parent.type == /turf/space) //exact type check to exclude ocean floors
			return COMPONENT_INCOMPATIBLE
		. = ..()
		var/datum/contaminated_disease/new_disease = new(disease_name, TIME + contamination_time)
		disease_list = list(new_disease)

	InheritComponent(datum/component/contaminated/C, i_am_original)
		if(!i_am_original)
			return
		for(var/datum/contaminated_disease/other in C.disease_list)
			src.add_disease(other)

	proc/add_disease(var/datum/contaminated_disease/other)
		var/datum/contaminated_disease/current = src.get_disease(other.name)
		if(!current)
			src.disease_list += other
			return
		current.expiration_time = max(current.expiration_time, other.expiration_time)

	proc/update_diseases()
		for(var/datum/contaminated_disease/disease in src.disease_list)
			if(disease.expiration_time < TIME)
				src.disease_list -= disease

	proc/get_disease(var/disease_name)
		RETURN_TYPE(/datum/contaminated_disease)
		for(var/datum/contaminated_disease/disease in src.disease_list)
			if(disease.name == disease_name)
				return disease
		return null

	proc/health_scan_text()
		src.update_diseases()
		var/result = "Contaminants: "
		var/count = 0
		for(var/datum/contaminated_disease/disease in src.disease_list)
			if(count != 0)
				result += ", "
			result += "[disease.name]"
			count++

/// Data on which disease to spread and how long it should spread for
/datum/contaminated_disease
	var/name = null //! The name of the disease to spread
	var/expiration_time = INFINITY //! Time that the disease will stop spreading

	New(var/name, var/expiration_time)
		. = ..()
		src.name = name
		src.expiration_time = expiration_time

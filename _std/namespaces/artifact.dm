
CREATE_NAMESPACE(ARTIFACT)

ADD_TO_NAMESPACE(ARTIFACT)(var/static/list/obj/list_artifacts) //! list of all artifacts

ADD_TO_NAMESPACE(ARTIFACT)(var/static/list/datum/artifact_origin/list_origins) //! Instance of each artifact origin
ADD_TO_NAMESPACE(ARTIFACT)(var/static/datum/artifact_origin/ancient/origin_ancient = null)
ADD_TO_NAMESPACE(ARTIFACT)(var/static/datum/artifact_origin/eldritch/origin_eldritch = null)
ADD_TO_NAMESPACE(ARTIFACT)(var/static/datum/artifact_origin/lattice/origin_lattice = null)
ADD_TO_NAMESPACE(ARTIFACT)(var/static/datum/artifact_origin/martian/origin_martian = null)
ADD_TO_NAMESPACE(ARTIFACT)(var/static/datum/artifact_origin/precursor/origin_precursor = null)
ADD_TO_NAMESPACE(ARTIFACT)(var/static/datum/artifact_origin/wizard/origin_wizard = null)

/// Instance of each artifact type, sorted by size and alphabetically
ADD_TO_NAMESPACE(ARTIFACT)(var/static/list/datum/artifact/list_types)
/// Associative list with the instance from above, with the key being the type name
ADD_TO_NAMESPACE(ARTIFACT)(var/static/list/datum/artifact/types_from_name)

/// associative list of lists, with the keys being artifact origin names (and "all") and artifact types
/// the value is the rarity of the type.
/// This is used with weighted_pick for randomly generated artifacts (sometimes of specific origin)
ADD_TO_NAMESPACE(ARTIFACT)(var/static/list/list_rarities)

// Lists of names for artifact forms
ADD_TO_NAMESPACE(ARTIFACT)(var/static/list/list_name_origins = list())
ADD_TO_NAMESPACE(ARTIFACT)(var/static/list/list_name_types = list())
ADD_TO_NAMESPACE(ARTIFACT)(var/static/list/list_name_faults = list())
ADD_TO_NAMESPACE(ARTIFACT)(var/static/list/list_name_triggers = list())

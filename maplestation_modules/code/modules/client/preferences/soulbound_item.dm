/datum/preference/choiced/soulbound_item
	category = PREFERENCE_CATEGORY_MANUALLY_RENDERED
	savefile_key = "soulbound_item"
	savefile_identifier = PREFERENCE_CHARACTER
	should_generate_icons = TRUE

/datum/preference/choiced/soulbound_item/init_possible_values()
	return assoc_to_keys(GLOB.item_choice_soulbound_item) + "Random"

/datum/preference/choiced/soulbound_item/icon_for(value)
	if (value == "Random")
		return icon('icons/effects/random_spawners.dmi', "questionmark")
	else
		var/obj/item/item_type = GLOB.item_choice_soulbound_item[value]
		return icon(initial(item_type.icon), initial(item_type.icon_state))

/datum/preference/choiced/soulbound_item/is_accessible(datum/preferences/preferences)
	if (!..(preferences))
		return FALSE

	return "Soulbound Item" in preferences.all_quirks

/datum/preference/choiced/soulbound_item/apply_to_human(mob/living/carbon/human/target, value)
	return
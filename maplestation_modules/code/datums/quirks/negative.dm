// -- Bad modular quirks. --

// Rebalance of existing quirks
/datum/quirk/item_quirk/nearsighted
	value = -2

/datum/quirk/bad_touch
	value = -2

/datum/quirk/numb
	value = -2 // This is a small buff but a large nerf so it's balanced at a relatively low cost
	desc = "You don't feel pain as much as others. \
		It's harder to pinpoint which parts of your body are injured, and \
		you are immune to some effects of pain - possibly to your detriment."

// Modular quirks
// More vulnerabile to pain (increased pain modifier)
/datum/quirk/pain_vulnerability
	name = "Hyperalgesia"
	desc = "You're less resistant to pain - Your pain naturally decreases slower and you receive more overall."
	icon = FA_ICON_USER_INJURED
	value = -6
	gain_text = span_danger("You feel sharper.")
	lose_text = span_notice("You feel duller.")
	medical_record_text = "Patient has Hyperalgesia, and is more susceptible to pain stimuli than most."
	mail_goodies = list(/obj/item/temperature_pack/cold)

/datum/quirk/pain_vulnerability/add()
	var/mob/living/carbon/carbon_holder = quirk_holder
	if(istype(carbon_holder))
		carbon_holder.set_pain_mod(PAIN_MOD_QUIRK, 1.15)

/datum/quirk/pain_vulnerability/remove()
	var/mob/living/carbon/carbon_holder = quirk_holder
	if(istype(carbon_holder))
		carbon_holder.unset_pain_mod(PAIN_MOD_QUIRK)

// More vulnerable to pain + get pain from more actions (Glass bones and paper skin)
/datum/quirk/allodynia
	name = "Allodynia"
	desc = "Your nerves are extremely sensitive - you may receive pain from things that wouldn't normally be painful, such as hugs."
	icon = FA_ICON_TIRED
	value = -10
	gain_text = span_danger("You feel fragile.")
	lose_text = span_notice("You feel less delicate.")
	medical_record_text = "Patient has Allodynia, and is extremely sensitive to touch, pain, and similar stimuli."
	mail_goodies = list(/obj/item/temperature_pack/cold, /obj/item/temperature_pack/heat)
	COOLDOWN_DECLARE(time_since_last_touch)

/datum/quirk/allodynia/add()
	var/mob/living/carbon/carbon_holder = quirk_holder
	if(istype(carbon_holder))
		carbon_holder.set_pain_mod(PAIN_MOD_QUIRK, 1.2)
	RegisterSignal(quirk_holder, list(COMSIG_LIVING_GET_PULLED, COMSIG_CARBON_HELP_ACT), PROC_REF(cause_body_pain))

/datum/quirk/allodynia/remove()
	var/mob/living/carbon/carbon_holder = quirk_holder
	if(istype(carbon_holder))
		carbon_holder.unset_pain_mod(PAIN_MOD_QUIRK)
	UnregisterSignal(quirk_holder, list(COMSIG_LIVING_GET_PULLED, COMSIG_CARBON_HELP_ACT))

/**
 * Causes pain to arm zones if they're targeted, and the chest zone otherwise.
 *
 * source - quirk_holder / the mob being touched
 * toucher - the mob that's interacting with source (pulls, hugs, etc)
 */
/datum/quirk/allodynia/proc/cause_body_pain(datum/source, mob/living/toucher)
	SIGNAL_HANDLER

	if(!COOLDOWN_FINISHED(src, time_since_last_touch))
		return

	if(quirk_holder.stat != CONSCIOUS)
		return

	to_chat(quirk_holder, span_danger("[toucher] touches you, causing a wave of sharp pain throughout your [parse_zone(toucher.zone_selected)]!"))
	actually_hurt(toucher.zone_selected, 9)

/**
 * Actually cause the pain to the target limb, causing a visual effect, emote, and a negative moodlet.
 *
 * zone - the body zone being affected
 * amount - the amount of pain being added
 */
/datum/quirk/allodynia/proc/actually_hurt(zone, amount)
	var/mob/living/carbon/carbon_holder = quirk_holder
	if(!istype(carbon_holder))
		return

	new /obj/effect/temp_visual/annoyed(quirk_holder.loc)
	carbon_holder.cause_pain(zone, amount)
	INVOKE_ASYNC(quirk_holder, TYPE_PROC_REF(/mob/living, pain_emote))
	quirk_holder.add_mood_event("bad_touch", /datum/mood_event/very_bad_touch)
	COOLDOWN_START(src, time_since_last_touch, 30 SECONDS)

// Spawn with an item that you are soulbound to (must say close or build up lethal levels of stress and slowly lose blood, should persist through mindswaps)
/datum/quirk/item_quirk/soulbound_item
	name = "Soulbound Item"
	desc = "You are nearsighted without prescription glasses, but spawn with a pair." //TODO
	icon = FA_ICON_GLASSES //TODO
	value = -4 //TODO
	gain_text = span_danger("Things far away from you start looking blurry.") //TODO
	lose_text = span_notice("You start seeing faraway things normally again.") //TODO
	medical_record_text = "Patient requires prescription glasses in order to counteract nearsightedness." //TODO
	hardcore_value = 5 //TODO
	quirk_flags = QUIRK_HUMAN_ONLY
	mail_goodies = list(/obj/item/clothing/glasses/regular) // extra pair if orginal one gets broken by somebody mean //TODO
	/// A weak reference to our soulbound item.
	var/datum/weakref/soulbound_item_ref

/datum/quirk_constant_data/soulbound_item
	associated_typepath = /datum/quirk/item_quirk/soulbound_item
	customization_options = list(/datum/preference/choiced/soulbound_item)

/datum/quirk/item_quirk/soulbound_item/add_unique(client/client_source)
	var/soulbound_item_name = client_source?.prefs.read_preference(/datum/preference/choiced/soulbound_item) || "Loaf of Bread"
	var/obj/item/soulbound_item_type

	soulbound_item_name = soulbound_item_name == "Random" ? pick(GLOB.item_choice_soulbound_item) : soulbound_item_name
	soulbound_item_type = GLOB.item_choice_soulbound_item[soulbound_item_name]

	var/obj/new_soulbound_item = new soulbound_item_type(get_turf(quirk_holder))
	
	give_item_to_holder(new_soulbound_item, list(
		LOCATION_BACKPACK = ITEM_SLOT_BACKPACK,
	))
	quirk_holder.AddComponent(/datum/component/soulbound_person, quirk_holder.mind, new_soulbound_item)

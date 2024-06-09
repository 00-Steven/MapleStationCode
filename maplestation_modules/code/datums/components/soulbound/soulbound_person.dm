/**
 * Soulbound Person Component
 *
 * Keeps track of a given item and its distance to the user,
 * and applies increasingly dangerous effects to the holder
 * when that item is outside a given range.
 * Used by:
 * - Soulbound quirk (TODO: ACTUAL FILE)
 * - Soulbound smite (TODO: ACTUAL FILE)
 */

#define MIN_BLOOD 0

/datum/component/soulbound_person
	can_transfer = TRUE
	/// Owner's mind in case of mind transfer
	var/datum/mind/owner_mind
	/// A weak reference to our soulbound object.
	var/datum/weakref/soulbound_object_ref
	var/strain = 0
	var/max_separation_distance = 3

/datum/component/soulbound_person/Initialize(datum/mind/new_mind, obj/new_soulbound_object, starting_strain = 0)
	if(!isliving(parent))
		return COMPONENT_INCOMPATIBLE

	owner_mind = new_mind
	soulbound_object_ref = WEAKREF(new_soulbound_object)
	strain = starting_strain

/datum/component/spill/PostTransfer()
	if(!isliving(parent))
		return COMPONENT_INCOMPATIBLE

/datum/component/soulbound_person/RegisterWithParent() //MAKE IT SEND A MESSAGE WHEN IT FUCKING GETS DESTROYED, THE OBJECT
	RegisterSignal(parent, COMSIG_LIVING_LIFE, PROC_REF(on_life))
	RegisterSignal(parent, COMSIG_MIND_TRANSFERRED, PROC_REF(on_mind_transferred)) // Cope, we don't have COMSIG_MOB_MIND_TRANSFERRED_OUT_OF yet
	if(ishuman(parent))
		RegisterSignal(parent, COMSIG_HUMAN_ON_HANDLE_BLOOD, PROC_REF(try_lose_blood))

/datum/component/soulbound_person/UnregisterFromParent()
	UnregisterSignal(parent, list(COMSIG_LIVING_LIFE, COMSIG_HUMAN_ON_HANDLE_BLOOD, COMSIG_MIND_TRANSFERRED))

/datum/component/soulbound_person/proc/check_separated()
	var/obj/soulbound_object = soulbound_object_ref?.resolve()

	if(isnull(soulbound_object))
		return TRUE // If it doesn't exist we're VERY separated.

	if(get_dist(parent, soulbound_object) > max_separation_distance)
		return TRUE

	return FALSE

/datum/component/soulbound_person/proc/on_life(mob/living/source, seconds_per_tick, times_fired)
	SIGNAL_HANDLER

	if(check_separated())
		strain = min(strain + 0.5, 100)
		if(strain > 10 && SPT_PROB(2.5, seconds_per_tick))
			strain_reaction()
	else
		strain = max(strain - (2 * seconds_per_tick), 0)

/datum/component/soulbound_person/proc/strain_reaction()
	if(iscarbon(parent))
		var/mob/living/carbon/carbon_parent = parent
		if(carbon_parent.stat != CONSCIOUS)
			return

	var/mob/living/carbon/living_parent = parent

	var/high_strain = (strain > 60) //things get psychosomatic from here on
	switch(rand(1, 6))
		if(1)
			if(high_strain)
				to_chat(living_parent, span_warning("You feel really sick at the thought of being alone!"))
			else
				to_chat(living_parent, span_warning("You feel sick..."))
			addtimer(CALLBACK(living_parent, TYPE_PROC_REF(/mob/living/carbon, vomit), high_strain), 50) //blood vomit if high strain
		if(2)
			if(high_strain)
				to_chat(living_parent, span_warning("You feel weak and scared! If only you weren't alone..."))
				living_parent.adjustStaminaLoss(50)
			else
				to_chat(living_parent, span_warning("You can't stop shaking..."))

			living_parent.adjust_dizzy(40 SECONDS)
			living_parent.adjust_confusion(20 SECONDS)
			living_parent.set_jitter_if_lower(40 SECONDS)

		if(3, 4)
			if(high_strain)
				to_chat(living_parent, span_warning("You're going mad with loneliness!"))
				living_parent.adjust_hallucinations(60 SECONDS)
			else
				to_chat(living_parent, span_warning("You feel really lonely..."))

		if(5)
			if(high_strain)
				if(prob(15) && ishuman(living_parent))
					var/mob/living/carbon/human/human_parent = living_parent
					human_parent.set_heartattack(TRUE)
					to_chat(human_parent, span_userdanger("You feel a stabbing pain in your heart!"))
				else
					to_chat(living_parent, span_userdanger("You feel your heart lurching in your chest..."))
					living_parent.adjustOxyLoss(8)
			else
				to_chat(living_parent, span_warning("Your heart skips a beat."))
				living_parent.adjustOxyLoss(8)

		else
			//No effect
			return

/datum/component/soulbound_person/proc/try_lose_blood(datum/source, seconds_per_tick, times_fired)
	SIGNAL_HANDLER

	if(!check_separated())
		return FALSE

	var/mob/living/carbon/human/human_parent = parent
	if(human_parent.stat == DEAD || human_parent.blood_volume <= MIN_BLOOD)
		return
	// This exotic blood check is solely to snowflake slimepeople into working with this component.
	if(HAS_TRAIT(human_parent, TRAIT_NOBLOOD)) // && isnull(human_parent.dna.species.exotic_blood)
		return

	human_parent.blood_volume = max(MIN_BLOOD, human_parent.blood_volume - human_parent.dna.species.blood_deficiency_drain_rate * seconds_per_tick)

/datum/component/soulbound_person/proc/on_mind_transferred(datum/source, mob/living/current)
	SIGNAL_HANDLER

	//current.AddComponent(/datum/component/soulbound_person, owner_mind, soulbound_object_ref?.resolve(), strain)
	if(isnull(owner_mind.current))
		qdel(src) // No body whatsoever? Begone.
		return
	owner_mind.current.TakeComponent(src)
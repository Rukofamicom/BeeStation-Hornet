/obj/item/organ
	name = "organ"
	icon = 'icons/obj/surgery.dmi'
	var/mob/living/carbon/owner = null
	var/status = ORGAN_ORGANIC
	w_class = WEIGHT_CLASS_SMALL
	throwforce = 0
	var/zone = BODY_ZONE_CHEST
	var/slot
	// DO NOT add slots with matching names to different zones - it will break internal_organs_slot list!
	var/organ_flags = ORGAN_EDIBLE
	var/maxHealth = STANDARD_ORGAN_THRESHOLD
	var/damage = 0		//total damage this organ has sustained
	///Healing factor and decay factor function on % of maxhealth, and do not work by applying a static number per tick
	var/healing_factor 	= 0										//fraction of maxhealth healed per on_life(), set to 0 for generic organs
	var/decay_factor 	= 0										//same as above but when without a living owner, set to 0 for generic organs
	var/high_threshold	= STANDARD_ORGAN_THRESHOLD * 0.45		//when severe organ damage occurs
	var/low_threshold	= STANDARD_ORGAN_THRESHOLD * 0.1		//when minor organ damage occurs

	///Organ variables for determining what we alert the owner with when they pass/clear the damage thresholds
	var/prev_damage = 0
	var/low_threshold_passed
	var/high_threshold_passed
	var/now_failing
	var/now_fixed
	var/high_threshold_cleared
	var/low_threshold_cleared

	///When you take a bite you cant jam it in for surgery anymore.
	var/useable = TRUE
	var/list/food_reagents = list(/datum/reagent/consumable/nutriment = 5)
	juice_typepath = /datum/reagent/liquidgibs

	///Do we effect the appearance of our mob. Used to save time in preference code
	var/visual = TRUE
	/// Traits that are given to the holder of the organ.
	var/list/organ_traits
	/// Status Effects that are given to the holder of the organ.
	var/list/organ_effects

// Players can look at prefs before atoms SS init, and without this
// they would not be able to see external organs, such as moth wings.
// This is also necessary because assets SS is before atoms, and so
// any nonhumans created in that time would experience the same effect.
INITIALIZE_IMMEDIATE(/obj/item/organ)

/obj/item/organ/Initialize(mapload)
	. = ..()
	START_PROCESSING(SSobj, src)
	if(organ_flags & ORGAN_EDIBLE)
		AddComponent(/datum/component/edible,\
		initial_reagents = food_reagents,\
		foodtypes = RAW | MEAT | GORE,\
		volume = 10,\
		pre_eat = CALLBACK(src, PROC_REF(pre_eat)),\
		on_compost = CALLBACK(src, PROC_REF(pre_compost)),\
		after_eat = CALLBACK(src, PROC_REF(on_eat_from)))
	if(organ_flags & ORGAN_SYNTHETIC)
		juice_typepath = null

/*
 * Insert the organ into the select mob.
 *
 * receiver - the mob who will get our organ
 * special - "quick swapping" an organ out - when TRUE, the mob will be unaffected by not having that organ for the moment
 * drop_if_replaced - if there's an organ in the slot already, whether we drop it afterwards
 * pref_load - some lazy shit used only for passing an arg into another proc
 */
/obj/item/organ/proc/Insert(mob/living/carbon/receiver, special = FALSE, drop_if_replaced = TRUE, pref_load = FALSE)
	SHOULD_CALL_PARENT(TRUE)

	if(!iscarbon(receiver) || owner == receiver)
		return FALSE

	var/obj/item/organ/replaced = receiver.get_organ_slot(slot)
	if(replaced)
		replaced.Remove(receiver, special = TRUE, pref_load = pref_load)
		if(drop_if_replaced)
			replaced.forceMove(get_turf(receiver))
		else
			qdel(replaced)

	receiver.internal_organs |= src
	receiver.internal_organs_slot[slot] = src
	owner = receiver


	// Apply unique side-effects. Return value does not matter.
	on_insert(receiver, special)

	STOP_PROCESSING(SSobj, src)

	return TRUE

/// Called after the organ is inserted into a mob.
/// Adds Traits, Actions, and Status Effects on the mob in which the organ is impanted.
/// Override this proc to create unique side-effects for inserting your organ. Must be called by overrides.
/obj/item/organ/proc/on_insert(mob/living/carbon/organ_owner, special)
	SHOULD_CALL_PARENT(TRUE)

	moveToNullspace()

	for(var/trait in organ_traits)
		ADD_TRAIT(organ_owner, trait, REF(src))
		//message_admins("[key_name(organ_owner)] has gained organ [src] ([slot]) and trait [trait] added.")

	for(var/datum/action/action as anything in actions)
		action.Grant(organ_owner)

	for(var/datum/status_effect/effect as anything in organ_effects)
		organ_owner.apply_status_effect(effect, type)

	//RegisterSignal(owner, COMSIG_ATOM_EXAMINE, PROC_REF(on_owner_examine))
	SEND_SIGNAL(src, COMSIG_ORGAN_IMPLANTED, organ_owner)
	SEND_SIGNAL(organ_owner, COMSIG_CARBON_GAIN_ORGAN, src, special)

//Special is for instant replacement like autosurgeons
/obj/item/organ/proc/Remove(mob/living/carbon/organ_owner, special = FALSE, pref_load = FALSE)
	SHOULD_CALL_PARENT(TRUE)

	owner = null
	if(organ_owner)
		organ_owner.internal_organs -= src
		if(organ_owner.internal_organs_slot[slot] == src)
			organ_owner.internal_organs_slot.Remove(slot)
		if((organ_flags & ORGAN_VITAL) && !special && !(organ_owner.status_flags & GODMODE))
			if(organ_owner.stat != DEAD)
				organ_owner.investigate_log("has been killed by losing a vital organ ([src]).", INVESTIGATE_DEATHS)
			organ_owner.death()

	// Apply or reset unique side-effects. Return value does not matter.
	on_remove(organ_owner, special)

	START_PROCESSING(SSobj, src)

	return TRUE

/// Called after the organ is removed from a mob.
/// Removes Traits, Actions, and Status Effects on the mob in which the organ was impanted.
/// Override this proc to create unique side-effects for removing your organ. Must be called by overrides.
/obj/item/organ/proc/on_remove(mob/living/carbon/organ_owner, special)
	SHOULD_CALL_PARENT(TRUE)

	for(var/trait in organ_traits)
		REMOVE_TRAIT(organ_owner, trait, REF(src))
		//message_admins("[key_name(organ_owner)] has lost organ [src] ([slot]) and trait [trait] removed.")

	for(var/datum/action/action as anything in actions)
		action.Remove(organ_owner)

	for(var/datum/status_effect/effect as anything in organ_effects)
		organ_owner.remove_status_effect(effect, type)

	SEND_SIGNAL(src, COMSIG_ORGAN_REMOVED, organ_owner)
	SEND_SIGNAL(organ_owner, COMSIG_CARBON_LOSE_ORGAN, src, special)

/// Add a trait to an organ that it will give its owner.
/obj/item/organ/proc/add_organ_trait(trait)
	LAZYADD(organ_traits, trait)
	if(isnull(owner))
		return
	ADD_TRAIT(owner, trait, REF(src))

/// Removes a trait from an organ, and by extension, its owner.
/obj/item/organ/proc/remove_organ_trait(trait)
	LAZYREMOVE(organ_traits, trait)
	if(isnull(owner))
		return
	REMOVE_TRAIT(owner, trait, REF(src))

/// Add a Status Effect to an organ that it will give its owner.
/obj/item/organ/proc/add_organ_status(status)
	LAZYADD(organ_effects, status)
	if(isnull(owner))
		return
	owner.apply_status_effect(status, type)

/// Removes a Status Effect from an organ, and by extension, its owner.
/obj/item/organ/proc/remove_organ_status(status)
	LAZYREMOVE(organ_effects, status)
	if(isnull(owner))
		return
	owner.remove_status_effect(status, type)

/obj/item/organ/proc/on_find(mob/living/finder)
	return

/obj/item/organ/process(delta_time, times_fired)
	on_death(delta_time, times_fired) //Kinda hate doing it like this, but I really don't want to call process directly.

/obj/item/organ/proc/on_death(delta_time, times_fired) //runs decay when outside of a person
	if(organ_flags & (ORGAN_SYNTHETIC | ORGAN_FROZEN))
		return
	applyOrganDamage(decay_factor * maxHealth * delta_time)

/obj/item/organ/proc/on_life(delta_time, times_fired) //repair organ damage if the organ is not failing
	SHOULD_CALL_PARENT(TRUE) //PASS YOUR ARGS FUCKER

	if(organ_flags & ORGAN_FAILING)
		return
	///Damage decrements by a percent of its maxhealth
	var/healing_amount = healing_factor
	///Damage decrements again by a percent of its maxhealth, up to a total of 4 extra times depending on the owner's health
	if(owner)
		healing_amount += (owner.satiety > 0) ? (4 * healing_factor * owner.satiety / MAX_SATIETY) : 0
	applyOrganDamage(-healing_amount * maxHealth * delta_time, damage) // pass current damage incase we are over cap

/obj/item/organ/examine(mob/user)
	. = ..()
	if(organ_flags & ORGAN_FAILING)
		if(status == ORGAN_ROBOTIC)
			. += span_warning("[src] seems to be broken!")
			return
		. += span_warning("[src] has decayed for too long, and has turned a sickly color! It doesn't look like it will work anymore!")
		return
	if(damage > high_threshold)
		. += span_warning("[src] is starting to look discolored.")
	. += span_info("[src] fit[name[length(name)] == "s" ? "" : "s"] in the <b>[parse_zone(zone)]</b>.")

///Used as callbacks by object pooling
/obj/item/organ/proc/exit_wardrobe()
	START_PROCESSING(SSobj, src)

//See above
/obj/item/organ/proc/enter_wardrobe()
	STOP_PROCESSING(SSobj, src)

/obj/item/organ/Destroy()
	if(owner)
		// The special flag is important, because otherwise mobs can die
		// while undergoing transformation into different mobs.
		Remove(owner, special=TRUE)
	else
		STOP_PROCESSING(SSobj, src)
	return ..()

// Put any "can we eat this" checks for edible organs here
/obj/item/organ/proc/pre_eat(eater, feeder)
	if(iscarbon(eater))
		var/mob/living/carbon/target = eater
		for(var/S in target.surgeries)
			var/datum/surgery/surgery = S
			if(surgery.location == zone)
				return FALSE
	return TRUE

/obj/item/organ/proc/pre_compost(user)
	return TRUE

/obj/item/organ/proc/on_eat_from(eater, feeder)
	useable = FALSE //You bit it, no more using it

/obj/item/organ/proc/check_for_surgery(mob/living/carbon/human/H)
	for(var/datum/surgery/S in H.surgeries)
		return TRUE			//no snacks mid surgery
	return FALSE

/obj/item/organ/item_action_slot_check(slot,mob/user)
	return //so we don't grant the organ's action to mobs who pick up the organ.

///Adjusts an organ's damage by the amount "d", up to a maximum amount, which is by default max damage
/obj/item/organ/proc/applyOrganDamage(var/d, var/maximum = maxHealth)	//use for damaging effects
	if(!d) //Micro-optimization.
		return
	if(maximum < damage)
		return
	damage = clamp(damage + d, 0, maximum)
	var/mess = check_damage_thresholds(owner)
	prev_damage = damage
	if(mess && owner)
		to_chat(owner, mess)

///SETS an organ's damage to the amount "d", and in doing so clears or sets the failing flag, good for when you have an effect that should fix an organ if broken
/obj/item/organ/proc/set_organ_damage(var/d)	//use mostly for admin heals
	applyOrganDamage(d - damage)

/** check_damage_thresholds
  * input: M (a mob, the owner of the organ we call the proc on)
  * output: returns a message should get displayed.
  * description: By checking our current damage against our previous damage, we can decide whether we've passed an organ threshold.
  *				 If we have, send the corresponding threshold message to the owner, if such a message exists.
  */
/obj/item/organ/proc/check_damage_thresholds(var/M)
	if(damage == prev_damage)
		return
	var/delta = damage - prev_damage
	if(delta > 0)
		if(damage >= maxHealth)
			organ_flags |= ORGAN_FAILING
			return now_failing
		if(damage > high_threshold && prev_damage <= high_threshold)
			return high_threshold_passed
		if(damage > low_threshold && prev_damage <= low_threshold)
			return low_threshold_passed
	else
		organ_flags &= ~ORGAN_FAILING
		if(prev_damage > low_threshold && damage <= low_threshold)
			return low_threshold_cleared
		if(prev_damage > high_threshold && damage <= high_threshold)
			return high_threshold_cleared
		if(prev_damage == maxHealth)
			return now_fixed

//Looking for brains?
//Try code/modules/mob/living/carbon/brain/brain_item.dm

/mob/living/proc/regenerate_organs()
	return 0

/mob/living/carbon/regenerate_organs()
	if(dna?.species)
		dna.species.regenerate_organs(src, replace_current = FALSE)
		return

	else
		var/obj/item/organ/lungs/L = get_organ_slot(ORGAN_SLOT_LUNGS)
		if(!L)
			L = new()
			L.Insert(src)
		L.set_organ_damage(0)

		var/obj/item/organ/heart/H = get_organ_slot(ORGAN_SLOT_HEART)
		if(!H)
			H = new()
			H.Insert(src)
		H.set_organ_damage(0)

		var/obj/item/organ/tongue/T = get_organ_slot(ORGAN_SLOT_TONGUE)
		if(!T)
			T = new()
			T.Insert(src)
		T.set_organ_damage(0)

		var/obj/item/organ/eyes/eyes = get_organ_slot(ORGAN_SLOT_EYES)
		if(!eyes)
			eyes = new()
			eyes.Insert(src)
		eyes.set_organ_damage(0)

		var/obj/item/organ/ears/ears = get_organ_slot(ORGAN_SLOT_EARS)
		if(!ears)
			ears = new()
			ears.Insert(src)
		ears.set_organ_damage(0)

/** get_availability
  * returns whether the species should innately have this organ.
  *
  * regenerate organs works with generic organs, so we need to get whether it can accept certain organs just by what this returns.
  * This is set to return true or false, depending on if a species has a specific organless trait. stomach for example checks if the species has NOSTOMACH and return based on that.
  * Arguments:
  * owner_species - species, needed to return the mutant slot as true or false. stomach set to null means it shouldn't have one.
  * owner_mob - for more specific checks, like nightmares.
 */
/obj/item/organ/proc/get_availability(datum/species/owner_species, mob/living/owner_mob)
	return TRUE

/// Called before organs are replaced in regenerate_organs with new ones
/obj/item/organ/proc/before_organ_replacement(obj/item/organ/replacement)
	SHOULD_CALL_PARENT(TRUE)

	SEND_SIGNAL(src, COMSIG_ORGAN_BEING_REPLACED, replacement)

	// If we're being replace with an identical type we should take organ damage
	if(replacement.type == type)
		replacement.set_organ_damage(damage)

/// Called by medical scanners to get a simple summary of how healthy the organ is. Returns an empty string if things are fine.
/obj/item/organ/proc/get_status_text()
	var/status = ""
	if(organ_flags & ORGAN_FAILING)
		status = "<font color='#cc3333'>Non-Functional</font>"
	else if(damage > high_threshold)
		status = "<font color='#ff9933'>Severely Damaged</font>"
	else if (damage > low_threshold)
		status = "<font color='#ffcc33'>Mildly Damaged</font>"

	return status

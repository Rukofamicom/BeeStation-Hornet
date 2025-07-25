
//////////////////////////////////////////////////////////////////////////////////////////
					// MEDICINE REAGENTS
//////////////////////////////////////////////////////////////////////////////////////

// where all the reagents related to medicine go.

/datum/reagent/medicine
	name = "Medicine"
	chem_flags = CHEMICAL_NOT_DEFINED
	taste_description = "bitterness"

/datum/reagent/medicine/on_mob_life(mob/living/carbon/M, delta_time, times_fired)
	current_cycle++
	holder.remove_reagent(type, metabolization_rate * delta_time / M.metabolism_efficiency) //medicine reagents stay longer if you have a better metabolism
	if(!QDELETED(holder) && metabolite) // removing a reagent can sometimes delete the holder
		holder.add_reagent(metabolite, metabolization_rate / M.metabolism_efficiency * METABOLITE_RATE)

/datum/reagent/medicine/leporazine
	name = "Leporazine"
	description = "Leporazine will effectively regulate a patient's body temperature, ensuring it never leaves safe levels."
	color = "#DB90C6"
	chem_flags = CHEMICAL_RNG_GENERAL | CHEMICAL_RNG_FUN | CHEMICAL_RNG_BOTANY
	overdose_threshold = 30
	metabolization_rate = 0.25 * REAGENTS_METABOLISM

/datum/reagent/medicine/leporazine/on_mob_life(mob/living/carbon/M, delta_time, times_fired)
	var/target_temp = M.get_body_temp_normal(apply_change=FALSE)
	if(M.bodytemperature > target_temp)
		M.adjust_bodytemperature(-40 * TEMPERATURE_DAMAGE_COEFFICIENT * REM * delta_time, target_temp)
	else if(M.bodytemperature < (target_temp + 1))
		M.adjust_bodytemperature(40 * TEMPERATURE_DAMAGE_COEFFICIENT * REM * delta_time, 0, target_temp)
	if(ishuman(M))
		var/mob/living/carbon/human/humi = M
		if(humi.coretemperature > target_temp)
			humi.adjust_coretemperature(-40 * TEMPERATURE_DAMAGE_COEFFICIENT * REM * delta_time, target_temp)
		else if(humi.coretemperature < (target_temp + 1))
			humi.adjust_coretemperature(40 * TEMPERATURE_DAMAGE_COEFFICIENT * REM * delta_time, 0, target_temp)
	..()

/datum/reagent/medicine/leporazine/overdose_process(mob/living/M)
	if(prob(50))
		M.adjust_bodytemperature(200, 0)
	else
		M.adjust_bodytemperature(-200, 0)
	..()
	. = 1

/datum/reagent/medicine/adminordrazine //An OP chemical for admins
	name = "Adminordrazine"
	description = "It's magic. We don't have to explain it."
	color = "#E0BB00" //golden for the gods
	chem_flags = CHEMICAL_NOT_SYNTH | CHEMICAL_RNG_FUN
	taste_description = "badmins"

/datum/reagent/medicine/adminordrazine/on_mob_life(mob/living/carbon/M, delta_time, times_fired)
	M.heal_bodypart_damage(5 * REM * delta_time, 5 * REM * delta_time)
	M.adjustToxLoss(-5 * REM * delta_time, FALSE, TRUE)
	M.setOxyLoss(0, 0)
	M.setCloneLoss(0, 0)

	M.set_blurriness(0)
	M.set_blindness(0)
	M.SetKnockdown(0)
	M.SetStun(0)
	M.SetUnconscious(0)
	M.SetParalyzed(0)
	M.SetImmobilized(0)
	M.confused = 0
	M.SetSleeping(0)

	M.silent = FALSE
	M.dizziness = 0
	M.disgust = 0
	M.drowsyness = 0
	M.stuttering = 0
	M.slurring = 0
	M.jitteriness = 0
	M.hallucination = 0
	M.radiation = 0
	REMOVE_TRAITS_NOT_IN(M, list(SPECIES_TRAIT, ROUNDSTART_TRAIT, ORGAN_TRAIT))
	M.reagents.remove_all_type(/datum/reagent/toxin, 5 * REM * delta_time, FALSE, TRUE)
	if(M.blood_volume < BLOOD_VOLUME_NORMAL)
		M.blood_volume = BLOOD_VOLUME_NORMAL

	M.cure_all_traumas(TRAUMA_RESILIENCE_MAGIC)
	for(var/obj/item/organ/organ as anything in M.internal_organs)
		organ.set_organ_damage(0)
	for(var/thing in M.diseases)
		var/datum/disease/D = thing
		if(D.danger == DISEASE_BENEFICIAL || D.danger == DISEASE_POSITIVE)
			continue
		D.cure()
	..()
	. = TRUE

/datum/reagent/medicine/adminordrazine/quantum_heal
	name = "Quantum Medicine"
	description = "Rare and experimental particles, that apparently swap the user's body with one from an alternate dimension where it's completely healthy."
	taste_description = "science"

/datum/reagent/medicine/synaptizine
	name = "Synaptizine"
	description = "Increases resistance to stuns as well as reducing drowsiness and hallucinations."
	color = "#FF00FF"
	chem_flags = CHEMICAL_RNG_GENERAL | CHEMICAL_RNG_FUN | CHEMICAL_GOAL_BOTANIST_HARVEST | CHEMICAL_GOAL_CHEMIST_USEFUL_MEDICINE

/datum/reagent/medicine/synaptizine/on_mob_life(mob/living/carbon/M, delta_time, times_fired)
	M.drowsyness = max(M.drowsyness - (5 * REM * delta_time), 0)
	M.AdjustStun(-20 * REM * delta_time)
	M.AdjustKnockdown(-20 * REM * delta_time)
	M.AdjustUnconscious(-20 * REM * delta_time)
	M.AdjustImmobilized(-20 * REM * delta_time)
	M.AdjustParalyzed(-20 * REM * delta_time)
	if(holder.has_reagent(/datum/reagent/toxin/mindbreaker))
		holder.remove_reagent(/datum/reagent/toxin/mindbreaker, 5 * REM * delta_time)
	M.hallucination = max(M.hallucination - (10 * REM * delta_time), 0)
	if(DT_PROB(16, delta_time))
		M.adjustToxLoss(1, 0)
		. = TRUE
	..()

/datum/reagent/medicine/synaphydramine
	name = "Diphen-Synaptizine"
	description = "Reduces drowsiness, hallucinations, and Histamine from body."
	color = "#EC536D" // rgb: 236, 83, 109
	chem_flags = CHEMICAL_RNG_GENERAL | CHEMICAL_RNG_FUN | CHEMICAL_RNG_BOTANY

/datum/reagent/medicine/synaphydramine/on_mob_life(mob/living/carbon/M, delta_time, times_fired)
	M.drowsyness = max(M.drowsyness - (5 * REM * delta_time), 0)
	if(holder.has_reagent(/datum/reagent/toxin/mindbreaker))
		holder.remove_reagent(/datum/reagent/toxin/mindbreaker, 5 * REM * delta_time)
	if(holder.has_reagent(/datum/reagent/toxin/histamine))
		holder.remove_reagent(/datum/reagent/toxin/histamine, 5 * REM * delta_time)
	M.hallucination = max(M.hallucination - (10 * REM * delta_time), 0)
	if(DT_PROB(16, delta_time))
		M.adjustToxLoss(1, 0)
		. = TRUE
	..()

/datum/reagent/medicine/inacusiate
	name = "Inacusiate"
	description = "Instantly restores all hearing to the patient, but does not cure deafness."
	color = "#606060" //inacusiate is light grey, oculine is dark grey
	chem_flags = CHEMICAL_RNG_GENERAL | CHEMICAL_RNG_FUN | CHEMICAL_RNG_BOTANY | CHEMICAL_GOAL_CHEMIST_USEFUL_MEDICINE

/datum/reagent/medicine/inacusiate/on_mob_life(mob/living/carbon/M, delta_time, times_fired)
	M.restoreEars()
	..()

/datum/reagent/medicine/cryoxadone
	name = "Cryoxadone"
	description = "A chemical mixture with almost magical healing powers. Its main limitation is that the patient's body temperature must be under 270K for it to metabolise correctly."
	color = "#0000C8"
	chem_flags = CHEMICAL_RNG_GENERAL | CHEMICAL_RNG_FUN | CHEMICAL_RNG_BOTANY | CHEMICAL_GOAL_BARTENDER_SERVING
	taste_description = "blue"

/datum/reagent/medicine/cryoxadone/on_mob_life(mob/living/carbon/M, delta_time, times_fired)
	var/power = -0.00003 * (M.bodytemperature ** 2) + 3
	if(M.bodytemperature < T0C)
		M.adjustOxyLoss(-3 * power * REM * delta_time, 0)
		M.adjustBruteLoss(-power * REM * delta_time, 0)
		M.adjustFireLoss(-power * REM * delta_time, 0)
		M.adjustToxLoss(-power * REM * delta_time, 0, TRUE) //heals TOXINLOVERs
		M.adjustCloneLoss(-power * REM * delta_time, 0)
		/*
		for(var/i in M.all_wounds)
			var/datum/wound/iter_wound = i
			iter_wound.on_xadone(power * REAGENTS_EFFECT_MULTIPLIER * delta_time)
		*/
		REMOVE_TRAIT(M, TRAIT_DISFIGURED, TRAIT_GENERIC) //fixes common causes for disfiguration
		. = TRUE
	metabolization_rate = REAGENTS_METABOLISM * (0.00001 * (M.bodytemperature ** 2) + 0.5)//Metabolism rate is reduced in colder body temps making it more effective
	..()

/datum/reagent/medicine/clonexadone
	name = "Clonexadone"
	description = "A chemical that derives from Cryoxadone. It specializes in healing clone damage, but nothing else. Requires very cold temperatures to properly metabolize, and metabolizes quicker than cryoxadone."
	color = "#3D3DC6"
	chem_flags = CHEMICAL_RNG_GENERAL | CHEMICAL_RNG_FUN | CHEMICAL_RNG_BOTANY
	taste_description = "muscle"
	metabolization_rate = 1.5 * REAGENTS_METABOLISM

/datum/reagent/medicine/clonexadone/on_mob_life(mob/living/carbon/M, delta_time, times_fired)
	if(M.bodytemperature < T0C)
		M.adjustCloneLoss((0.00006 * (M.bodytemperature ** 2) - 6) * REM * delta_time, 0)
		REMOVE_TRAIT(M, TRAIT_DISFIGURED, TRAIT_GENERIC)
		. = TRUE
	metabolization_rate = REAGENTS_METABOLISM * (0.000015 * (M.bodytemperature ** 2) + 0.75)//Metabolism rate is reduced in colder body temps making it more effective
	..()

/datum/reagent/medicine/pyroxadone
	name = "Pyroxadone"
	description = "A mixture of cryoxadone and slime jelly, that apparently inverses the requirement for its activation."
	color = "#f7832a"
	chem_flags = CHEMICAL_RNG_GENERAL | CHEMICAL_RNG_FUN | CHEMICAL_RNG_BOTANY
	taste_description = "spicy jelly"

/datum/reagent/medicine/pyroxadone/on_mob_life(mob/living/carbon/M, delta_time, times_fired)
	if(M.bodytemperature > BODYTEMP_HEAT_DAMAGE_LIMIT)
		metabolization_rate = 0.2 // It metabolises effectively when the body is taking heat damage
		var/power = 0
		switch(M.bodytemperature)
			if(BODYTEMP_HEAT_DAMAGE_LIMIT to 400)
				power = 2
			if(400 to 460)
				power = 3
			else
				power = 5
		if(M.on_fire)
			power *= 2

		M.adjustOxyLoss(-2 * power * REM * delta_time, FALSE)
		M.adjustBruteLoss(-power * REM * delta_time, FALSE)
		M.adjustFireLoss(-1.5 * power * REM * delta_time, FALSE)
		M.adjustToxLoss(-power * REM * delta_time, FALSE, TRUE)
		M.adjustCloneLoss(-power * REM * delta_time, FALSE)
		/*
		for(var/i in M.all_wounds)
			var/datum/wound/iter_wound = i
			iter_wound.on_xadone(power * REAGENTS_EFFECT_MULTIPLIER * delta_time)
		*/
		REMOVE_TRAIT(M, TRAIT_DISFIGURED, TRAIT_GENERIC)
		. = TRUE
	else //If not the right temperature for pyroxadone to work
		metabolization_rate = REAGENTS_METABOLISM
	..()

/datum/reagent/medicine/rezadone
	name = "Rezadone"
	description = "A powder derived from fish toxin, Rezadone can effectively treat genetic damage as well as restoring minor wounds. Overdose will cause intense nausea and minor toxin damage."
	reagent_state = SOLID
	color = "#669900" // rgb: 102, 153, 0
	chem_flags = CHEMICAL_RNG_GENERAL | CHEMICAL_RNG_FUN | CHEMICAL_RNG_BOTANY
	overdose_threshold = 30
	taste_description = "fish"

/datum/reagent/medicine/rezadone/on_mob_life(mob/living/carbon/M, delta_time, times_fired)
	M.setCloneLoss(0) //Rezadone is almost never used in favor of cryoxadone. Hopefully this will change that. // No such luck so far
	M.heal_bodypart_damage(1 * REM * delta_time, 1 * REM * delta_time)
	REMOVE_TRAIT(M, TRAIT_DISFIGURED, TRAIT_GENERIC)
	..()
	. = TRUE

/datum/reagent/medicine/rezadone/overdose_process(mob/living/M, delta_time, times_fired)
	M.adjustToxLoss(1 * REM * delta_time, 0)
	M.Dizzy(5 * REM * delta_time)
	M.Jitter(5 * REM * delta_time)
	..()
	. = TRUE

/datum/reagent/medicine/rezadone/expose_mob(mob/living/M, method=TOUCH, reac_volume)
	. = ..()
	if(iscarbon(M))
		var/mob/living/carbon/patient = M
		if(reac_volume >= 5 && HAS_TRAIT_FROM(patient, TRAIT_HUSK, "burn") && patient.getFireLoss() < THRESHOLD_UNHUSK) //One carp yields 12u rezadone.
			patient.cure_husk("burn")
			patient.visible_message(span_nicegreen("[patient]'s body rapidly absorbs moisture from the environment, taking on a more healthy appearance."))

/datum/reagent/medicine/spaceacillin
	name = "Spaceacillin"
	description = "Spaceacillin will prevent a patient from conventionally spreading any diseases they are currently infected with."
	color = "#E1F2E6"
	chem_flags = CHEMICAL_RNG_GENERAL | CHEMICAL_RNG_FUN | CHEMICAL_RNG_BOTANY | CHEMICAL_GOAL_CHEMIST_USEFUL_MEDICINE
	metabolization_rate = 0.1 * REAGENTS_METABOLISM

//Goon Chems. Ported mainly from Goonstation. Easily mixable (or not so easily) and provide a variety of effects.
/datum/reagent/medicine/silver_sulfadiazine
	name = "Silver Sulfadiazine"
	description = "If used in patch-based applications, immediately restores burn wounds as well as restoring more over time. If ingested through other means, deals minor toxin damage."
	reagent_state = LIQUID
	color = "#C8A5DC"
	chem_flags = CHEMICAL_RNG_GENERAL | CHEMICAL_RNG_FUN | CHEMICAL_RNG_BOTANY | CHEMICAL_GOAL_CHEMIST_USEFUL_MEDICINE
	metabolization_rate = 2.5 * REAGENTS_METABOLISM
	overdose_threshold = 100
	metabolite = /datum/reagent/metabolite/medicine/silver_sulfadiazine

/datum/reagent/medicine/silver_sulfadiazine/expose_mob(mob/living/M, method=TOUCH, reac_volume, show_message = 1, touch_protection, obj/item/bodypart/affecting)
	if(iscarbon(M) && M.stat != DEAD)
		if(method in list(INGEST, VAPOR, INJECT))
			M.adjustToxLoss(0.5*reac_volume)
			if(show_message)
				to_chat(M, span_warning("You don't feel so good..."))
		else if(M.getFireLoss() && method == PATCH)
			if(affecting.heal_damage(burn = reac_volume))
				M.update_damage_overlays()
			M.adjustStaminaLoss(reac_volume*2)
			if(show_message)
				to_chat(M, span_danger("You feel your burns healing! It stings like hell!"))
			M.emote("scream")
			SEND_SIGNAL(M, COMSIG_ADD_MOOD_EVENT, "painful_medicine", /datum/mood_event/painful_medicine)
	..()

/datum/reagent/medicine/silver_sulfadiazine/on_mob_life(mob/living/carbon/M, delta_time, times_fired)
	M.adjustFireLoss(-0.5 * REM * delta_time, 0)
	..()
	. = TRUE

/datum/reagent/medicine/silver_sulfadiazine/overdose_process(mob/living/carbon/M, delta_time, times_fired)
	M.adjustOxyLoss(1 * REM * delta_time, 0)
	..()
	. = TRUE

/datum/reagent/medicine/oxandrolone
	name = "Oxandrolone"
	description = "Stimulates the healing of severe burns. Overdosing will double the effectiveness of healing the burns while also dealing toxin and liver damage"
	reagent_state = LIQUID
	color = "#1E8BFF"
	chem_flags = CHEMICAL_RNG_GENERAL | CHEMICAL_RNG_FUN | CHEMICAL_RNG_BOTANY | CHEMICAL_GOAL_CHEMIST_USEFUL_MEDICINE
	metabolization_rate = 0.5 * REAGENTS_METABOLISM
	overdose_threshold = 25

/datum/reagent/medicine/oxandrolone/on_mob_life(mob/living/carbon/M, delta_time, times_fired)
	M.adjustFireLoss(-3 * REM * delta_time, 0)
	if(M.getFireLoss() != 0)
		M.adjustStaminaLoss(3 * REM * delta_time, FALSE)
	..()
	. = TRUE

/datum/reagent/medicine/oxandrolone/overdose_process(mob/living/M, delta_time, times_fired)
	M.adjustFireLoss(-3 * REM * delta_time, 0)
	M.adjustToxLoss(3 * REM * delta_time, 0)
	M.adjustOrganLoss(ORGAN_SLOT_LIVER, 2)
	..()

/datum/reagent/medicine/styptic_powder
	name = "Styptic Powder"
	description = "If used in patch-based applications, immediately restores bruising. If ingested through other means, deals minor toxin damage."
	reagent_state = LIQUID
	color = "#FF9696"
	chem_flags = CHEMICAL_RNG_GENERAL | CHEMICAL_RNG_FUN | CHEMICAL_RNG_BOTANY | CHEMICAL_GOAL_CHEMIST_USEFUL_MEDICINE
	metabolization_rate = 2.5 * REAGENTS_METABOLISM
	overdose_threshold = 100
	metabolite = /datum/reagent/metabolite/medicine/styptic_powder

/datum/reagent/medicine/styptic_powder/expose_mob(mob/living/M, method=TOUCH, reac_volume, show_message = 1, touch_protection, obj/item/bodypart/affecting)
	if(iscarbon(M) && M.stat != DEAD)
		if(method in list(INGEST, VAPOR, INJECT))
			M.adjustToxLoss(0.5*reac_volume)
			if(show_message)
				to_chat(M, span_warning("You don't feel so good..."))
		else if(M.getBruteLoss() && method == PATCH)
			if(affecting.heal_damage(reac_volume))
				M.update_damage_overlays()
			M.adjustStaminaLoss(reac_volume*2)
			if(show_message)
				to_chat(M, span_danger("You feel your bruises healing! It stings like hell!"))
			M.emote("scream")
			SEND_SIGNAL(M, COMSIG_ADD_MOOD_EVENT, "painful_medicine", /datum/mood_event/painful_medicine)
	return ..()


/datum/reagent/medicine/styptic_powder/on_mob_life(mob/living/carbon/M, delta_time, times_fired)
	M.adjustBruteLoss(-0.5 * REM * delta_time, 0)
	..()
	. = 1

/datum/reagent/medicine/styptic_powder/overdose_process(mob/living/carbon/M, delta_time, times_fired)
	M.adjustOxyLoss(1 * REM * delta_time, 0)
	..()
	. = 1

/datum/reagent/medicine/salglu_solution
	name = "Saline-Glucose Solution"
	description = "Has a 33% chance per metabolism cycle to heal brute and burn damage. Can be used as a temporary blood substitute."
	reagent_state = LIQUID
	color = "#DCDCDC"
	chem_flags = CHEMICAL_RNG_GENERAL | CHEMICAL_RNG_FUN | CHEMICAL_RNG_BOTANY
	metabolization_rate = 0.5 * REAGENTS_METABOLISM
	overdose_threshold = 60
	taste_description = "sweetness and salt"
	var/last_added = 0
	var/maximum_reachable = BLOOD_VOLUME_NORMAL - 10	//So that normal blood regeneration can continue with salglu active

/datum/reagent/medicine/salglu_solution/on_mob_life(mob/living/carbon/M, delta_time, times_fired)
	if(last_added)
		M.blood_volume -= last_added
		last_added = 0
	if(M.blood_volume < maximum_reachable)	//Can only up to double your effective blood level.
		var/amount_to_add = min(M.blood_volume, 5*volume)
		var/new_blood_level = min(M.blood_volume + amount_to_add, maximum_reachable)
		last_added = new_blood_level - M.blood_volume
		M.blood_volume = new_blood_level
	if(DT_PROB(18, delta_time))
		M.adjustBruteLoss(-0.5, 0)
		M.adjustFireLoss(-0.5, 0)
		. = TRUE
	..()

/datum/reagent/medicine/salglu_solution/overdose_process(mob/living/M, delta_time, times_fired)
	if(DT_PROB(1.5, delta_time))
		to_chat(M, span_warning("You feel salty."))
		holder.add_reagent(/datum/reagent/consumable/sodiumchloride, 1)
		holder.remove_reagent(/datum/reagent/medicine/salglu_solution, 0.5)
	else if(DT_PROB(1.5, delta_time))
		to_chat(M, span_warning("You feel sweet."))
		holder.add_reagent(/datum/reagent/consumable/sugar, 1)
		holder.remove_reagent(/datum/reagent/medicine/salglu_solution, 0.5)
	if(DT_PROB(18, delta_time))
		M.adjustBruteLoss(0.5, FALSE, FALSE, BODYTYPE_ORGANIC)
		M.adjustFireLoss(0.5, FALSE, FALSE, BODYTYPE_ORGANIC)
		. = TRUE
	..()

/datum/reagent/medicine/mine_salve
	name = "Miner's Salve"
	description = "A powerful painkiller. Restores bruising and burns in addition to making the patient believe they are fully healed."
	reagent_state = LIQUID
	color = "#6D6374"
	chem_flags = CHEMICAL_RNG_GENERAL | CHEMICAL_RNG_FUN | CHEMICAL_RNG_BOTANY
	metabolization_rate = 0.4 * REAGENTS_METABOLISM

/datum/reagent/medicine/mine_salve/on_mob_life(mob/living/carbon/C, delta_time, times_fired)
	C.hal_screwyhud = SCREWYHUD_HEALTHY
	C.adjustBruteLoss(-0.25 * REM * delta_time, 0)
	C.adjustFireLoss(-0.25 * REM * delta_time, 0)
	..()
	return TRUE

/datum/reagent/medicine/mine_salve/expose_mob(mob/living/M, method=TOUCH, reac_volume, show_message = 1)
	if(iscarbon(M) && M.stat != DEAD)
		if(method in list(INGEST, VAPOR, INJECT))
			M.adjust_nutrition(-5)
			if(show_message)
				to_chat(M, span_warning("Your stomach feels empty and cramps!"))
		else
			var/mob/living/carbon/C = M
			for(var/s in C.surgeries)
				var/datum/surgery/S = s
				S.speed_modifier = max(0.1, S.speed_modifier)
				// +10% surgery speed on each step, useful while operating in less-than-perfect conditions

			if(show_message)
				to_chat(M, span_danger("You feel your wounds fade away to nothing!") )
	..()

/datum/reagent/medicine/mine_salve/on_mob_end_metabolize(mob/living/M)
	if(iscarbon(M))
		var/mob/living/carbon/N = M
		N.hal_screwyhud = SCREWYHUD_NONE
	..()

/datum/reagent/medicine/synthflesh
	name = "Synthflesh"
	description = "Has a 100% chance of instantly healing brute and burn damage. One unit of the chemical will heal one point of damage. Touch application only."
	reagent_state = LIQUID
	color = "#FFEBEB"
	chem_flags = CHEMICAL_RNG_GENERAL | CHEMICAL_RNG_FUN | CHEMICAL_RNG_BOTANY | CHEMICAL_GOAL_CHEMIST_USEFUL_MEDICINE
	metabolization_rate = 2.5 * REAGENTS_METABOLISM
	overdose_threshold = 125

/datum/reagent/medicine/synthflesh/expose_mob(mob/living/M, method=TOUCH, reac_volume, show_message = 1, touch_protection, obj/item/bodypart/affecting)
	if(iscarbon(M))
		if(M.stat == DEAD)
			show_message = FALSE
		if(method == PATCH)
			//you could be targeting a limb that doesnt exist while applying the patch, so lets avoid a runtime
			if(affecting.heal_damage(brute = reac_volume, burn = reac_volume))
				M.update_damage_overlays()
			M.adjustStaminaLoss(reac_volume*2)
			if(show_message)
				to_chat(M, span_danger("You feel your burns and bruises healing! It stings like hell!"))
			SEND_SIGNAL(M, COMSIG_ADD_MOOD_EVENT, "painful_medicine", /datum/mood_event/painful_medicine)
			M.emote("scream")
			//Has to be at less than THRESHOLD_UNHUSK burn damage and have at least 100 synthflesh (currently inside the body + amount now being applied). Corpses dont metabolize.
			if(HAS_TRAIT_FROM(M, TRAIT_HUSK, "burn") && M.getFireLoss() < THRESHOLD_UNHUSK && (M.reagents.get_reagent_amount(/datum/reagent/medicine/synthflesh) + reac_volume) >= 100)
				M.cure_husk("burn")
				M.visible_message(span_nicegreen("You successfully replace most of the burnt off flesh of [M]."))
	..()

/datum/reagent/medicine/synthflesh/on_mob_life(mob/living/carbon/M, delta_time, times_fired)
	M.adjustFireLoss(-0.5*REM, 0)
	M.adjustBruteLoss(-0.5*REM, 0)
	..()
	. = 1

/datum/reagent/medicine/synthflesh/overdose_process(mob/living/M)
	M.adjustToxLoss(2*REM, 0)
	..()
	. = 1

/datum/reagent/medicine/charcoal
	name = "Charcoal"
	description = "Heals mild toxin damage as well as slowly removing any other chemicals the patient has in their bloodstream."
	reagent_state = LIQUID
	color = "#000000"
	chem_flags = CHEMICAL_RNG_GENERAL | CHEMICAL_RNG_FUN | CHEMICAL_RNG_BOTANY | CHEMICAL_GOAL_BOTANIST_HARVEST
	metabolization_rate = REAGENTS_METABOLISM
	taste_description = "ash"
	process_flags = ORGANIC

/datum/reagent/medicine/charcoal/on_mob_life(mob/living/carbon/M, delta_time, times_fired)
	M.adjustToxLoss(-1 * REM * delta_time, 0)
	. = 1
	for(var/datum/reagent/R in M.reagents.reagent_list)
		if(R != src)
			M.reagents.remove_reagent(R.type, 0.75 * REM * delta_time)
	..()

/datum/reagent/medicine/system_cleaner
	name = "System Cleaner"
	description = "Neutralizes harmful chemical compounds inside synthetic systems."
	reagent_state = LIQUID
	color = "#F1C40F"
	chem_flags = CHEMICAL_RNG_GENERAL | CHEMICAL_RNG_FUN | CHEMICAL_RNG_BOTANY
	metabolization_rate = 0.5 * REAGENTS_METABOLISM
	process_flags = SYNTHETIC

/datum/reagent/medicine/system_cleaner/on_mob_life(mob/living/carbon/M, delta_time, times_fired)
	M.adjustToxLoss(-2 * REM * delta_time, 0)
	. = 1
	for(var/datum/reagent/R in M.reagents.reagent_list)
		if(R != src)
			M.reagents.remove_reagent(R.type, 1 * REM * delta_time)
	..()

/datum/reagent/medicine/liquid_solder
	name = "Liquid Solder"
	description = "Repairs brain damage in synthetics."
	color = "#727272"
	chem_flags = CHEMICAL_RNG_GENERAL | CHEMICAL_RNG_FUN | CHEMICAL_RNG_BOTANY
	taste_description = "metallic"
	process_flags = SYNTHETIC

/datum/reagent/medicine/liquid_solder/on_mob_life(mob/living/M)
	M.adjustOrganLoss(ORGAN_SLOT_BRAIN, (-3*REM))
	M.hallucination = max(0, M.hallucination - 10)
	if(iscarbon(M))
		var/mob/living/carbon/C = M
		if(prob(30) && C.has_trauma_type(BRAIN_TRAUMA_SPECIAL))
			C.cure_trauma_type(BRAIN_TRAUMA_SPECIAL)
		if(prob(10) && C.has_trauma_type(BRAIN_TRAUMA_MILD))
			C.cure_trauma_type(BRAIN_TRAUMA_MILD)
	..()

/datum/reagent/medicine/omnizine
	name = "Omnizine"
	description = "Slowly heals all damage types. Overdose will cause damage in all types instead."
	reagent_state = LIQUID
	color = "#DCDCDC"
	chem_flags = CHEMICAL_RNG_GENERAL | CHEMICAL_RNG_FUN | CHEMICAL_GOAL_BOTANIST_HARVEST
	metabolization_rate = 0.25 * REAGENTS_METABOLISM
	overdose_threshold = 30
	var/healing = 0.5

/datum/reagent/medicine/omnizine/on_mob_life(mob/living/carbon/M, delta_time, times_fired)
	M.adjustToxLoss(-healing * REM * delta_time, 0)
	M.adjustOxyLoss(-healing * REM * delta_time, 0)
	M.adjustBruteLoss(-healing * REM * delta_time, 0)
	M.adjustFireLoss(-healing * REM * delta_time, 0)
	..()
	. = TRUE

/datum/reagent/medicine/omnizine/overdose_process(mob/living/M, delta_time, times_fired)
	M.adjustToxLoss(1.5 * REM * delta_time, FALSE)
	M.adjustOxyLoss(1.5 * REM * delta_time, FALSE)
	M.adjustBruteLoss(1.5 * REM * delta_time, FALSE, FALSE, BODYTYPE_ORGANIC)
	M.adjustFireLoss(1.5 * REM * delta_time, FALSE, FALSE, BODYTYPE_ORGANIC)
	..()
	. = TRUE

/datum/reagent/medicine/calomel
	name = "Calomel"
	description = "Quickly purges the body of all chemicals. Toxin damage is dealt if the patient is in good condition."
	reagent_state = LIQUID
	color = "#19C832"
	chem_flags = CHEMICAL_RNG_GENERAL | CHEMICAL_RNG_FUN | CHEMICAL_RNG_BOTANY
	metabolization_rate = 0.5 * REAGENTS_METABOLISM
	taste_description = "acid"

/datum/reagent/medicine/calomel/on_mob_life(mob/living/carbon/M, delta_time, times_fired)
	for(var/datum/reagent/R in M.reagents.reagent_list)
		if(R != src)
			M.reagents.remove_reagent(R.type, 2.5 * REM * delta_time)
	if(M.health > 20)
		M.adjustToxLoss(2.5 * REM * delta_time, 0)
		. = TRUE
	..()

/datum/reagent/medicine/potass_iodide
	name = "Potassium Iodide"
	description = "Efficiently restores low radiation damage."
	reagent_state = LIQUID
	color = "#BAA15D"
	chem_flags = CHEMICAL_RNG_GENERAL | CHEMICAL_RNG_FUN | CHEMICAL_RNG_BOTANY | CHEMICAL_GOAL_BOTANIST_HARVEST
	metabolization_rate = 2 * REAGENTS_METABOLISM

/datum/reagent/medicine/potass_iodide/on_mob_life(mob/living/carbon/M, delta_time, times_fired)
	if(M.radiation > 0)
		M.radiation -= min(8 * REM * delta_time, M.radiation)
	..()

/datum/reagent/medicine/pen_acid
	name = "Pentetic Acid"
	description = "Reduces massive amounts of radiation and toxin damage while purging other chemicals from the body."
	reagent_state = LIQUID
	color = "#E6FFF0"
	chem_flags = CHEMICAL_RNG_GENERAL | CHEMICAL_RNG_FUN | CHEMICAL_RNG_BOTANY | CHEMICAL_GOAL_CHEMIST_USEFUL_MEDICINE
	metabolization_rate = 0.5 * REAGENTS_METABOLISM

/datum/reagent/medicine/pen_acid/on_mob_life(mob/living/carbon/M, delta_time, times_fired)
	M.radiation -= (max(M.radiation - RAD_MOB_SAFE, 0) / 50) * REM * delta_time
	M.adjustToxLoss(-2 * REM * delta_time, 0)
	for(var/datum/reagent/R in M.reagents.reagent_list)
		if(R != src)
			M.reagents.remove_reagent(R.type, 2 * REM * delta_time)
	..()
	. = TRUE

/datum/reagent/medicine/sal_acid
	name = "Salicyclic Acid"
	description = "Stimulates the healing of severe bruises. Overdosing will double the effectiveness of healing the bruises while also dealing toxin and liver damage."
	reagent_state = LIQUID
	color = "#D2D2D2"
	chem_flags = CHEMICAL_RNG_GENERAL | CHEMICAL_RNG_FUN | CHEMICAL_RNG_BOTANY | CHEMICAL_GOAL_CHEMIST_USEFUL_MEDICINE
	metabolization_rate = 0.5 * REAGENTS_METABOLISM
	overdose_threshold = 25


/datum/reagent/medicine/sal_acid/on_mob_life(mob/living/carbon/M, delta_time, times_fired)
	M.adjustBruteLoss(-3 * REM * delta_time, 0)
	if(M.getBruteLoss() != 0)
		M.adjustStaminaLoss(3 * REM * delta_time, FALSE)
	..()
	. = TRUE

/datum/reagent/medicine/sal_acid/overdose_process(mob/living/M, delta_time, times_fired)
	M.adjustBruteLoss(-3 * REM * delta_time, 0)
	M.adjustToxLoss(3 * REM * delta_time, 0)
	M.adjustOrganLoss(ORGAN_SLOT_LIVER, 2)
	..()

/datum/reagent/medicine/salbutamol
	name = "Salbutamol"
	description = "Rapidly restores oxygen deprivation as well as preventing more of it to an extent."
	reagent_state = LIQUID
	color = "#00FFFF"
	chem_flags = CHEMICAL_RNG_GENERAL | CHEMICAL_RNG_FUN | CHEMICAL_RNG_BOTANY | CHEMICAL_GOAL_CHEMIST_USEFUL_MEDICINE
	overdose_threshold = 25
	metabolization_rate = 0.25 * REAGENTS_METABOLISM

/datum/reagent/medicine/salbutamol/on_mob_life(mob/living/carbon/M, delta_time, times_fired)
	M.adjustOxyLoss(-3 * REM * delta_time, 0)
	if(M.losebreath >= 4)
		M.losebreath -= 2 * REM * delta_time
	..()
	. = TRUE

/datum/reagent/medicine/salbutamol/overdose_process(mob/living/M)
	M.reagents.add_reagent(/datum/reagent/toxin/histamine, 1)
	M.reagents.remove_reagent(/datum/reagent/medicine/salbutamol, 1)
	..()

/datum/reagent/medicine/perfluorodecalin
	name = "Perfluorodecalin"
	description = "Extremely rapidly restores oxygen deprivation, but causes minor toxin damage. Overdose causes significant damage to the lungs."
	reagent_state = LIQUID
	color = "#FF6464"
	chem_flags = CHEMICAL_RNG_GENERAL | CHEMICAL_RNG_FUN | CHEMICAL_RNG_BOTANY
	overdose_threshold = 30
	metabolization_rate = 0.25 * REAGENTS_METABOLISM

/datum/reagent/medicine/perfluorodecalin/on_mob_life(mob/living/carbon/human/M)
	M.adjustOrganLoss(ORGAN_SLOT_LUNGS, -2)
	M.adjustOxyLoss(-10*REM, 0)
	M.adjustToxLoss(1*REM, 0)
	..()
	return TRUE

/datum/reagent/medicine/perfluorodecalin/overdose_process(mob/living/M)
	M.adjustOrganLoss(ORGAN_SLOT_HEART, 2)
	..()

/datum/reagent/medicine/ephedrine
	name = "Ephedrine"
	description = "Increases stun resistance and movement speed. Overdose deals toxin damage and inhibits breathing."
	reagent_state = LIQUID
	color = "#D2FFFA"
	chem_flags = CHEMICAL_RNG_GENERAL | CHEMICAL_RNG_FUN | CHEMICAL_RNG_BOTANY
	metabolization_rate = 0.5 * REAGENTS_METABOLISM
	overdose_threshold = 30
	addiction_threshold = 25

/datum/reagent/medicine/ephedrine/on_mob_metabolize(mob/living/L)
	..()
	L.add_movespeed_modifier(/datum/movespeed_modifier/reagent/ephedrine)//mildly slower than meth

/datum/reagent/medicine/ephedrine/on_mob_end_metabolize(mob/living/L)
	L.remove_movespeed_modifier(/datum/movespeed_modifier/reagent/ephedrine)
	..()

/datum/reagent/medicine/ephedrine/on_mob_life(mob/living/carbon/M, delta_time, times_fired)
	if(DT_PROB(10, delta_time) && iscarbon(M))
		var/obj/item/I = M.get_active_held_item()
		if(I && M.dropItemToGround(I))
			to_chat(M, span_notice("Your hands spaz out and you drop what you were holding!"))
			M.Jitter(10)

	M.AdjustAllImmobility(-20 * REM * delta_time)
	M.adjustStaminaLoss(-10 * REM * delta_time, FALSE)
	..()
	return TRUE

/datum/reagent/medicine/ephedrine/overdose_process(mob/living/M, delta_time, times_fired)
	if(DT_PROB(1, delta_time) && iscarbon(M))
		var/datum/disease/D = new /datum/disease/heart_failure
		M.ForceContractDisease(D)
		to_chat(M, span_userdanger("You're pretty sure you just felt your heart stop for a second there.."))
		M.playsound_local(M, 'sound/effects/singlebeat.ogg', 100, 0)

	if(DT_PROB(3.5, delta_time))
		to_chat(M, span_notice("[pick("Your head pounds.", "You feel a tight pain in your chest.", "You find it hard to stay still.", "You feel your heart practically beating out of your chest.")]"))

	if(DT_PROB(18, delta_time))
		M.adjustToxLoss(1, 0)
		M.losebreath++
		. = TRUE
	return TRUE

/datum/reagent/medicine/ephedrine/addiction_act_stage1(mob/living/M)
	if(prob(3) && iscarbon(M))
		M.visible_message(span_danger("[M] starts having a seizure!"), span_userdanger("You have a seizure!"))
		M.Unconscious(100)
		M.Jitter(350)

	if(prob(33))
		M.adjustToxLoss(2*REM, 0)
		M.losebreath += 2
		. = 1
	..()

/datum/reagent/medicine/ephedrine/addiction_act_stage2(mob/living/M)
	if(prob(6) && iscarbon(M))
		M.visible_message(span_danger("[M] starts having a seizure!"), span_userdanger("You have a seizure!"))
		M.Unconscious(100)
		M.Jitter(350)

	if(prob(33))
		M.adjustToxLoss(3*REM, 0)
		M.losebreath += 3
		. = 1
	..()

/datum/reagent/medicine/ephedrine/addiction_act_stage3(mob/living/M)
	if(prob(12) && iscarbon(M))
		M.visible_message(span_danger("[M] starts having a seizure!"), span_userdanger("You have a seizure!"))
		M.Unconscious(100)
		M.Jitter(350)

	if(prob(33))
		M.adjustToxLoss(4*REM, 0)
		M.losebreath += 4
		. = 1
	..()

/datum/reagent/medicine/ephedrine/addiction_act_stage4(mob/living/M)
	if(prob(24) && iscarbon(M))
		M.visible_message(span_danger("[M] starts having a seizure!"), span_userdanger("You have a seizure!"))
		M.Unconscious(100)
		M.Jitter(350)

	if(prob(33))
		M.adjustToxLoss(5*REM, 0)
		M.losebreath += 5
		. = 1
	..()

/datum/reagent/medicine/diphenhydramine
	name = "Diphenhydramine"
	description = "Rapidly purges the body of Histamine and reduces jitteriness. Slight chance of causing drowsiness."
	reagent_state = LIQUID
	color = "#64FFE6"
	chem_flags = CHEMICAL_RNG_GENERAL | CHEMICAL_RNG_FUN | CHEMICAL_RNG_BOTANY
	metabolization_rate = 0.5 * REAGENTS_METABOLISM

/datum/reagent/medicine/diphenhydramine/on_mob_life(mob/living/carbon/M, delta_time, times_fired)
	if(DT_PROB(5, delta_time))
		M.drowsyness++
	M.jitteriness -= 1 * REM * delta_time
	holder.remove_reagent(/datum/reagent/toxin/histamine, 3 * REM * delta_time)
	..()

/datum/reagent/medicine/morphine
	name = "Morphine"
	description = "A painkiller that allows the patient to move at full speed even in bulky objects. Causes drowsiness and eventually unconsciousness in high doses. Overdose will cause a variety of effects, ranging from minor to lethal."
	reagent_state = LIQUID
	color = "#A9FBFB"
	chem_flags = CHEMICAL_RNG_GENERAL | CHEMICAL_RNG_FUN | CHEMICAL_GOAL_BOTANIST_HARVEST
	metabolization_rate = 0.5 * REAGENTS_METABOLISM
	overdose_threshold = 30
	addiction_threshold = 25

/datum/reagent/medicine/morphine/on_mob_metabolize(mob/living/L)
	..()
	L.add_movespeed_mod_immunities(type, /datum/movespeed_modifier/damage_slowdown)

/datum/reagent/medicine/morphine/on_mob_end_metabolize(mob/living/L)
	L.remove_movespeed_mod_immunities(type, /datum/movespeed_modifier/damage_slowdown)
	..()

/datum/reagent/medicine/morphine/on_mob_life(mob/living/carbon/M, delta_time, times_fired)
	switch(current_cycle)
		if(11)
			to_chat(M, span_warning("You start to feel tired...") )
		if(12 to 24)
			M.drowsyness += 1 * REM * delta_time
		if(24 to INFINITY)
			M.Sleeping(40 * REM * delta_time)
			. = TRUE
	..()

/datum/reagent/medicine/morphine/overdose_process(mob/living/M, delta_time, times_fired)
	if(DT_PROB(18, delta_time))
		M.drop_all_held_items()
		M.Dizzy(2)
		M.Jitter(2)
	..()

/datum/reagent/medicine/morphine/addiction_act_stage1(mob/living/M)
	if(prob(33))
		M.drop_all_held_items()
		M.Jitter(2)
	..()

/datum/reagent/medicine/morphine/addiction_act_stage2(mob/living/M)
	if(prob(33))
		M.drop_all_held_items()
		M.adjustToxLoss(1*REM, 0)
		. = 1
		M.Dizzy(3)
		M.Jitter(3)
	..()

/datum/reagent/medicine/morphine/addiction_act_stage3(mob/living/M)
	if(prob(33))
		M.drop_all_held_items()
		M.adjustToxLoss(2*REM, 0)
		. = 1
		M.Dizzy(4)
		M.Jitter(4)
	..()

/datum/reagent/medicine/morphine/addiction_act_stage4(mob/living/M)
	if(prob(33))
		M.drop_all_held_items()
		M.adjustToxLoss(3*REM, 0)
		. = 1
		M.Dizzy(5)
		M.Jitter(5)
	..()

/datum/reagent/medicine/oculine
	name = "Oculine"
	description = "Quickly restores eye damage, cures nearsightedness, and has a chance to restore vision to the blind."
	reagent_state = LIQUID
	color = "#404040" //ucline is dark grey, inacusiate is light grey
	chem_flags = CHEMICAL_RNG_GENERAL | CHEMICAL_RNG_FUN | CHEMICAL_RNG_BOTANY | CHEMICAL_GOAL_BOTANIST_HARVEST | CHEMICAL_GOAL_CHEMIST_USEFUL_MEDICINE
	metabolization_rate = 0.25 * REAGENTS_METABOLISM
	taste_description = "dull toxin"

/datum/reagent/medicine/oculine/on_mob_life(mob/living/carbon/M, delta_time, times_fired)
	var/obj/item/organ/eyes/eyes = M.get_organ_slot(ORGAN_SLOT_EYES)
	if (!eyes)
		return
	eyes.applyOrganDamage(-2 * REM * delta_time)
	if(HAS_TRAIT_FROM(M, TRAIT_BLIND, EYE_DAMAGE))
		if(DT_PROB(10, delta_time))
			to_chat(M, span_warning("Your vision slowly returns..."))
			M.cure_blind(EYE_DAMAGE)
			M.cure_nearsighted(EYE_DAMAGE)
			M.blur_eyes(35)

	else if(HAS_TRAIT_FROM(M, TRAIT_NEARSIGHT, EYE_DAMAGE))
		to_chat(M, span_warning("The blackness in your peripheral vision fades."))
		M.cure_nearsighted(EYE_DAMAGE)
		M.blur_eyes(10)
	else if(M.is_blind() || M.eye_blurry)
		M.set_blindness(0)
		M.set_blurriness(0)
	..()

/datum/reagent/medicine/atropine
	name = "Atropine"
	description = "If a patient is in critical condition, rapidly heals all damage types as well as regulating oxygen in the body. Excellent for stabilizing wounded patients. Has the side effects of causing minor confusion."
	reagent_state = LIQUID
	color = "#1D3535" //slightly more blue, like epinephrine
	chem_flags = CHEMICAL_RNG_GENERAL | CHEMICAL_RNG_FUN | CHEMICAL_RNG_BOTANY | CHEMICAL_GOAL_CHEMIST_USEFUL_MEDICINE
	metabolization_rate = 0.25 * REAGENTS_METABOLISM
	overdose_threshold = 15

/datum/reagent/medicine/atropine/on_mob_life(mob/living/carbon/M, delta_time, times_fired)
	if(M.health <= 20)
		M.adjustToxLoss(-4* REM * delta_time, 0)
		M.adjustBruteLoss(-4* REM * delta_time, 0)
		M.adjustFireLoss(-4* REM * delta_time, 0)
		M.adjustOxyLoss(-5* REM * delta_time, 0)
		. = TRUE
	M.losebreath = 0
	if(DT_PROB(10, delta_time))
		M.Dizzy(5)
		M.Jitter(5)
		M.drop_all_held_items()
	..()

/datum/reagent/medicine/atropine/overdose_process(mob/living/M, delta_time, times_fired)
	M.reagents.add_reagent(/datum/reagent/toxin/histamine, 3 * REM * delta_time)
	M.reagents.remove_reagent(/datum/reagent/medicine/atropine, 2 * REM * delta_time)
	. = TRUE
	M.Dizzy(1 * REM * delta_time)
	M.Jitter(1 * REM * delta_time)
	..()

/datum/reagent/medicine/epinephrine
	name = "Epinephrine"
	description = "Minor boost to stun resistance. Slowly heals damage if a patient is in critical condition, as well as regulating oxygen loss. Overdose causes weakness and toxin damage."
	reagent_state = LIQUID
	color = "#D2FFFA"
	chem_flags = CHEMICAL_RNG_GENERAL | CHEMICAL_RNG_FUN | CHEMICAL_RNG_BOTANY
	metabolization_rate = 0.25 * REAGENTS_METABOLISM
	overdose_threshold = 30

/datum/reagent/medicine/epinephrine/on_mob_metabolize(mob/living/carbon/M)
	..()
	ADD_TRAIT(M, TRAIT_NOCRITDAMAGE, type)

/datum/reagent/medicine/epinephrine/on_mob_end_metabolize(mob/living/carbon/M)
	REMOVE_TRAIT(M, TRAIT_NOCRITDAMAGE, type)
	..()

/datum/reagent/medicine/epinephrine/on_mob_life(mob/living/carbon/M, delta_time, times_fired)
	if(M.health <= M.crit_threshold)
		M.adjustToxLoss(-0.5 * REM * delta_time, 0)
		M.adjustBruteLoss(-0.5 * REM * delta_time, 0)
		M.adjustFireLoss(-0.5 * REM * delta_time, 0)
		M.adjustOxyLoss(-0.5 * REM * delta_time, 0)
	if(M.losebreath >= 4)
		M.losebreath -= 2 * REM * delta_time
	if(M.losebreath < 0)
		M.losebreath = 0
	M.adjustStaminaLoss(-0.5 * REM * delta_time, 0)
	. = TRUE
	if(DT_PROB(10, delta_time))
		M.AdjustAllImmobility(-20)
	..()

/datum/reagent/medicine/epinephrine/overdose_process(mob/living/M, delta_time, times_fired)
	if(DT_PROB(18, REM * delta_time))
		M.adjustStaminaLoss(2.5, 0)
		M.adjustToxLoss(1, 0)
		M.losebreath++
		. = TRUE
	..()

/datum/reagent/medicine/strange_reagent
	name = "Strange Reagent"
	description = "A miracle drug capable of bringing the dead back to life. Only functions when applied by patch or spray, if the target has less than 100 brute and burn damage (independent of one another) and hasn't been husked. Causes slight damage to the living."
	reagent_state = LIQUID
	color = "#A0E85E"
	chem_flags = CHEMICAL_RNG_GENERAL | CHEMICAL_RNG_FUN | CHEMICAL_RNG_BOTANY
	metabolization_rate = 0.5 * REAGENTS_METABOLISM
	taste_description = "magnets"

/datum/reagent/medicine/strange_reagent/expose_mob(mob/living/M, method=TOUCH, reac_volume)
	if(M.stat == DEAD)
		if(M.suiciding || M.ishellbound()) //they are never coming back
			M.visible_message(span_warning("[M]'s body does not react..."))
			return
		if(M.getBruteLoss() >= 100 || M.getFireLoss() >= 100 || HAS_TRAIT(M, TRAIT_HUSK)) //body is too damaged to be revived
			M.visible_message(span_warning("[M]'s body convulses a bit, and then falls still once more."))
			M.do_jitter_animation(10)
			return
		else
			M.visible_message(span_warning("[M]'s body starts convulsing!"))
			M.notify_ghost_cloning(source = M)
			M.do_jitter_animation(10)
			addtimer(CALLBACK(M, TYPE_PROC_REF(/mob/living/carbon, do_jitter_animation), 10), 40) //jitter immediately, then again after 4 and 8 seconds
			addtimer(CALLBACK(M, TYPE_PROC_REF(/mob/living/carbon, do_jitter_animation), 10), 80)
			addtimer(CALLBACK(M, TYPE_PROC_REF(/mob/living, revive), FALSE, FALSE), 100)
	..()

/datum/reagent/medicine/strange_reagent/on_mob_life(mob/living/carbon/M, delta_time, times_fired)
	M.adjustBruteLoss(0.5* REM * delta_time, FALSE)
	M.adjustFireLoss(0.5* REM * delta_time, FALSE)
	..()
	. = TRUE

/datum/reagent/medicine/mannitol
	name = "Mannitol"
	description = "Efficiently restores brain damage."
	color = "#A0A0A0" //mannitol is light grey, neurine is lighter grey"
	chem_flags = CHEMICAL_RNG_GENERAL | CHEMICAL_RNG_FUN | CHEMICAL_RNG_BOTANY | CHEMICAL_GOAL_BOTANIST_HARVEST | CHEMICAL_GOAL_CHEMIST_USEFUL_MEDICINE

/datum/reagent/medicine/mannitol/on_mob_add(mob/living/carbon/C)
	if(HAS_TRAIT(C, TRAIT_BRAIN_TUMOR))
		overdose_threshold = 35 // special overdose to brain tumor quirker
	..()


/datum/reagent/medicine/mannitol/on_mob_life(mob/living/carbon/C, delta_time, times_fired)
	if(HAS_TRAIT(C, TRAIT_BRAIN_TUMOR)) // to brain tumor quirk holder
		SEND_SIGNAL(C, COMSIG_ADD_MOOD_EVENT, "brain_tumor", /datum/mood_event/brain_tumor_mannitol)
		if(!overdosed)
			C.adjustOrganLoss(ORGAN_SLOT_BRAIN, -0.5 * REM * delta_time)
	else // to ordinary people
		C.adjustOrganLoss(ORGAN_SLOT_BRAIN, -2 * REM * delta_time)
	..()

/datum/reagent/medicine/mannitol/overdose_process(mob/living/carbon/C)
	if(HAS_TRAIT(C, TRAIT_BRAIN_TUMOR))
		if(prob(10))
			C.adjustOrganLoss(ORGAN_SLOT_BRAIN, -0.1*REM)
	..()


/datum/reagent/medicine/neurine
	name = "Neurine"
	description = "Reacts with neural tissue, helping reform damaged connections. Can cure minor traumas."
	color = "#C0C0C0" //ditto
	chem_flags = CHEMICAL_RNG_GENERAL | CHEMICAL_RNG_FUN | CHEMICAL_RNG_BOTANY

/datum/reagent/medicine/neurine/on_mob_life(mob/living/carbon/C, delta_time, times_fired)
	if(holder.has_reagent(/datum/reagent/consumable/ethanol/neurotoxin))
		holder.remove_reagent(/datum/reagent/consumable/ethanol/neurotoxin, 5 * REM * delta_time)
	if(DT_PROB(8, delta_time))
		C.cure_trauma_type(resilience = TRAUMA_RESILIENCE_BASIC)
	..()

/datum/reagent/medicine/mutadone
	name = "Mutadone"
	description = "Removes jitteriness and restores genetic defects."
	color = "#5096C8"
	chem_flags = CHEMICAL_RNG_GENERAL | CHEMICAL_RNG_FUN | CHEMICAL_RNG_BOTANY | CHEMICAL_GOAL_CHEMIST_USEFUL_MEDICINE
	taste_description = "acid"

/datum/reagent/medicine/mutadone/on_mob_life(mob/living/carbon/M, delta_time, times_fired)
	M.jitteriness = 0
	if(M.has_dna())
		M.dna.remove_all_mutations(mutadone = TRUE)
	if(!QDELETED(M)) //We were a monkey, now a human
		..()

/datum/reagent/medicine/antihol
	name = "Antihol"
	description = "Purges alcoholic substance from the patient's body and eliminates its side effects. Less effective in light drinkers."
	color = "#00B4C8"
	chem_flags = CHEMICAL_RNG_GENERAL | CHEMICAL_RNG_FUN | CHEMICAL_RNG_BOTANY
	taste_description = "raw egg"

/datum/reagent/medicine/antihol/on_mob_life(mob/living/carbon/M, delta_time, times_fired)
	if(!HAS_TRAIT(M, TRAIT_LIGHT_DRINKER))
		M.dizziness = 0
		M.drowsyness = 0
		M.slurring = 0
		M.confused = 0
		if(ishuman(M))
			var/mob/living/carbon/human/H = M
			H.drunkenness = max(H.drunkenness - (10 * REM * delta_time), 0)
	M.reagents.remove_all_type(/datum/reagent/consumable/ethanol, 3 * REM * delta_time, FALSE, TRUE)
	M.adjustToxLoss(-0.2 * REM * delta_time, 0)
	..()
	. = TRUE

//Stimulants. Used in Adrenal Implant
/datum/reagent/medicine/amphetamine
	name = "Amphetamine"
	description = "Increases stun resistance and movement speed in addition to restoring minor damage and weakness. Overdose causes weakness and toxin damage."
	color = "#78008C"
	chem_flags = CHEMICAL_RNG_GENERAL | CHEMICAL_RNG_FUN | CHEMICAL_RNG_BOTANY
	metabolization_rate = 0.5 * REAGENTS_METABOLISM
	overdose_threshold = 60

/datum/reagent/medicine/amphetamine/on_mob_metabolize(mob/living/L)
	..()
	L.add_movespeed_modifier(/datum/movespeed_modifier/reagent/amphetamine)

/datum/reagent/medicine/amphetamine/on_mob_end_metabolize(mob/living/L)
	L.remove_movespeed_modifier(/datum/movespeed_modifier/reagent/amphetamine)
	..()

/datum/reagent/medicine/amphetamine/on_mob_life(mob/living/carbon/M, delta_time, times_fired)
	if(M.health < 50 && M.health > 0)
		M.adjustOxyLoss(-1 * REM * delta_time, FALSE)
		M.adjustToxLoss(-1 * REM * delta_time, FALSE)
		M.adjustBruteLoss(-1 * REM * delta_time, FALSE)
		M.adjustFireLoss(-1 * REM * delta_time, FALSE)
	M.AdjustAllImmobility(-60 * REM * delta_time)
	M.adjustStaminaLoss(-35 * REM * delta_time, FALSE)
	..()
	. = TRUE

/datum/reagent/medicine/amphetamine/overdose_process(mob/living/M, delta_time, times_fired)
	if(DT_PROB(18, delta_time))
		M.adjustStaminaLoss(2.5, 0)
		M.adjustToxLoss(1, 0)
		M.losebreath++
		. = TRUE
	..()


//Pump-Up for Pump-Up Stimpack
/datum/reagent/medicine/pumpup
	name = "Pump-Up"
	description = "Makes you immune to damage slowdown, resistant to all other kinds of slowdown and gives a minor speed boost. Overdose causes weakness and toxin damage."
	color = "#78008C"
	chem_flags = CHEMICAL_RNG_GENERAL | CHEMICAL_RNG_FUN | CHEMICAL_RNG_BOTANY
	metabolization_rate = 0.5 * REAGENTS_METABOLISM
	overdose_threshold = 60

/datum/reagent/medicine/pumpup/on_mob_life(mob/living/carbon/M as mob)
	M.AdjustAllImmobility(-80, FALSE)
	M.adjustStaminaLoss(-80, 0)
	M.Jitter(300)
	..()
	return TRUE

/datum/reagent/medicine/pumpup/on_mob_metabolize(mob/living/L)
	..()
	ADD_TRAIT(L, TRAIT_SLEEPIMMUNE, type)
	ADD_TRAIT(L, TRAIT_STUNRESISTANCE, type)
	ADD_TRAIT(L, TRAIT_IGNOREDAMAGESLOWDOWN, type)

/datum/reagent/medicine/pumpup/on_mob_end_metabolize(mob/living/L)
	..()
	REMOVE_TRAIT(L, TRAIT_SLEEPIMMUNE, type)
	REMOVE_TRAIT(L, TRAIT_STUNRESISTANCE, type)
	REMOVE_TRAIT(L, TRAIT_IGNOREDAMAGESLOWDOWN, type)

/datum/reagent/medicine/pumpup/overdose_process(mob/living/M)
	if(prob(33))
		M.adjustStaminaLoss(2.5*REM, 0)
		M.adjustToxLoss(1*REM, 0)
		M.losebreath++
		. = 1
	..()


/datum/reagent/medicine/insulin
	name = "Insulin"
	description = "Increases sugar depletion rates."
	reagent_state = LIQUID
	color = "#FFFFF0"
	chem_flags = CHEMICAL_RNG_GENERAL | CHEMICAL_RNG_FUN | CHEMICAL_RNG_BOTANY
	metabolization_rate = 0.5 * REAGENTS_METABOLISM

/datum/reagent/medicine/insulin/on_mob_life(mob/living/carbon/M, delta_time, times_fired)
	if(M.AdjustSleeping(-20 * REM * delta_time))
		. = TRUE
	holder.remove_reagent(/datum/reagent/consumable/sugar, 3 * REM * delta_time)
	..()

//Trek Chems, used primarily by medibots. Only heals a specific damage type, but is very efficient.
/datum/reagent/medicine/bicaridine
	name = "Bicaridine"
	description = "Restores bruising. Overdose causes liver damage."
	reagent_state = LIQUID
	color = "#bf0000"
	chem_flags = CHEMICAL_RNG_GENERAL | CHEMICAL_RNG_FUN | CHEMICAL_GOAL_BOTANIST_HARVEST
	metabolization_rate = 0.5 * REAGENTS_METABOLISM
	metabolite = /datum/reagent/metabolite/medicine/bicaridine
	overdose_threshold = 30

/datum/reagent/medicine/bicaridine/on_mob_life(mob/living/carbon/M, delta_time, times_fired)
	M.adjustBruteLoss(-1 * REM * delta_time/METABOLITE_PENALTY(metabolite), 0)
	..()
	. = TRUE

/datum/reagent/medicine/bicaridine/overdose_process(mob/living/carbon/M, delta_time, times_fired)
	M.reagents.add_reagent(metabolite, 1)
	M.reagents.remove_reagent(/datum/reagent/medicine/bicaridine, 1)
	M.adjustOrganLoss(ORGAN_SLOT_LIVER, 1 * REM * delta_time)
	..()
	. = TRUE

/datum/reagent/medicine/dexalin
	name = "Dexalin"
	description = "Restores oxygen loss. Overdose causes it instead."
	reagent_state = LIQUID
	color = "#0080FF"
	chem_flags = CHEMICAL_RNG_GENERAL | CHEMICAL_RNG_FUN | CHEMICAL_RNG_BOTANY
	overdose_threshold = 30

/datum/reagent/medicine/dexalin/on_mob_life(mob/living/carbon/M, delta_time, times_fired)
	M.adjustOxyLoss(-1.5 * REM * delta_time, FALSE)
	..()
	. = TRUE

/datum/reagent/medicine/dexalin/overdose_process(mob/living/carbon/M, delta_time, times_fired)
	M.adjustOrganLoss(ORGAN_SLOT_HEART, 2 * REM * delta_time)
	..()
	. = TRUE

/datum/reagent/medicine/dexalinp
	name = "Dexalin Plus"
	description = "Restores oxygen loss. Overdose causes large amounts of damage to the heart. It is highly effective."
	reagent_state = LIQUID
	color = "#0040FF"
	chem_flags = CHEMICAL_RNG_GENERAL | CHEMICAL_RNG_FUN | CHEMICAL_RNG_BOTANY
	overdose_threshold = 25

/datum/reagent/medicine/dexalinp/on_mob_life(mob/living/carbon/M, delta_time, times_fired)
	M.adjustOxyLoss(-3 * REM * delta_time, 0)
	if(M.getOxyLoss() != 0)
		M.adjustStaminaLoss(3 * REM * delta_time, FALSE)
	..()
	. = TRUE

/datum/reagent/medicine/dexalinp/overdose_process(mob/living/carbon/M, delta_time, times_fired)
	M.adjustOrganLoss(ORGAN_SLOT_HEART, 4 * REM * delta_time)
	..()
	. = TRUE

/datum/reagent/medicine/kelotane
	name = "Kelotane"
	description = "Restores fire damage. Overdose causes liver damage."
	reagent_state = LIQUID
	color = "#FFa800"
	chem_flags = CHEMICAL_RNG_GENERAL | CHEMICAL_RNG_FUN | CHEMICAL_GOAL_BOTANIST_HARVEST
	metabolization_rate = 0.5 * REAGENTS_METABOLISM
	metabolite = /datum/reagent/metabolite/medicine/kelotane
	overdose_threshold = 30

/datum/reagent/medicine/kelotane/on_mob_life(mob/living/carbon/M, delta_time, times_fired)
	M.adjustFireLoss((-1 * REM * delta_time)/METABOLITE_PENALTY(metabolite), 0)
	..()
	. = TRUE

/datum/reagent/medicine/kelotane/overdose_process(mob/living/carbon/M, delta_time, times_fired)
	M.reagents.add_reagent(metabolite, 1)
	M.reagents.remove_reagent(/datum/reagent/medicine/kelotane, 1)
	M.adjustOrganLoss(ORGAN_SLOT_LIVER, 1 * REM * delta_time)
	..()
	. = TRUE

/datum/reagent/medicine/antitoxin
	name = "Anti-Toxin"
	description = "Heals toxin damage and removes toxins in the bloodstream. Overdose causes liver damage."
	reagent_state = LIQUID
	color = "#00a000"
	chem_flags = CHEMICAL_RNG_GENERAL | CHEMICAL_RNG_FUN | CHEMICAL_RNG_BOTANY | CHEMICAL_GOAL_CHEMIST_USEFUL_MEDICINE
	metabolization_rate = 0.5 * REAGENTS_METABOLISM
	taste_description = "a roll of gauze"
	metabolite = /datum/reagent/metabolite/medicine/antitoxin
	overdose_threshold = 30

/datum/reagent/medicine/antitoxin/on_mob_life(mob/living/carbon/M, delta_time, times_fired)
	M.adjustToxLoss((-1 * REM * delta_time)/METABOLITE_PENALTY(metabolite), 0)
	..()
	. = TRUE

/datum/reagent/medicine/antitoxin/overdose_process(mob/living/carbon/M, delta_time, times_fired)
	M.reagents.add_reagent(metabolite, 1)
	M.reagents.remove_reagent(/datum/reagent/medicine/antitoxin, 1)
	M.adjustOrganLoss(ORGAN_SLOT_LIVER, 1 * REM * delta_time)
	..()
	. = TRUE

/datum/reagent/medicine/carthatoline
	name = "Carthatoline"
	description = "Carthatoline is strong evacuant used to treat severe poisoning."
	reagent_state = LIQUID
	color = "#225722"
	chem_flags = CHEMICAL_RNG_GENERAL | CHEMICAL_RNG_FUN | CHEMICAL_RNG_BOTANY | CHEMICAL_GOAL_CHEMIST_USEFUL_MEDICINE
	overdose_threshold = 25

/datum/reagent/medicine/carthatoline/on_mob_life(mob/living/carbon/M, delta_time, times_fired)
	M.adjustToxLoss(-3 * REM * delta_time, 0)
	if(M.getToxLoss() && DT_PROB(5, delta_time))
		M.vomit(1)
	for(var/datum/reagent/toxin/R in M.reagents.reagent_list)
		M.reagents.remove_reagent(R.type,1)
	..()
	. = TRUE

/datum/reagent/medicine/carthatoline/overdose_process(mob/living/carbon/M, delta_time, times_fired)
	M.adjustOrganLoss(ORGAN_SLOT_BRAIN, 2 * REM * delta_time)
	..()
	. = TRUE

/datum/reagent/medicine/meclizine
	name = "Meclizine"
	description = "A medicine which prevents vomiting."
	reagent_state = LIQUID
	color = "#cecece"
	chem_flags = CHEMICAL_RNG_GENERAL | CHEMICAL_RNG_FUN | CHEMICAL_RNG_BOTANY
	metabolization_rate = 0.25 * REAGENTS_METABOLISM
	overdose_threshold = 25

/datum/reagent/medicine/meclizine/on_mob_life(mob/living/carbon/M, delta_time, times_fired)
	if(DT_PROB(5, delta_time))
		M.adjustToxLoss(-1 * REM * delta_time, 0)
	..()
	. = TRUE //Some other poor sod can do the rest, I just make chems

/datum/reagent/medicine/meclizine/overdose_process(mob/living/carbon/M, delta_time, times_fired)
	M.adjustToxLoss(2 * REM * delta_time, 0)
	M.adjustOrganLoss(ORGAN_SLOT_STOMACH, 2 * REM * delta_time)
	..()
	. = TRUE

/datum/reagent/medicine/meclizine/on_mob_metabolize(mob/living/M)
	..()
	ADD_TRAIT(M, TRAIT_NOVOMIT, type)

/datum/reagent/medicine/meclizine/on_mob_end_metabolize(mob/living/M)
	..()
	REMOVE_TRAIT(M, TRAIT_NOVOMIT, type)

/datum/reagent/medicine/hepanephrodaxon
	name = "Hepanephrodaxon"
	description = "Used to repair the common tissues involved in filtration."
	taste_description = "glue"
	reagent_state = LIQUID
	color = "#D2691E"
	chem_flags = CHEMICAL_RNG_GENERAL | CHEMICAL_RNG_FUN | CHEMICAL_RNG_BOTANY | CHEMICAL_GOAL_CHEMIST_USEFUL_MEDICINE
	metabolization_rate = REM * 3.75
	overdose_threshold = 10

/datum/reagent/medicine/hepanephrodaxon/on_mob_life(var/mob/living/carbon/M)
	var/repair_strength = 1
	var/obj/item/organ/liver/L = M.get_organ_slot(ORGAN_SLOT_LIVER)
	if(L.damage > 0)
		L.damage = max(L.damage - 4 * repair_strength, 0)
		M.confused = (2)
	M.adjustToxLoss(-6)
	..()
	. = 1

/datum/reagent/medicine/hepanephrodaxon/overdose_process(mob/living/M)
	M.adjustOrganLoss(ORGAN_SLOT_BRAIN, 2)
	M.confused = (2)
	..()
	. = 1

/datum/reagent/medicine/inaprovaline
	name = "Inaprovaline"
	description = "Stabilizes the breathing of patients. Good for those in critical condition."
	reagent_state = LIQUID
	color = "#A4D8D8"
	chem_flags = CHEMICAL_RNG_GENERAL | CHEMICAL_RNG_FUN | CHEMICAL_RNG_BOTANY

/datum/reagent/medicine/inaprovaline/on_mob_life(mob/living/carbon/M, delta_time, times_fired)
	if(M.losebreath >= 5)
		M.losebreath -= 5 * REM * delta_time
	..()

/datum/reagent/medicine/tricordrazine
	name = "Tricordrazine"
	description = "Has a high chance to heal all types of damage. Overdose causes toxin damage and liver damage."
	reagent_state = LIQUID
	color = "#707A00" //tricord's component chems mixed together, olive.
	chem_flags = CHEMICAL_RNG_GENERAL | CHEMICAL_RNG_FUN | CHEMICAL_RNG_BOTANY
	metabolization_rate = 3 * REAGENTS_METABOLISM
	overdose_threshold = 30
	taste_description = "grossness"
	metabolite = /datum/reagent/metabolite/medicine/tricordrazine

/datum/reagent/medicine/tricordrazine/on_mob_life(mob/living/carbon/M, delta_time, times_fired)
	M.adjustBruteLoss((-2 * REM * delta_time)/METABOLITE_PENALTY(metabolite), 0)
	M.adjustFireLoss((-2 * REM * delta_time)/METABOLITE_PENALTY(metabolite), 0)
	M.adjustToxLoss((-2 * REM * delta_time)/METABOLITE_PENALTY(metabolite), 0)
	M.adjustOxyLoss((-2 * REM * delta_time)/METABOLITE_PENALTY(metabolite), 0)
	. = TRUE
	..()

/datum/reagent/medicine/tricordrazine/overdose_process(mob/living/carbon/M, delta_time, times_fired)
	M.adjustToxLoss(2*REM, 0)
	M.adjustOrganLoss(ORGAN_SLOT_BRAIN, 1 * REM * delta_time)
	..()
	. = 1

/datum/reagent/medicine/regen_jelly
	name = "Regenerative Jelly"
	description = "Gradually regenerates all types of damage, without harming slime anatomy."
	reagent_state = LIQUID
	color = "#CC23FF"
	chem_flags = CHEMICAL_RNG_GENERAL | CHEMICAL_RNG_FUN | CHEMICAL_RNG_BOTANY
	taste_description = "jelly"

/datum/reagent/medicine/regen_jelly/on_mob_life(mob/living/carbon/M, delta_time, times_fired)
	M.adjustBruteLoss(-0.5* REM * delta_time, 0)
	M.adjustFireLoss(-0.5* REM * delta_time, 0)
	M.adjustOxyLoss(-0.5* REM * delta_time, 0)
	M.adjustToxLoss(-0.5* REM * delta_time, 0, TRUE) //heals TOXINLOVERs
	..()
	. = TRUE

/datum/reagent/medicine/syndicate_nanites //Used exclusively by Syndicate medical cyborgs
	name = "Restorative Nanites"
	description = "Miniature medical robots that swiftly restore bodily damage."
	reagent_state = SOLID
	color = "#555555"
	chem_flags = CHEMICAL_NOT_SYNTH | CHEMICAL_RNG_GENERAL | CHEMICAL_RNG_FUN | CHEMICAL_RNG_BOTANY
	overdose_threshold = 30
	process_flags = ORGANIC | SYNTHETIC

/datum/reagent/medicine/syndicate_nanites/on_mob_life(mob/living/carbon/M, delta_time, times_fired)
	M.adjustBruteLoss(-5 * REM * delta_time, 0) //A ton of healing - this is a 50 telecrystal investment.
	M.adjustFireLoss(-5 * REM * delta_time, 0)
	M.adjustOxyLoss(-15 * REM * delta_time, 0)
	M.adjustToxLoss(-5 * REM * delta_time, 0)
	M.adjustOrganLoss(ORGAN_SLOT_BRAIN, -15 * REM * delta_time)
	M.adjustCloneLoss(-3 * REM * delta_time, 0)
	if (M.blood_volume < BLOOD_VOLUME_NORMAL)
		M.blood_volume = max(M.blood_volume, min(M.blood_volume + 4, BLOOD_VOLUME_NORMAL))
	..()
	. = TRUE

/datum/reagent/medicine/syndicate_nanites/overdose_process(mob/living/carbon/M, delta_time, times_fired) //wtb flavortext messages that hint that you're vomitting up robots
	if(DT_PROB(13, delta_time))
		M.reagents.remove_reagent(type, metabolization_rate*15) // ~5 units at a rate of 0.4 but i wanted a nice number in code
		M.vomit(20) // nanite safety protocols make your body expel them to prevent harmies
	..()
	. = TRUE

/datum/reagent/medicine/earthsblood //Created by ambrosia gaia plants
	name = "Earthsblood"
	description = "Ichor from an extremely powerful plant. Great for restoring wounds, but it's a little heavy on the brain."
	color = "#FFAF00"
	chem_flags = CHEMICAL_RNG_GENERAL | CHEMICAL_RNG_FUN | CHEMICAL_RNG_BOTANY | CHEMICAL_GOAL_BOTANIST_HARVEST
	overdose_threshold = 25

/datum/reagent/medicine/earthsblood/on_mob_life(mob/living/carbon/M, delta_time, times_fired)
	M.adjustBruteLoss(-3 * REM * delta_time, 0)
	M.adjustFireLoss(-3 * REM * delta_time, 0)
	M.adjustOxyLoss(-15 * REM * delta_time, 0)
	M.adjustToxLoss(-3 * REM * delta_time, 0)
	M.adjustOrganLoss(ORGAN_SLOT_BRAIN, 1 * REM * delta_time, 150) //This does, after all, come from ambrosia, and the most powerful ambrosia in existence, at that!
	M.adjustCloneLoss(-1 * REM * delta_time, 0)
	M.adjustStaminaLoss(-30 * REM * delta_time, 0)
	M.jitteriness = clamp(M.jitteriness + (3 * REM * delta_time), 0, 30)
	M.druggy = clamp(M.druggy + (10 * REM * delta_time), 0, 15 * REM * delta_time) //See above
	..()
	. = TRUE

/datum/reagent/medicine/earthsblood/overdose_process(mob/living/affected_mob, delta_time, times_fired)
	affected_mob.hallucination = clamp(affected_mob.hallucination + (5 * REM * delta_time), 0, 60)
	affected_mob.adjustToxLoss(5 * REM * delta_time, 0)
	..()
	. = TRUE

/datum/reagent/medicine/haloperidol
	name = "Haloperidol"
	description = "Increases depletion rates for most stimulating/hallucinogenic drugs. Reduces druggy effects and jitteriness. Severe stamina regeneration penalty, causes drowsiness. Small chance of brain damage."
	reagent_state = LIQUID
	color = "#27870a"
	chem_flags = CHEMICAL_RNG_GENERAL | CHEMICAL_RNG_FUN | CHEMICAL_GOAL_BOTANIST_HARVEST
	metabolization_rate = 0.4 * REAGENTS_METABOLISM

/datum/reagent/medicine/haloperidol/on_mob_life(mob/living/carbon/M, delta_time, times_fired)
	for(var/datum/reagent/drug/R in M.reagents.reagent_list)
		M.reagents.remove_reagent(R.type, 5 * REM * delta_time)
	M.drowsyness += 2 * REM * delta_time
	if(M.jitteriness >= 3)
		M.jitteriness -= 3 * REM * delta_time
	if (M.hallucination >= 5)
		M.hallucination -= 5 * REM * delta_time
	if(DT_PROB(10, delta_time))
		M.adjustOrganLoss(ORGAN_SLOT_BRAIN, 1, 50)
	M.adjustStaminaLoss(2.5 * REM * delta_time, 0)
	..()
	return TRUE

/datum/reagent/medicine/lavaland_extract
	name = "Lavaland Extract"
	description = "An extract of lavaland atmospheric and mineral elements. Heals the user in small doses, but is extremely toxic otherwise."
	color = "#6B372E" //dark and red like lavaland
	chem_flags = CHEMICAL_NOT_SYNTH | CHEMICAL_RNG_GENERAL | CHEMICAL_RNG_FUN | CHEMICAL_RNG_BOTANY
	overdose_threshold = 3 //To prevent people stacking massive amounts of a very strong healing reagent

/datum/reagent/medicine/lavaland_extract/on_mob_life(mob/living/carbon/M, delta_time, times_fired)
	M.heal_bodypart_damage(5 * REM * delta_time, 5 * REM * delta_time, 0)
	..()
	return TRUE

/datum/reagent/medicine/lavaland_extract/overdose_process(mob/living/carbon/M, delta_time, times_fired)
	M.adjustBruteLoss(3 * REM * delta_time, FALSE, FALSE, BODYTYPE_ORGANIC)
	M.adjustFireLoss(3 * REM * delta_time, FALSE, FALSE, BODYTYPE_ORGANIC)
	M.adjustToxLoss(3 * REM * delta_time, FALSE, FALSE)
	..()
	return TRUE

//used for changeling's adrenaline power
/datum/reagent/medicine/changelingadrenaline
	name = "Changeling Adrenaline"
	description = "Reduces the duration of unconsciousness, knockdown and stuns. Restores stamina, but deals toxin damage when overdosed."
	color = "#C1151D"
	chem_flags = CHEMICAL_RNG_GENERAL | CHEMICAL_RNG_FUN | CHEMICAL_RNG_BOTANY
	overdose_threshold = 30

/datum/reagent/medicine/changelingadrenaline/on_mob_life(mob/living/carbon/metabolizer, delta_time, times_fired)
	..()
	metabolizer.AdjustAllImmobility(-20 * REM * delta_time)
	metabolizer.adjustStaminaLoss(-20 * REM * delta_time, 0)
	return TRUE

/datum/reagent/medicine/changelingadrenaline/overdose_process(mob/living/metabolizer, delta_time, times_fired)
	metabolizer.adjustToxLoss(2 * REM * delta_time, 0)
	..()
	return TRUE

/datum/reagent/medicine/changelinghaste
	name = "Changeling Haste"
	description = "Drastically increases movement speed."
	color = "#AE151D"
	chem_flags = CHEMICAL_RNG_GENERAL | CHEMICAL_RNG_FUN | CHEMICAL_RNG_BOTANY
	metabolization_rate = 2.5 * REAGENTS_METABOLISM

/datum/reagent/medicine/changelinghaste/on_mob_metabolize(mob/living/L)
	..()
	L.add_movespeed_modifier(/datum/movespeed_modifier/reagent/changelinghaste)

/datum/reagent/medicine/changelinghaste/on_mob_end_metabolize(mob/living/L)
	L.remove_movespeed_modifier(/datum/movespeed_modifier/reagent/changelinghaste)
	..()

/datum/reagent/medicine/corazone
	// Heart attack code will not do damage if corazone is present
	// because it's SPACE MAGIC ASPIRIN
	name = "Corazone"
	description = "A medication used to assist in healing the heart and to stabalize the heart and liver."
	color = "#F49797"
	chem_flags = CHEMICAL_RNG_GENERAL | CHEMICAL_RNG_FUN | CHEMICAL_RNG_BOTANY
	overdose_threshold = 20
	self_consuming = TRUE

/datum/reagent/medicine/corazone/on_mob_metabolize(mob/living/M)
	M.adjustOrganLoss(ORGAN_SLOT_HEART, -1.5)
	..()
	ADD_TRAIT(M, TRAIT_STABLEHEART, type)
	ADD_TRAIT(M, TRAIT_STABLELIVER, type)

/datum/reagent/medicine/corazone/on_mob_end_metabolize(mob/living/M)
	REMOVE_TRAIT(M, TRAIT_STABLEHEART, type)
	REMOVE_TRAIT(M, TRAIT_STABLELIVER, type)
	..()

/datum/reagent/medicine/corazone/overdose_process(mob/living/M)
	M.reagents.add_reagent(/datum/reagent/toxin/histamine, 1)
	M.reagents.remove_reagent(/datum/reagent/medicine/corazone, 1)
	..()

/datum/reagent/medicine/muscle_stimulant
	name = "Muscle Stimulant"
	description = "A potent chemical that allows someone under its influence to be at full physical ability even when under massive amounts of pain."
	chem_flags = CHEMICAL_RNG_GENERAL | CHEMICAL_RNG_FUN | CHEMICAL_RNG_BOTANY

/datum/reagent/medicine/muscle_stimulant/on_mob_metabolize(mob/living/L)
	. = ..()
	L.add_movespeed_mod_immunities(type, /datum/movespeed_modifier/damage_slowdown)

/datum/reagent/medicine/muscle_stimulant/on_mob_end_metabolize(mob/living/L)
	. = ..()
	L.remove_movespeed_mod_immunities(type, /datum/movespeed_modifier/damage_slowdown)

/datum/reagent/medicine/modafinil
	name = "Modafinil"
	description = "Long-lasting sleep suppressant that very slightly reduces stun and knockdown times. Overdosing has horrendous side effects and deals lethal oxygen damage, will knock you unconscious if not dealt with."
	reagent_state = LIQUID
	color = "#BEF7D8" // palish blue white
	chem_flags = CHEMICAL_RNG_GENERAL | CHEMICAL_RNG_FUN | CHEMICAL_RNG_BOTANY
	metabolization_rate = 0.1 * REAGENTS_METABOLISM
	overdose_threshold = 20 // with the random effects this might be awesome or might kill you at less than 10u (extensively tested)
	taste_description = "salt" // it actually does taste salty
	var/overdose_progress = 0 // to track overdose progress

/datum/reagent/medicine/modafinil/on_mob_metabolize(mob/living/M)
	ADD_TRAIT(M, TRAIT_SLEEPIMMUNE, type)
	..()
	M.add_movespeed_modifier(/datum/movespeed_modifier/reagent/modafil)

/datum/reagent/medicine/modafinil/on_mob_end_metabolize(mob/living/M)
	REMOVE_TRAIT(M, TRAIT_SLEEPIMMUNE, type)
	..()
	M.remove_movespeed_modifier(/datum/movespeed_modifier/reagent/modafil)

/datum/reagent/medicine/modafinil/on_mob_life(mob/living/carbon/metabolizer, delta_time, times_fired)
	if(!overdosed) // We do not want any effects on OD
		overdose_threshold = overdose_threshold + ((rand(-10, 10) / 10) * REM * delta_time) // for extra fun
		metabolizer.AdjustAllImmobility(-20 * REM * delta_time)
		metabolizer.adjustStaminaLoss(-15 * REM * delta_time, 0)
		metabolizer.Jitter(1)
		metabolization_rate = 0.005 * REAGENTS_METABOLISM * rand(5, 20) // randomizes metabolism between 0.02 and 0.08 per second
		. = TRUE
	..()

/datum/reagent/medicine/modafinil/overdose_start(mob/living/M)
	to_chat(M, span_userdanger("You feel awfully out of breath and jittery!"))
	metabolization_rate = 0.025 * REAGENTS_METABOLISM // sets metabolism to 0.005 per second on overdose

/datum/reagent/medicine/modafinil/overdose_process(mob/living/M, delta_time, times_fired)
	overdose_progress++
	switch(overdose_progress)
		if(1 to 40)
			M.jitteriness = min(M.jitteriness + (1 * REM * delta_time), 10)
			M.stuttering = min(M.stuttering + (1 * REM * delta_time), 10)
			M.Dizzy(5 * REM * delta_time)
			if(DT_PROB(30, delta_time))
				M.losebreath++
		if(41 to 80)
			M.adjustOxyLoss(0.1 * REM * delta_time, 0)
			M.adjustStaminaLoss(0.1 * REM * delta_time, 0)
			M.jitteriness = min(M.jitteriness + (1 * REM * delta_time), 20)
			M.stuttering = min(M.stuttering + (1 * REM * delta_time), 20)
			M.Dizzy(10 * REM * delta_time)
			if(DT_PROB(30, delta_time))
				M.losebreath++
			if(DT_PROB(10, delta_time))
				to_chat(M, "You have a sudden fit!")
				M.emote("moan")
				M.Paralyze(20) // you should be in a bad spot at this point unless epipen has been used
		if(81)
			to_chat(M, "You feel too exhausted to continue!") // at this point you will eventually die unless you get charcoal
			M.adjustOxyLoss(0.1 * REM * delta_time, 0)
			M.adjustStaminaLoss(0.1 * REM * delta_time, 0)
		if(82 to INFINITY)
			M.Sleeping(100 * REM * delta_time)
			M.adjustOxyLoss(1.5 * REM * delta_time, 0)
			M.adjustStaminaLoss(1.5 * REM * delta_time, 0)
	..()
	return TRUE

/datum/reagent/medicine/psicodine
	name = "Psicodine"
	description = "Suppresses anxiety and other various forms of mental distress. Overdose causes hallucinations and minor toxin damage."
	reagent_state = LIQUID
	color = "#07E79E"
	chem_flags = CHEMICAL_RNG_GENERAL | CHEMICAL_RNG_FUN | CHEMICAL_RNG_BOTANY
	metabolization_rate = 0.25 * REAGENTS_METABOLISM
	overdose_threshold = 30
	var/dosage

/datum/reagent/medicine/psicodine/on_mob_metabolize(mob/living/L)
	..()
	ADD_TRAIT(L, TRAIT_FEARLESS, type)

/datum/reagent/medicine/psicodine/on_mob_end_metabolize(mob/living/L)
	REMOVE_TRAIT(L, TRAIT_FEARLESS, type)
	..()

/datum/reagent/medicine/psicodine/on_mob_life(mob/living/carbon/M, delta_time, times_fired)
	dosage++
	M.jitteriness = max(M.jitteriness - (6 * REM * delta_time), 0)
	M.dizziness = max(M.dizziness - (6 * REM * delta_time), 0)
	M.confused = max(M.confused - (6 * REM * delta_time), 0)
	M.disgust = max(M.disgust - (6 * REM * delta_time), 0)
	var/datum/component/mood/mood = M.GetComponent(/datum/component/mood)
	if(mood != null && mood.sanity <= SANITY_NEUTRAL) // only take effect if in negative sanity and then...
		mood.setSanity(min(mood.sanity + (5 * REM * delta_time), SANITY_NEUTRAL)) // set minimum to prevent unwanted spiking over neutral
	..()
	. = TRUE

/datum/reagent/medicine/psicodine/overdose_process(mob/living/M, delta_time, times_fired)
	M.hallucination = clamp(M.hallucination + (5 * REM * delta_time), 0, 60)
	M.adjustToxLoss(1 * REM * delta_time, 0)
	..()
	. = TRUE

/datum/reagent/medicine/silibinin
	name = "Silibinin"
	description = "A thistle derrived hepatoprotective flavolignan mixture that help reverse damage to the liver."
	reagent_state = SOLID
	color = "#FFFFD0"
	chem_flags = CHEMICAL_RNG_GENERAL | CHEMICAL_RNG_FUN | CHEMICAL_RNG_BOTANY | CHEMICAL_GOAL_BOTANIST_HARVEST
	metabolization_rate = 1.5 * REAGENTS_METABOLISM

/datum/reagent/medicine/silibinin/on_mob_life(mob/living/carbon/M, delta_time, times_fired)
	M.adjustOrganLoss(ORGAN_SLOT_LIVER, -2 * REM * delta_time)//Add a chance to cure liver trauma once implemented.
	..()
	. = TRUE

/datum/reagent/medicine/polypyr  //This is intended to be an ingredient in advanced chems.
	name = "Polypyrylium Oligomers"
	description = "A purple mixture of short polyelectrolyte chains not easily synthesized in the laboratory. It is a powerful pharmaceutical drug which provides minor healing and prevents bloodloss, making it incredibly useful for the synthesis of other drugs."
	reagent_state = SOLID
	color = "#9423FF"
	chem_flags = CHEMICAL_RNG_GENERAL | CHEMICAL_RNG_FUN | CHEMICAL_RNG_BOTANY | CHEMICAL_GOAL_BOTANIST_HARVEST
	metabolization_rate = 0.25 * REAGENTS_METABOLISM
	overdose_threshold = 50
	taste_description = "numbing bitterness"

/datum/reagent/medicine/polypyr/on_mob_life(mob/living/carbon/M, delta_time, times_fired) //I wanted a collection of small positive effects, this is as hard to obtain as coniine after all.
	. = ..()
	M.adjustOrganLoss(ORGAN_SLOT_LUNGS, -0.25 * REM * delta_time)
	M.adjustBruteLoss(-0.35 * REM * delta_time, 0)
	if(ishuman(M))
		var/mob/living/carbon/human/H = M
		H.cauterise_wounds(0.1)
	return TRUE

/datum/reagent/medicine/polypyr/expose_mob(mob/living/M, method=TOUCH, reac_volume)
	if(method == TOUCH || method == VAPOR)
		if(M && ishuman(M) && reac_volume >= 0.5)
			var/mob/living/carbon/human/H = M
			H.hair_color = "92f"
			H.facial_hair_color = "92f"
			H.update_hair()

/datum/reagent/medicine/polypyr/overdose_process(mob/living/M, delta_time, times_fired)
	M.adjustOrganLoss(ORGAN_SLOT_LUNGS, 0.5 * REM * delta_time)
	..()
	. = TRUE

/datum/reagent/medicine/stabilizing_nanites
	name = "Stabilizing nanites"
	description = "Rapidly heals a patient out of crit by regenerating damaged cells and causing blood to clot, preventing bleeding. Nanites distribution in the blood makes them ineffective against moderately healthy targets."
	reagent_state = LIQUID
	color = "#000000"
	chem_flags = CHEMICAL_NOT_SYNTH | CHEMICAL_RNG_GENERAL | CHEMICAL_RNG_FUN | CHEMICAL_RNG_BOTANY
	metabolization_rate = 0.25 * REAGENTS_METABOLISM
	overdose_threshold = 15

/datum/reagent/medicine/stabilizing_nanites/on_mob_life(mob/living/carbon/M, delta_time, times_fired)
	if(M.health <= 80)
		M.adjustToxLoss(-4 * REM * delta_time, 0)
		M.adjustBruteLoss(-4 * REM * delta_time, 0)
		M.adjustFireLoss(-4 * REM * delta_time, 0)
		M.adjustOxyLoss(-5 * REM * delta_time, 0)
		. = TRUE

	if(DT_PROB(10, delta_time))
		M.Jitter(5)
	M.losebreath = 0
	if (M.blood_volume < BLOOD_VOLUME_SAFE)
		M.blood_volume = max(M.blood_volume, (min(M.blood_volume + 4, BLOOD_VOLUME_SAFE) * REM * delta_time))
	..()

/datum/reagent/medicine/stabilizing_nanites/on_mob_metabolize(mob/living/L)
	ADD_TRAIT(L, TRAIT_NO_BLEEDING, type)

/datum/reagent/medicine/stabilizing_nanites/on_mob_end_metabolize(mob/living/L)
	REMOVE_TRAIT(L, TRAIT_NO_BLEEDING, type)

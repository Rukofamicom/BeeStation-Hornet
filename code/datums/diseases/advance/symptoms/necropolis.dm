/datum/symptom/necroseed
	name = "Necropolis Seed"
	desc = "An infantile form of the root of Lavaland's tendrils. Forms a symbiotic bond with the host, making them stronger and hardier, at the cost of speed. Should the disease be cured, the host will be severely weakened"
	stealth = 0
	resistance = 3
	stage_speed = -10
	transmission = -3
	level = 9
	base_message_chance = 5
	severity = -1
	symptom_delay_min = 1
	symptom_delay_max = 1
	var/tendrils = FALSE
	var/chest = FALSE
	var/fireproof = FALSE
	prefixes = list("Lava ", "Lavaland ", "Eldritch ")
	bodies = list("Goliath", "Tentacle", "Carapace")
	threshold_desc = "<b>Stealth 8:</b> Upon death, the host's soul will solidify into an unholy artifact, rendering them utterly unrevivable in the process.<br>\
						<b>Transmission 6:</b> The area near the host roils with paralyzing tendrils.<br>\
						<b>Resistance 20:</b>	Host becomes immune to heat, ash, and lava"
	var/list/cached_tentacle_turfs
	var/turf/last_location
	var/tentacle_recheck_cooldown = 100

/datum/symptom/necroseed/severityset(datum/disease/advance/A)
	. = ..()
	if(A.stealth >= 8)
		severity += 2
	if(A.resistance >= 20 || ((CONFIG_GET(flag/unconditional_symptom_thresholds) || A.event) && A.resistance >= 12))
		severity -= 1
	if(CONFIG_GET(flag/unconditional_symptom_thresholds))
		threshold_desc = "<b>Stealth 8:</b> Upon death, the host's soul will solidify into an unholy artifact, rendering them utterly unrevivable in the process.<br>\
						<b>Transmission 6:</b> The area near the host roils with paralyzing tendrils.<br>\
						<b>Resistance 12:</b>	Host becomes immune to heat, ash, and lava"

/datum/symptom/necroseed/Start(datum/disease/advance/A)
	if(!..())
		return
	if(A.transmission >= 6)
		tendrils = TRUE
	if(A.resistance >= 20 || ((CONFIG_GET(flag/unconditional_symptom_thresholds) || A.event) && A.resistance >= 12))
		fireproof = TRUE
	if(A.stealth >= 8)
		chest = TRUE


/datum/symptom/necroseed/Activate(datum/disease/advance/A)
	if(!..())
		return
	var/mob/living/carbon/M = A.affected_mob
	switch(A.stage)
		if(2)
			if(prob(base_message_chance) && M.stat != DEAD)
				to_chat(M, span_notice("Your skin feels scaly."))
		if(3, 4)
			if(prob(base_message_chance) && M.stat != DEAD)
				to_chat(M, span_notice("[pick("Your skin is hard.", "You feel stronger.", "You feel powerful.")]"))
		if(5)
			if(tendrils)
				tendril(A)
			M.dna.species.punchdamage = max(12, M.dna.species.punchdamage)
			M.dna.species.brutemod = min(0.6, M.dna.species.brutemod)
			M.dna.species.burnmod = min(0.6, M.dna.species.burnmod)
			M.dna.species.heatmod = min(0.6, M.dna.species.heatmod)
			M.add_movespeed_modifier(/datum/movespeed_modifier/virus/necro_virus)
			ADD_TRAIT(M, TRAIT_PIERCEIMMUNE, DISEASE_TRAIT)
			if(fireproof)
				ADD_TRAIT(M, TRAIT_RESISTHEAT, DISEASE_TRAIT)
				ADD_TRAIT(M, TRAIT_RESISTHIGHPRESSURE, DISEASE_TRAIT)
				M.weather_immunities |= "ash"
				M.weather_immunities |= "lava"
			if(HAS_TRAIT(M, TRAIT_NECROPOLIS_INFECTED))
				REMOVE_TRAIT(M, TRAIT_NECROPOLIS_INFECTED, "legion_core_trait")
				if(M.stat != DEAD)
					to_chat(M, span_notice("The tendrils loosen their grip, protecting the necropolis within you."))
			if(prob(base_message_chance) && M.stat != DEAD)
				to_chat(M, span_notice("[pick("Your skin has become a hardened carapace", "Your strength is superhuman.", "You feel invincible.")]"))
	return

/datum/symptom/necroseed/proc/tendril(datum/disease/advance/A)
	. = A.affected_mob
	var/mob/living/loc = A.affected_mob.loc
	if(isturf(loc))
		if(!LAZYLEN(cached_tentacle_turfs) || loc != last_location || tentacle_recheck_cooldown <= world.time)
			LAZYCLEARLIST(cached_tentacle_turfs)
			last_location = loc
			tentacle_recheck_cooldown = world.time + initial(tentacle_recheck_cooldown)
			for(var/turf/open/T in (RANGE_TURFS(1, loc)-loc))
				LAZYADD(cached_tentacle_turfs, T)
		for(var/t in cached_tentacle_turfs)
			if(isopenturf(t))
				if(prob(5))
					new /obj/effect/temp_visual/goliath_tentacle/necro(t, A.affected_mob)
			else
				cached_tentacle_turfs -= t

/datum/symptom/necroseed/End(datum/disease/advance/A)
	if(!..())
		return
	var/mob/living/carbon/M = A.affected_mob
	to_chat(M, span_danger("You feel weak and powerless as the necropolis' blessing leaves your body, leaving you quicker but vulnerable."))
	M.dna.species.punchdamage = initial(M.dna.species.punchdamage)
	M.dna.species.brutemod = initial(M.dna.species.heatmod)
	M.dna.species.burnmod = initial(M.dna.species.heatmod)
	M.dna.species.heatmod = initial(M.dna.species.heatmod)
	M.remove_movespeed_modifier(/datum/movespeed_modifier/virus/necro_virus)
	REMOVE_TRAIT(M, TRAIT_PIERCEIMMUNE, DISEASE_TRAIT)
	if(fireproof)
		REMOVE_TRAIT(M, TRAIT_RESISTHIGHPRESSURE, DISEASE_TRAIT)
		REMOVE_TRAIT(M, TRAIT_RESISTHEAT, DISEASE_TRAIT)
		M.weather_immunities -= "ash"
		M.weather_immunities -= "lava"

/datum/symptom/necroseed/OnDeath(datum/disease/advance/A)
	if(!..())
		return
	var/mob/living/M = A.affected_mob
	if(chest && A.stage >= 5 && M.sethellbound())
		to_chat(M, span_danger("Your soul is ripped from your body!"))
		M.visible_message(span_danger("An unearthly roar shakes the ground as [M] explodes into a shower of gore, leaving behind an ominous, fleshy chest."))
		playsound(M.loc,'sound/effects/tendril_destroyed.ogg', 200, 0, 50, 1, 1)
		addtimer(CALLBACK(M, TYPE_PROC_REF(/mob, gib)), 0.5 SECONDS)	//we can't gib mob while it's already dying
		if(!ishuman(M) || HAS_TRAIT(M, TRAIT_NONECRODISEASE)) //We don't NEED them to be human. However, I want to avoid people making teratoma-farms for necrochests
			return
		new /obj/structure/closet/crate/necropolis/tendril(M.loc)

/obj/effect/temp_visual/goliath_tentacle/necro
	name = "fledgling necropolis tendril"

/obj/effect/temp_visual/goliath_tentacle/necro/trip()
	var/latched = FALSE
	for(var/mob/living/L in loc)
		if(L == spawner)
			retract()
			return
		visible_message(span_danger("[src] grabs hold of [L]!"))
		L.Stun(40)
		L.adjustBruteLoss(rand(1,10))
		latched = TRUE
	if(!latched)
		retract()
	else
		deltimer(timerid)
		timerid = addtimer(CALLBACK(src, PROC_REF(retract)), 10, TIMER_STOPPABLE)

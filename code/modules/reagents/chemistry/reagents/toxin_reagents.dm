
//////////////////////////Poison stuff (Toxins & Acids)///////////////////////

/datum/reagent/toxin
	name = "Toxin"
	description = "A toxic chemical."
	color = "#CF3600" // rgb: 207, 54, 0
	taste_description = "bitterness"
	taste_mult = 1.2
	metabolization_rate = 0 														//Starts at zero, so the first tick of each chem does nothing and it can be adjusted appropriately based on base_metab
	var/toxpwr = 3.75 																//How much total damage the toxin does per unit
	var/toxtick = 0 																//How much power the current tick of the toxin has, based on toxpwr and metabolization_rate
	var/sedative = 0 																//Does this toxin have a sedative effect?
	var/base_metab = REAGENTS_METABOLISM 											//Base metabolism doesn't change, but actual metabolism does for toxins
	var/silent_toxin = FALSE 														//won't produce a pain message when processed by liver/life() if there isn't another non-silent toxin present.

/datum/reagent/toxin/on_mob_life(mob/living/carbon/M)
	metabolization_rate = base_metab*max(min((volume-5)*0.0666 + 0.5, 1.5), 0.5)  	//metabolization rate +/- 50% based on current volume of the toxin in the victim
	toxtick = toxpwr*metabolization_rate 											//defining current power of the toxin for this tick globally, rather than in each individual toxin
	to_chat(M, "<span class='notice'>DEBUG: [name] tox:[toxtick] u/t:[metabolization_rate] Vol:[volume]</span>") 								//DEBUG TEXT DELETE LINE
	if(M.drowsyness <= 60 && sedative)																											// DEBUG TEXT DELETE LINE
		to_chat(M, "<span class='notice'>DEBUG: Drowsyness = [M.drowsyness] + [min(0.5 + volume * metabolization_rate, 5)-1]</span>") 			// DEBUG TEXT DELETE LINE
	else if(M.drowsyness && sedative)																											// DEBUG TEXT DELETE LINE
		to_chat(M, "<span class='notice'>DEBUG: Drowsyness = [M.drowsyness] + 0</span>") 														// DEBUG TEXT DELETE LINE
	if(sedative) 																	//All sedatives follow the same base formula for knockouts. 
		if(M.drowsyness >= 50 && current_cycle >= 8)		
			M.Sleeping(40, 0)
		if(M.drowsyness <= 60) 														//Toxins will never push drowsyness beyond 60 so that waking from a waning sedative is possible before it has completely left the system. 
			M.drowsyness += min(0.5 + volume * metabolization_rate, 5)*sedative
	if(toxpwr)
		. = TRUE
		M.adjustToxLoss(toxtick*REM, 0)
	..()

/datum/reagent/toxin/amatoxin	//Relatively powerful but ordinary toxin. 
	name = "Amatoxin"
	description = "A powerful poison derived from certain species of mushroom."
	color = "#792300" // rgb: 121, 35, 0
	toxpwr = 7
	taste_description = "mushroom"

/datum/reagent/toxin/mutagen
	name = "Unstable Mutagen"
	description = "Might cause unpredictable mutations. Keep away from children."
	color = "#00FF00"
	toxpwr = 0
	taste_description = "slime"
	taste_mult = 0.9

/datum/reagent/toxin/mutagen/reaction_mob(mob/living/carbon/M, method=TOUCH, reac_volume)
	if(!..())
		return
	if(!M.has_dna())
		return  //No robots, AIs, aliens, Ians or other mobs should be affected by this.
	if((method==VAPOR && prob(min(33, reac_volume))) || method==INGEST || method==PATCH || method==INJECT)
		M.randmuti()
		if(prob(98))
			M.easy_randmut(NEGATIVE+MINOR_NEGATIVE)
		else
			M.easy_randmut(POSITIVE)
		M.updateappearance()
		M.domutcheck()
	..()

/datum/reagent/toxin/mutagen/on_mob_life(mob/living/carbon/C)
	C.apply_effect(5,EFFECT_IRRADIATE,0)
	return ..()

/datum/reagent/toxin/plasma
	name = "Plasma"
	description = "Plasma in its liquid form."
	taste_description = "a burning, tingling sensation"
	specific_heat = SPECIFIC_HEAT_PLASMA
	taste_mult = 1.5
	color = "#8228A0"
	toxpwr = 7.5
	process_flags = ORGANIC | SYNTHETIC

/datum/reagent/toxin/plasma/on_mob_life(mob/living/carbon/C)
	if(holder.has_reagent(/datum/reagent/medicine/epinephrine))
		holder.remove_reagent(/datum/reagent/medicine/epinephrine, 2*REM)
	C.adjustPlasma(20)
	return ..()

/datum/reagent/toxin/plasma/reaction_obj(obj/O, reac_volume)
	if((!O) || (!reac_volume))
		return 0
	var/temp = holder ? holder.chem_temp : T20C
	O.atmos_spawn_air("plasma=[reac_volume];TEMP=[temp]")

/datum/reagent/toxin/plasma/reaction_turf(turf/open/T, reac_volume)
	if(istype(T))
		var/temp = holder ? holder.chem_temp : T20C
		T.atmos_spawn_air("plasma=[reac_volume];TEMP=[temp]")
	return

/datum/reagent/toxin/plasma/reaction_mob(mob/living/M, method=TOUCH, reac_volume)//Splashing people with plasma is stronger than fuel!
	if(method == TOUCH || method == VAPOR)
		M.adjust_fire_stacks(reac_volume / 5)
		return
	..()

/datum/reagent/toxin/lexorin	//Lethal and fast acting toxin that targets the respiratory system
	name = "Lexorin"
	description = "A powerful poison used to stop respiration."
	color = "#7DC3A0"
	toxpwr = 0
	taste_description = "acid"

/datum/reagent/toxin/lexorin/on_mob_life(mob/living/carbon/C)
	. = TRUE

	if(HAS_TRAIT(C, TRAIT_NOBREATH))	//No effect on targets that don't need to breathe
		. = FALSE

	if(.)
		C.adjustOxyLoss((metabolization_rate*12.5), 0)	//2.5-7.5 oxyloss based on current volume of lexorin
		C.losebreath += 1
		if(prob(10))
			C.emote("gasp")
		C.reagents.add_reagent(/datum/reagent/toxin/histamine,metabolization_rate*2.5) //0.5-1.5u of histamine generation
	..()

/datum/reagent/toxin/slimejelly
	name = "Slime Jelly"
	description = "A gooey semi-liquid produced from one of the deadliest lifeforms in existence."
	color = "#801E28" // rgb: 128, 30, 40
	toxpwr = 8
	taste_description = "slime"
	taste_mult = 1.3

/datum/reagent/toxin/slimejelly/on_mob_life(mob/living/carbon/M)
	if(prob(10) && !isoozeling(M) && !isslimeperson(M))						//Shouldn't burn slime people
		to_chat(M, "<span class='danger'>Your insides are burning!</span>")
	..()

/datum/reagent/toxin/slimeooze
	name = "Slime Ooze"
	description = "A gooey semi-liquid produced from Oozelings"
	color = "#611e80"
	toxpwr = 2.5
	taste_description = "slime"
	taste_mult = 1.5

/datum/reagent/toxin/slimeooze/on_mob_life(mob/living/carbon/M)
	if(prob(10) && !isoozeling(M) && !isslimeperson(M))
		to_chat(M, "<span class='danger'>Your insides are burning!</span>")
	..()

/datum/reagent/toxin/minttoxin
	name = "Mint Toxin"
	description = "Useful for dealing with undesirable customers."
	color = "#CF3600" // rgb: 207, 54, 0
	toxpwr = 0
	taste_description = "mint"

/datum/reagent/toxin/minttoxin/on_mob_life(mob/living/carbon/M)
	if(HAS_TRAIT(M, TRAIT_FAT))
		M.gib()
	return ..()

/datum/reagent/toxin/carpotoxin		//Very slow acting neurotoxin, eventually resulting in total loss of movement and suffocation if the effects are completely ignored. Intended as more of a meme/prank toxin than an effective one.
	name = "Carpotoxin"				//Low doses are completely non-lethal, and even a massive dose gives players a minimum of about five minutes of flopping over in order to seek a chem purge. 
	description = "A deadly neurotoxin produced by the dreaded spess carp."
	silent_toxin = TRUE
	color = "#003333" // rgb: 0, 51, 51
	toxpwr = 0
	base_metab = 0.0625 * REAGENTS_METABOLISM						//This is absurdly slow to compliment the absurdly slow paralysis buildup detailed below.
	taste_description = "fish"
	var/para = 0
	var/alert = 0

/datum/reagent/toxin/carpotoxin/on_mob_life(mob/living/carbon/M)
	if(!iscatperson(M))
		para += max((metabolization_rate*8)-0.05, 0)				//Paralysis slowly builds at a rate of 0.05-0.25% per tick. Treatment does not become necessary for a long time
		if(para >= 5 && alert == 0)
			alert++
			to_chat(M, "<span class='notice'>You begin to feel numb</span>")  //Ominous warning message once the toxin has advanced far enough to begin to trigger paralysis
		if(para >= 15 && alert == 1)
			alert++
			to_chat(M, "<span class='notice'>Your chest feels strangely heavy</span>")
		if(para >= 5 && prob(min(para, 100)))						//Paralysis doesn't start to proc until the buildup has reached a 5% chance - at minimum this will take 20 ticks to reach.
			M.Paralyze(60, 0)
		if(para >= 15 && M.IsParalyzed())							//Paralysis procs begin to trigger suffocation. 60 ticks at minimum to reach this stage, and procs will still be too far apart to do any real damage for the time being.
			M.losebreath++
	..()

/datum/reagent/toxin/zombiepowder
	name = "Zombie Powder"
	description = "A strong neurotoxin that puts the subject into a death-like state."
	silent_toxin = TRUE
	reagent_state = SOLID
	color = "#669900" // rgb: 102, 153, 0
	toxpwr = 0
	taste_description = "death"														//Ominous flavor description

/datum/reagent/toxin/zombiepowder/on_mob_life(mob/living/carbon/M)
	M.adjustStaminaLoss(max(((metabolization_rate*2*current_cycle)-5), 0)*REM, 0)   //Delay before stamina damage starts ramping up, 4-13 tick delay based on volume
	if(M.getStaminaLoss() >= 145) 													//Fake death directly tied to stamina for versatility, but won't trigger until deep stamcrit
		M.fakedeath(type)
	..()

/datum/reagent/toxin/zombiepowder/on_mob_end_metabolize(mob/living/L)
	L.cure_fakedeath(type)
	..()

/datum/reagent/toxin/ghoulpowder
	name = "Ghoul Powder"
	description = "A strong neurotoxin that slows metabolism to a death-like state while keeping the patient fully active. Causes toxin buildup if used too long."
	reagent_state = SOLID
	color = "#664700" // rgb: 102, 71, 0
	toxpwr = 0.5
	taste_description = "death"

/datum/reagent/toxin/ghoulpowder/on_mob_metabolize(mob/living/L)
	..()
	ADD_TRAIT(L, TRAIT_FAKEDEATH, type)

/datum/reagent/toxin/ghoulpowder/on_mob_end_metabolize(mob/living/L)
	REMOVE_TRAIT(L, TRAIT_FAKEDEATH, type)
	..()

/datum/reagent/toxin/ghoulpowder/on_mob_life(mob/living/carbon/M)
	..()

/datum/reagent/toxin/mindbreaker
	name = "Mindbreaker Toxin"
	description = "A mild hallucinogen. Beneficial to some mental patients."
	color = "#B31008" // rgb: 139, 166, 233
	toxpwr = 0
	var/countdown = 0
	taste_description = "sourness"

/datum/reagent/toxin/mindbreaker/on_mob_life(mob/living/carbon/M)
	M.hallucination += 5
	..()

/datum/reagent/toxin/mindbreaker/on_mob_end_metabolize(mob/living/M)
	if(iscarbon(M))
		var/mob/living/carbon/N = M
		N.hal_screwyhud = SCREWYHUD_NONE
	..()

/datum/reagent/toxin/plantbgone
	name = "Plant-B-Gone"
	description = "A harmful toxic mixture to kill plantlife. Do not ingest!"
	color = "#49002E" // rgb: 73, 0, 46
	toxpwr = 2

/datum/reagent/toxin/plantbgone/reaction_obj(obj/O, reac_volume)
	if(istype(O, /obj/structure/alien/weeds) || istype(O, /obj/structure/glowshroom) || istype(O, /obj/structure/spacevine)) 
		qdel(O) //even a small amount is enough to kill it

/datum/reagent/toxin/plantbgone/reaction_mob(mob/living/M, method=TOUCH, reac_volume)
	if(method == VAPOR)
		if(iscarbon(M))
			var/mob/living/carbon/C = M
			if(!C.wear_mask) // If not wearing a mask
				var/damage = min(round(0.4*reac_volume, 0.1),10)
				C.adjustToxLoss(damage)

/datum/reagent/toxin/plantbgone/weedkiller
	name = "Weed Killer"
	description = "A harmful toxic mixture to kill weeds. Do not ingest!"
	color = "#4B004B" // rgb: 75, 0, 75
	toxpwr = 2.5

/datum/reagent/toxin/pestkiller
	name = "Pest Killer"
	description = "A harmful toxic mixture to kill pests. Do not ingest!"
	color = "#4B004B" // rgb: 75, 0, 75
	toxpwr = 2.5

/datum/reagent/toxin/pestkiller/reaction_mob(mob/living/M, method=TOUCH, reac_volume)
	..()
	if(MOB_BUG in M.mob_biotypes)
		var/damage = min(round(0.4*reac_volume, 0.1),10)
		M.adjustToxLoss(damage)

/datum/reagent/toxin/spore
	name = "Spore Toxin"
	description = "A natural toxin produced by blob spores that inhibits vision when ingested."
	color = "#9ACD32"
	toxpwr = 2.5

/datum/reagent/toxin/spore/on_mob_life(mob/living/carbon/C)
	C.damageoverlaytemp = 60
	C.update_damage_hud()
	C.blur_eyes(3)
	return ..()

/datum/reagent/toxin/spore_burning
	name = "Burning Spore Toxin"
	description = "A natural toxin produced by blob spores that induces combustion in its victim."
	color = "#9ACD32"
	toxpwr = 0.5
	taste_description = "burning"

/datum/reagent/toxin/spore_burning/on_mob_life(mob/living/carbon/M)
	M.adjust_fire_stacks(2)
	M.IgniteMob()
	return ..()

/datum/reagent/toxin/chloralhydrate				// Most powerful sedative available, but can be lethal.
	name = "Chloral Hydrate"
	description = "A powerful sedative"
	silent_toxin = TRUE
	reagent_state = SOLID
	color = "#000067" // rgb: 0, 0, 103
	toxpwr = 0
	sedative = 1
	base_metab = 1.5 * REAGENTS_METABOLISM

/datum/reagent/toxin/chloralhydrate/on_mob_life(mob/living/carbon/M)
	if(M.confused <= 20)
		M.confused += (metabolization_rate * 5 - 1)					//Gain 1 - 3 confusion per tick. Can result in net-zero confusion, since 1 heals naturally every tick.
	if(current_cycle >= 50 && M.drowsyness >= 50)
		toxpwr = (current_cycle - 50)
	..()

/datum/reagent/toxin/fakebeer	//disguised as normal beer for use by emagged brobots
	name = "Beer"
	description = "A specially-engineered sedative disguised as beer. It induces delayed, but rapid sleep in its target."
	color = "#664300" // rgb: 102, 67, 0
	base_metab = 1.5 * REAGENTS_METABOLISM
	taste_description = "piss water"
	glass_icon_state = "beerglass"
	glass_name = "glass of beer"
	glass_desc = "A freezing pint of beer."

/datum/reagent/toxin/fakebeer/on_mob_life(mob/living/carbon/M)
	if(current_cycle == 8)
		sedative = 1
		M.confused += min(20, volume*5)
		M.drowsyness += min(35, volume*8)
		to_chat(M, "<span class='notice'>You feel very lightheaded</span>")
	if(current_cycle >= 9 && M.confused <= 20)
		M.confused += 2	
	if(current_cycle >= 50 && M.drowsyness >= 50)
		toxpwr = (current_cycle - 50)
	return ..()

/datum/reagent/toxin/coffeepowder
	name = "Coffee Grounds"
	description = "Finely ground coffee beans, used to make coffee."
	reagent_state = SOLID
	color = "#5B2E0D" // rgb: 91, 46, 13
	toxpwr = 0.5

/datum/reagent/toxin/teapowder
	name = "Ground Tea Leaves"
	description = "Finely shredded tea leaves, used for making tea."
	reagent_state = SOLID
	color = "#7F8400" // rgb: 127, 132, 0
	toxpwr = 0.1
	taste_description = "green tea"

/datum/reagent/toxin/mutetoxin //the new zombie powder.
	name = "Mute Toxin"
	description = "A nonlethal poison that inhibits speech in its victim."
	silent_toxin = TRUE
	color = "#F0F8FF" // rgb: 240, 248, 255
	toxpwr = 0
	taste_description = "silence"

/datum/reagent/toxin/mutetoxin/on_mob_life(mob/living/carbon/M)
	M.silent = max(M.silent, 3)
	..()

/datum/reagent/toxin/staminatoxin
	name = "Tirizene"
	description = "A nonlethal poison that causes extreme fatigue and weakness in its victim. More potent when ingested"
	silent_toxin = TRUE
	color = "#6E2828"
	base_metab = 2.0 * REAGENTS_METABOLISM
	toxpwr = 0
	var/ing = 1

/datum/reagent/toxin/staminatoxin/reaction_mob(mob/living/M, method=TOUCH, reac_volume, show_message = 1)
	if(iscarbon(M) && M.stat != DEAD)
		if(method in list(INGEST))			// Bartenders with an emag get easy access to this chem, it'd be pretty good if it was more effective when in food/drinks
			ing = 2

/datum/reagent/toxin/staminatoxin/on_mob_life(mob/living/carbon/M)
	M.adjustStaminaLoss(metabolization_rate * ing * 8, 0)
	. = 1
	..()

/datum/reagent/toxin/polonium				//Available only via uplink, so quite powerful
	name = "Polonium"
	description = "An extremely radioactive material in liquid form. Ingestion results in fatal irradiation."
	reagent_state = LIQUID
	color = "#787878"
	base_metab = 0.25 * REAGENTS_METABOLISM
	toxpwr = 0
	process_flags = ORGANIC | SYNTHETIC

/datum/reagent/toxin/polonium/on_mob_life(mob/living/carbon/M)
	M.radiation += 100*metabolization_rate	//5-15 radiation per tick. Totals to 100 radiation per unit injected.
	..()

/datum/reagent/toxin/histamine
	name = "Histamine"
	description = "Histamine's effects become more dangerous depending on the dosage amount. They range from mildly annoying to incredibly lethal."
	silent_toxin = TRUE
	reagent_state = LIQUID
	color = "#FA6464"
	base_metab = 0.25 * REAGENTS_METABOLISM
	overdose_threshold = 30
	toxpwr = 0

/datum/reagent/toxin/histamine/on_mob_life(mob/living/carbon/M)
	if(prob(50))
		switch(pick(1, 2, 3))
			if(1)
				to_chat(M, "<span class='danger'>You can barely see!</span>")
				M.blur_eyes(3)
			if(2)
				M.emote("cough")
			if(3)
				M.emote("sneeze")
	..()

/datum/reagent/toxin/histamine/overdose_process(mob/living/carbon/M) 	//Anaphylaxis
	if(prob(volume))													//At time of overdose trigger, this will be 33% per tick, and will likely continue to worsen
		M.losebreath += 3
	if(prob(volume/10))													//Low chance of cardiac arrest, unless epinephrine is present.
		if(!M.undergoing_cardiac_arrest() && M.can_heartattack() && !holder.has_reagent(/datum/reagent/medicine/epinephrine))
			M.set_heartattack(TRUE)
			if(M.stat == CONSCIOUS)
				M.visible_message("<span class='userdanger'>[M] clutches at [M.p_their()] chest as if [M.p_their()] heart stopped!</span>")
	..()
	. = 1

/datum/reagent/toxin/formaldehyde
	name = "Formaldehyde"
	description = "Formaldehyde, on its own, is a fairly weak toxin, but it triggers a histamine response inside the body. Useful for preserving dead bodies."
	silent_toxin = TRUE
	reagent_state = LIQUID
	color = "#B4004B"
	base_metab = 0.5 * REAGENTS_METABOLISM
	toxpwr = 2.5

/datum/reagent/toxin/formaldehyde/on_mob_life(mob/living/carbon/M)
	if(prob(20))
		holder.add_reagent(/datum/reagent/toxin/histamine, metabolization_rate*10)  //1u Formaldehyde will produce roughly 2u Histamine, which metabolizes at half the speed.
	..()

/datum/reagent/toxin/venom 											//Only available via traitor uplink, so quite powerful
	name = "Venom"
	description = "An exotic poison extracted from highly toxic fauna, it is very toxic and also triggers a histamine response"
	reagent_state = LIQUID
	color = "#F0FFF0"
	base_metab = 0.5 * REAGENTS_METABOLISM

/datum/reagent/toxin/venom/on_mob_life(mob/living/carbon/M)
	toxpwr = max(5, volume)											//This double-dips making it especially potent in large volumes, but never particularly bad at low ones. Only available via uplink
	if(prob(toxpwr*4))
		M.reagents.add_reagent(/datum/reagent/toxin/histamine, 2)	//Steadily produces histamine at low volumes, rapidly at high volumes. 
	..()

/datum/reagent/toxin/fentanyl
	name = "Fentanyl"
	description = "Fentanyl will inhibit brain function and cause toxin damage." //No longer a sedative due to gaining SCREWYHUD_HEALTHY. Just a mild toxin that inhibits perception.
	reagent_state = LIQUID
	color = "#64916E"
	toxpwr = 2
	base_metab = 0.5 * REAGENTS_METABOLISM

/datum/reagent/toxin/fentanyl/on_mob_life(mob/living/carbon/M)
	M.adjustOrganLoss(ORGAN_SLOT_BRAIN, toxtick*REM, 150)
	M.hal_screwyhud = SCREWYHUD_HEALTHY							//inhibits normal brain function, and enables toxin mixes to not immediately make visible HUD changes. 
	..()


/datum/reagent/toxin/cyanide
	name = "Cyanide"
	description = "An infamous poison known for its use in assassination. Deals progressively worse damage and symptoms with time"
	reagent_state = LIQUID
	color = "#00B4FF"
	base_metab = 0.125 * REAGENTS_METABOLISM
	toxpwr = 0
	var/alert = 0

/datum/reagent/toxin/cyanide/on_mob_life(mob/living/carbon/M)
	if(toxpwr <= 20)
		toxpwr = toxpwr + metabolization_rate*2				//Power starts at 0 and goes up by 2 for every unit metabolized. 10u is just enough for a lethal dose, but larger doses will result in faster lethality.
	if(toxpwr >= 5 && alert == 0)
		alert++
		to_chat(M, "<span class='danger'>Your head is throbbing!</span>")
	if(toxpwr >= 10 && M.confused <= 20)
		M.confused += 2
	if(toxpwr >= 15)
		if(prob(toxpwr/2))
			M.visible_message("<span class='danger'>[M] starts having a seizure! They appear to be frothing at the mouth!</span>", "<span class='userdanger'>You have a seizure!</span>")
			M.Unconscious(100)
			M.Jitter(350)
	..()

/datum/reagent/toxin/bad_food
	name = "Bad Food"
	description = "The result of some abomination of cookery, food so bad it's toxic."
	reagent_state = LIQUID
	color = "#d6d6d8"
	base_metab = 0.25 * REAGENTS_METABOLISM
	toxpwr = 0.5
	taste_description = "bad cooking"

/datum/reagent/toxin/itching_powder
	name = "Itching Powder"
	description = "A powder that induces itching upon contact with the skin. Causes the victim to scratch at their itches and has a very low chance to decay into Histamine."
	silent_toxin = TRUE
	reagent_state = LIQUID
	color = "#C8C8C8"
	base_metab = REAGENTS_METABOLISM
	toxpwr = 0

/datum/reagent/toxin/itching_powder/reaction_mob(mob/living/M, method=TOUCH, reac_volume)
	if(method == TOUCH || method == VAPOR)
		M.reagents?.add_reagent(/datum/reagent/toxin/itching_powder, reac_volume)

/datum/reagent/toxin/itching_powder/on_mob_life(mob/living/carbon/M)
	if(prob(15))
		to_chat(M, "You scratch at your head.")
		M.adjustBruteLoss(0.2*REM, 0)
		. = 1
	if(prob(15))
		to_chat(M, "You scratch at your leg.")
		M.adjustBruteLoss(0.2*REM, 0)
		. = 1
	if(prob(15))
		to_chat(M, "You scratch at your arm.")
		M.adjustBruteLoss(0.2*REM, 0)
		. = 1
	if(prob(5))
		M.reagents.add_reagent(/datum/reagent/toxin/histamine, 1)
		return
	..()

/datum/reagent/toxin/initropidril									//Extremely potent, but only available via uplink.
	name = "Initropidril"
	description = "A powerful poison with insidious effects. It can cause paralysis, breathing failure, and cardiac arrest."
	silent_toxin = TRUE
	reagent_state = LIQUID
	color = "#7F10C0"
	base_metab = 0.5 * REAGENTS_METABOLISM
	toxpwr = 5
	var/roll = 0

/datum/reagent/toxin/initropidril/on_mob_life(mob/living/carbon/C)
	if(prob(metabolization_rate*100))								//10%-30% chance of effects triggering based on the current volume
		roll = rand(1,3)
		switch(roll)
			if(1)
				C.Paralyze(60, 0)
			if(2)
				C.losebreath += 10
				C.adjustOxyLoss(rand(5,25), 0)
			if(3)
				if(!C.undergoing_cardiac_arrest() && C.can_heartattack())
					C.set_heartattack(TRUE)
					if(C.stat == CONSCIOUS)
						C.visible_message("<span class='userdanger'>[C] clutches at [C.p_their()] chest as if [C.p_their()] heart stopped!</span>")
	..()

/datum/reagent/toxin/pancuronium	// Rapid onset paralysis toxin, only available via uplink
	name = "Pancuronium"
	description = "A flavorless, potent muscle relaxant known for leaving its victims conscious, but unable to speak or move."
	silent_toxin = TRUE
	reagent_state = LIQUID
	color = "#195096"
	base_metab = 0.5 * REAGENTS_METABOLISM							
	toxpwr = 0
	taste_mult = 0
	var/para = 0
	var/alert = 0

/datum/reagent/toxin/pancuronium/on_mob_life(mob/living/carbon/M)
	para += metabolization_rate 									//increases by 1 per unit metabolized, taking between 3-10 ticks per stage
	if(para >= 1 && alert == 0)
		alert++
		to_chat(M, "<span class='notice'>Your legs feel wobbly</span>")
	if(para >= 2 && alert == 1)
		alert++
		M.Knockdown(40, 0)
		to_chat(M, "<span class='danger'>Your legs give out!</span>")
	if(para >= 3 && alert == 2)								
		alert++
		M.Paralyze(60, 0)
		to_chat(M, "<span class='danger'>Your body refuses to move!</span>")		//minimum of 10 ticks to reach first paralysis
	if(para >= 4)
		M.Paralyze(100, 0)
		M.silent = max(M.silent, 3)
		if(alert == 3)
			alert++
			to_chat(M, "<span class='danger'>You feel completely paralyzed!</span>")  //completely helpless until the toxin wears off at this point
	..()

/datum/reagent/toxin/sodium_thiopental			//Used to be uplink only, but is now craftable due to being the only 100% non-lethal sedative
	name = "Sodium Thiopental"
	description = "Sodium Thiopental is a powerful sedative, and triggers almost immediate exhaustion"
	silent_toxin = TRUE
	reagent_state = LIQUID
	color = "#6496FA"
	base_metab = 0.75 * REAGENTS_METABOLISM
	sedative = 1								//Half as effective a sedative as Chloral Hydrate, but is also a potent stamina toxin on top of being a sedative
	toxpwr = 0

/datum/reagent/toxin/sodium_thiopental/on_mob_life(mob/living/carbon/M)
	if(M.getStaminaLoss() <= 50)
		M.adjustStaminaLoss((metabolization_rate + 0.25) * 25, 0)  // 8-14 stamina per tick
	else
		M.adjustStaminaLoss((metabolization_rate + 0.25) * 15, 0)  // 6-10.5 stamina per tick - quick to exhaust, but slower to completely knock out
	..()


/datum/reagent/toxin/sulfonal
	name = "Sulfonal"
	description = "A flavorless, stealthy poison that deals slow toxin damage with mild disassociative and sedative effect"
	silent_toxin = TRUE
	reagent_state = LIQUID
	color = "#7DC3A0"
	base_metab = 0.125 * REAGENTS_METABOLISM			
	sedative = 1.5									//A very poor sedative despite the multiplier, but will still stack with other sedatives
	toxpwr = 3										//Mostly intended as a slightly better version of Fentanyl that is somewhat harder to acquire
	taste_mult = 0

/datum/reagent/toxin/sulfonal/on_mob_life(mob/living/carbon/M)
	M.hal_screwyhud = SCREWYHUD_HEALTHY
	..()

/datum/reagent/toxin/sulfonal/on_mob_end_metabolize(mob/living/M)
	if(iscarbon(M))
		var/mob/living/carbon/N = M
		N.hal_screwyhud = SCREWYHUD_NONE
	..()

/datum/reagent/toxin/amanitin								//Available only via Botany
	name = "Amanitin"
	description = "An extremely powerful toxin extracted from a deadly mushroom."
	silent_toxin = TRUE
	reagent_state = LIQUID
	color = "#FFFFFF"
	toxpwr = 0
	base_metab = 0.5 * REAGENTS_METABOLISM

/datum/reagent/toxin/amanitin/on_mob_life(mob/living/M)
	toxpwr = toxpwr + volume/20								//Similar to cyanide, but with a non-linear power scale and no visible symptoms outside of the toxin damage
	..()

/datum/reagent/toxin/lipolicide
	name = "Lipolicide"
	description = "A powerful toxin that will destroy fat cells, massively reducing body weight in a short time. Deadly to those without nutriment in their body."
	silent_toxin = TRUE
	taste_description = "mothballs"
	reagent_state = LIQUID
	color = "#F0FFF0"
	base_metab = 0.5 * REAGENTS_METABOLISM
	toxpwr = 0

/datum/reagent/toxin/lipolicide/on_mob_life(mob/living/carbon/M)	//Valuable as a treatment for obesity in moderation
	if(M.nutrition <= NUTRITION_LEVEL_STARVING)
		toxpwr = 10													//1-3 tox per tick if starving
	else
		toxpwr = 0
	M.adjust_nutrition(metabolization_rate * -15 + 0.5) 			// 1-4 nutrition lost per tick depending on current volume
	if(current_cycle > 10)
		M.overeatduration = 0										// Removes fat trait 10 ticks into processing
	return ..()


/datum/reagent/toxin/spewium
	name = "Spewium"
	description = "A powerful emetic, causes uncontrollable vomiting.  May result in vomiting organs at high doses."
	reagent_state = LIQUID
	color = "#2f6617" 				   //A sickly green color
	base_metab = REAGENTS_METABOLISM
	toxpwr = 0
	taste_description = "vomit"
	taste_mult = 0						//undetectable when in food/drink

/datum/reagent/toxin/spewium/on_mob_life(mob/living/carbon/C)
	if(prob(min(current_cycle*2, 50)))								//25 ticks and you're vomitting uncontrollably
		if(current_cycle >=25 && prob(15))							//Also you might start projectile vomiting your own organs
			C.spew_organ()
			C.vomit(0, TRUE, TRUE, 4)
			to_chat(C, "<span class='userdanger'>You feel something lumpy come up as you vomit.</span>")
		else							
			C.vomit(10, prob(10), prob(50), rand(0,4), TRUE, prob(30))
	. = TRUE
	..()

/datum/reagent/toxin/curare
	name = "Curare"
	description = "Causes relatively rapid onset of paralysis and asphyxiation"
	reagent_state = LIQUID
	color = "#191919"
	base_metab = 0.5 * REAGENTS_METABOLISM
	toxpwr = 5

/datum/reagent/toxin/curare/on_mob_life(mob/living/carbon/M)
	toxpwr += metabolization_rate
	if(prob(toxtick*5))
		M.Paralyze(100, 0)
	if(toxtick >= 2)
		M.losebreath += toxtick/2
	..()

/datum/reagent/toxin/heparin //Based on a real-life anticoagulant. I'm not a doctor, so this won't be realistic.
	name = "Heparin"			
	description = "A powerful anticoagulant. Victims will bleed internally"  //I too am not a doctor, and I removed the brute damage so it was a small degree stealthier
	silent_toxin = TRUE
	reagent_state = LIQUID
	color = "#C8C8C8" //RGB: 200, 200, 200
	base_metab = 0.25 * REAGENTS_METABOLISM
	toxpwr = 0

/datum/reagent/toxin/heparin/on_mob_life(mob/living/carbon/M)
	if(ishuman(M))
		var/mob/living/carbon/human/H = M
		H.bleed_rate = min(H.bleed_rate + 2, 8)
		. = 1
	return ..() || .


/datum/reagent/toxin/rotatium //Rotatium. Fucks up your rotation and is hilarious
	name = "Rotatium"
	description = "A constantly swirling, oddly colourful fluid. Causes the consumer's sense of direction and hand-eye coordination to become wild."
	silent_toxin = TRUE
	reagent_state = LIQUID
	color = "#AC88CA" //RGB: 172, 136, 202
	base_metab = 0.6 * REAGENTS_METABOLISM
	toxpwr = 0.5
	taste_description = "spinning"
	process_flags = ORGANIC | SYNTHETIC

/datum/reagent/toxin/rotatium/on_mob_life(mob/living/carbon/M)
	if(M.hud_used)
		if(current_cycle >= 20 && current_cycle%20 == 0)
			var/list/screens = list(M.hud_used.plane_masters["[FLOOR_PLANE]"], M.hud_used.plane_masters["[GAME_PLANE]"], M.hud_used.plane_masters["[LIGHTING_PLANE]"])
			var/rotation = min(round(current_cycle/20), 89) // By this point the player is probably puking and quitting anyway
			for(var/whole_screen in screens)
				animate(whole_screen, transform = matrix(rotation, MATRIX_ROTATE), time = 5, easing = QUAD_EASING, loop = -1)
				animate(transform = matrix(-rotation, MATRIX_ROTATE), time = 5, easing = QUAD_EASING)
	return ..()

/datum/reagent/toxin/rotatium/on_mob_end_metabolize(mob/living/M)
	if(M && M.hud_used)
		var/list/screens = list(M.hud_used.plane_masters["[FLOOR_PLANE]"], M.hud_used.plane_masters["[GAME_PLANE]"], M.hud_used.plane_masters["[LIGHTING_PLANE]"])
		for(var/whole_screen in screens)
			animate(whole_screen, transform = matrix(), time = 5, easing = QUAD_EASING)
	..()

/datum/reagent/toxin/anacea
	name = "Anacea"
	description = "A toxin that quickly purges medicines and metabolizes very slowly."
	reagent_state = LIQUID
	color = "#3C5133"
	base_metab = 0.08 * REAGENTS_METABOLISM
	toxpwr = 5

/datum/reagent/toxin/anacea/on_mob_life(mob/living/carbon/M)
	var/remove_amt = 5
	if(holder.has_reagent(/datum/reagent/medicine/calomel) || holder.has_reagent(/datum/reagent/medicine/carthatoline)) //Charcoal is less effective at hindering anacea
		remove_amt = 0.5
	for(var/datum/reagent/medicine/R in M.reagents.reagent_list)
		M.reagents.remove_reagent(R.type,remove_amt)
	return ..()

//ACID


/datum/reagent/toxin/acid
	name = "Sulphuric Acid"
	description = "A strong mineral acid with the molecular formula H2SO4."
	color = "#00FF32"
	toxpwr = 1
	var/acidpwr = 10 //the amount of protection removed from the armour
	taste_description = "acid"
	self_consuming = TRUE
	process_flags = ORGANIC | SYNTHETIC

/datum/reagent/toxin/acid/reaction_mob(mob/living/carbon/C, method=TOUCH, reac_volume)
	if(!istype(C))
		return
	reac_volume = round(reac_volume,0.1)
	if(method == INGEST)
		C.adjustBruteLoss(min(6*toxpwr, reac_volume * toxpwr))
		C.visible_message("<span class='userdanger'>[C] has taken [min(6*toxpwr, reac_volume * toxpwr)] Acid damage!</span>")		//DEBUG
		return
	if(method == INJECT)
		C.adjustBruteLoss(1.5 * min(6*toxpwr, reac_volume * toxpwr))
		C.visible_message("<span class='userdanger'>[C] has taken [1.5 * min(6*toxpwr, reac_volume * toxpwr)] Acid damage!</span>")		//DEBUG
		return
	C.acid_act(acidpwr, reac_volume)

/datum/reagent/toxin/acid/reaction_obj(obj/O, reac_volume)
	if(ismob(O.loc)) //handled in human acid_act()
		return
	reac_volume = round(reac_volume,0.1)
	O.acid_act(acidpwr, reac_volume)

/datum/reagent/toxin/acid/reaction_turf(turf/T, reac_volume)
	if (!istype(T))
		return
	reac_volume = round(reac_volume,0.1)
	T.acid_act(acidpwr, reac_volume)

/datum/reagent/toxin/acid/fluacid
	name = "Fluorosulfuric acid"
	description = "Fluorosulfuric acid is an extremely corrosive chemical substance."
	color = "#5050FF"
	toxpwr = 2
	acidpwr = 42.0

/datum/reagent/toxin/acid/fluacid/on_mob_life(mob/living/carbon/M)
	M.adjustFireLoss(current_cycle/10, 0)
	. = 1
	..()

/datum/reagent/toxin/delayed									//replaced amanitin in uplink toxin kit
	name = "Toxin Microcapsules"
	description = "Causes rapid, heavy toxin damage after a period of inactivity."
	reagent_state = LIQUID
	base_metab = 0 												//stays in the system until active.
	var/actual_metaboliztion_rate = REAGENTS_METABOLISM
	toxpwr = 10													//10u is enough to crit, 20u will outright kill - no damage is dealt while base_metab=0

/datum/reagent/toxin/delayed/on_mob_life(mob/living/carbon/M)
	if(current_cycle == 60)
		to_chat(M, "<span class='danger'You feel a hot tingling all over your body!</span>")	//full minute delay before capsules start to dissolve
	if(current_cycle >= 60)										
		base_metab += volume/5																	//Capsules are rapidly metabolized once they start to dissolve	
	. = 1
	..()

/datum/reagent/toxin/mimesbane
	name = "Mime's Bane"
	description = "A nonlethal neurotoxin that interferes with the victim's ability to gesture."
	silent_toxin = TRUE
	color = "#F0F8FF" // rgb: 240, 248, 255
	toxpwr = 0
	taste_description = "stillness"

/datum/reagent/toxin/mimesbane/on_mob_metabolize(mob/living/L)
	ADD_TRAIT(L, TRAIT_EMOTEMUTE, type)

/datum/reagent/toxin/mimesbane/on_mob_end_metabolize(mob/living/L)
	REMOVE_TRAIT(L, TRAIT_EMOTEMUTE, type)

/datum/reagent/toxin/bonehurtingjuice //oof ouch
	name = "Bone Hurting Juice"
	description = "A strange substance that looks a lot like water. Drinking it is oddly tempting. Oof ouch."
	silent_toxin = TRUE //no point spamming them even more.
	color = "#AAAAAA77" //RGBA: 170, 170, 170, 77
	toxpwr = 0
	taste_description = "bone hurting"
	overdose_threshold = 50

/datum/reagent/toxin/bonehurtingjuice/on_mob_metabolize(mob/living/carbon/M)
	M.say("Oof ouch my bones!", forced = /datum/reagent/toxin/bonehurtingjuice)

/datum/reagent/toxin/bonehurtingjuice/on_mob_life(mob/living/carbon/M)
	M.adjustStaminaLoss(7.5, 0)
	if(prob(20))
		switch(rand(1, 3))
			if(1)
				var/list/possible_says = list("oof.", "ouch!", "my bones.", "oof ouch.", "oof ouch my bones.")
				M.say(pick(possible_says), forced = /datum/reagent/toxin/bonehurtingjuice)
			if(2)
				var/list/possible_mes = list("oofs softly.", "looks like their bones hurt.", "grimaces, as though their bones hurt.")
				M.say("*custom " + pick(possible_mes), forced = /datum/reagent/toxin/bonehurtingjuice)
			if(3)
				to_chat(M, "<span class='warning'>Your bones hurt!</span>")
	return ..()

/datum/reagent/toxin/bonehurtingjuice/overdose_process(mob/living/carbon/M)
	if(prob(4) && iscarbon(M)) //big oof
		var/selected_part
		switch(rand(1, 4)) //God help you if the same limb gets picked twice quickly.
			if(1)
				selected_part = BODY_ZONE_L_ARM
			if(2)
				selected_part = BODY_ZONE_R_ARM
			if(3)
				selected_part = BODY_ZONE_L_LEG
			if(4)
				selected_part = BODY_ZONE_R_LEG
		var/obj/item/bodypart/bp = M.get_bodypart(selected_part)
		if(M.dna.species.type != /datum/species/skeleton && M.dna.species.type != /datum/species/plasmaman) //We're so sorry skeletons, you're so misunderstood
			if(bp)
				bp.receive_damage(0, 0, 200)
				playsound(M, get_sfx("desecration"), 50, TRUE, -1)
				M.visible_message("<span class='warning'>[M]'s bones hurt too much!!</span>", "<span class='danger'>Your bones hurt too much!!</span>")
				M.say("OOF!!", forced = /datum/reagent/toxin/bonehurtingjuice)
			else //SUCH A LUST FOR REVENGE!!!
				to_chat(M, "<span class='warning'>A phantom limb hurts!</span>")
				M.say("Why are we still here, just to suffer?", forced = /datum/reagent/toxin/bonehurtingjuice)
		else //you just want to socialize
			if(bp)
				playsound(M, get_sfx("desecration"), 50, TRUE, -1)
				M.visible_message("<span class='warning'>[M] rattles loudly and flails around!!</span>", "<span class='danger'>Your bones hurt so much that your missing muscles spasm!!</span>")
				M.say("OOF!!", forced=/datum/reagent/toxin/bonehurtingjuice)
				bp.receive_damage(200, 0, 0) //But I don't think we should
			else
				to_chat(M, "<span class='warning'>Your missing arm aches from wherever you left it.</span>")
				M.emote("sigh")
	return ..()

/datum/reagent/toxin/bungotoxin
	name = "Bungotoxin"
	description = "A horrible cardiotoxin that protects the humble bungo pit."
	silent_toxin = TRUE
	color = "#EBFF8E"
	base_metab = 0.5 * REAGENTS_METABOLISM
	toxpwr = 0
	taste_description = "tannin"

/datum/reagent/toxin/bungotoxin/on_mob_life(mob/living/carbon/M)
	M.adjustOrganLoss(ORGAN_SLOT_HEART, 3)
	M.confused = M.dizziness //add a tertiary effect here if this is isn't an effective poison.
	var/tox_message = pick("You feel your heart spasm in your chest.", "You feel faint.","You feel you need to catch your breath.","You feel a prickle of pain in your chest.")
	to_chat(M, "<span class='notice'>[tox_message]</span>")
	. = 1
	..()

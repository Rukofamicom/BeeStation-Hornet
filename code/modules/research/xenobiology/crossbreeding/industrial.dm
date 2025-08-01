/*
Industrial extracts:
	Slowly consume plasma, produce items with it.
*/
/obj/item/slimecross/industrial
	name = "industrial extract"
	desc = "A gel-like, sturdy extract, fond of plasma and industry."
	effect = "industrial"
	icon_state = "industrial_still"
	var/plasmarequired = 2 //Units of plasma required to be consumed to produce item.
	var/itempath = /obj/item //The item produced by the extract.
	var/plasmaabsorbed = 0 //Units of plasma aborbed by the extract already. Absorbs at a rate of 2u/obj tick.
	var/itemamount = 1 //How many items to spawn

/obj/item/slimecross/industrial/examine(mob/user)
	. = ..()
	. += "It currently has [plasmaabsorbed] units of plasma floating inside the outer shell, out of [plasmarequired] units."

/obj/item/slimecross/industrial/proc/do_after_spawn(obj/item/spawned)
	return

/obj/item/slimecross/industrial/Initialize(mapload)
	. = ..()
	create_reagents(100, INJECTABLE | DRAWABLE)
	START_PROCESSING(SSobj,src)

/obj/item/slimecross/industrial/Destroy()
	STOP_PROCESSING(SSobj,src)
	return ..()

/obj/item/slimecross/industrial/process()
	var/IsWorking = FALSE
	if(reagents.has_reagent(/datum/reagent/toxin/plasma,amount = 2) && plasmarequired > 1) //Can absorb as much as 2
		IsWorking = TRUE
		reagents.remove_reagent(/datum/reagent/toxin/plasma,2)
		plasmaabsorbed += 2
	else if(reagents.has_reagent(/datum/reagent/toxin/plasma,amount = 1)) //Can absorb as little as 1
		IsWorking = TRUE
		reagents.remove_reagent(/datum/reagent/toxin/plasma,1)
		plasmaabsorbed += 1

	if(plasmaabsorbed >= plasmarequired)
		playsound(src, 'sound/effects/attackblob.ogg', 50, 1)
		plasmaabsorbed -= plasmarequired
		for(var/i in 1 to itemamount)
			do_after_spawn(new itempath(get_turf(src)))
	else if(IsWorking)
		playsound(src, 'sound/effects/bubbles.ogg', 5, 1)
	if(IsWorking)
		icon_state = "industrial"
	else
		icon_state = "industrial_still"

/obj/item/slimecross/industrial/grey
	colour = SLIME_TYPE_GREY
	effect_desc = "Produces monkey cubes."
	itempath = /obj/item/food/monkeycube
	itemamount = 5

/obj/item/slimecross/industrial/orange
	colour = SLIME_TYPE_ORANGE
	effect_desc = "Produces slime zippo lighters."
	plasmarequired = 6
	itempath = /obj/item/lighter/slime

/obj/item/slimecross/industrial/purple
	colour = SLIME_TYPE_PURPLE
	effect_desc = "Produces autoinjectors with regen jelly inside."
	plasmarequired = 5
	itempath = /obj/item/slimecrossbeaker/autoinjector/regenpack

/obj/item/slimecross/industrial/blue
	colour = SLIME_TYPE_BLUE
	effect_desc = "Produces full fire extinguishers."
	plasmarequired = 10
	itempath = /obj/item/extinguisher

/obj/item/slimecross/industrial/metal
	colour = SLIME_TYPE_METAL
	effect_desc = "Produces metal sheets."
	plasmarequired = 3
	itempath = /obj/item/stack/sheet/iron/ten

/obj/item/slimecross/industrial/yellow
	colour = SLIME_TYPE_YELLOW
	effect_desc = "Produces high capacity power cells, which are not fully charged on creation."
	plasmarequired = 5
	itempath = /obj/item/stock_parts/cell/high

/obj/item/slimecross/industrial/yellow/do_after_spawn(obj/item/spawned)
	var/obj/item/stock_parts/cell/high/C = spawned
	if(istype(C))
		C.charge = rand(0,C.maxcharge/2)

/obj/item/slimecross/industrial/darkpurple
	colour = SLIME_TYPE_DARK_PURPLE
	effect_desc = "Produces plasma... for plasma."
	plasmarequired = 10
	itempath = /obj/item/stack/sheet/mineral/plasma

/obj/item/slimecross/industrial/darkblue
	colour = SLIME_TYPE_DARK_BLUE
	effect_desc = "Produces one-use fireproofing potions."
	plasmarequired = 6
	itempath = /obj/item/slimepotion/fireproof

/obj/item/slimecross/industrial/darkblue/do_after_spawn(obj/item/spawned)
	var/obj/item/slimepotion/fireproof/potion = spawned
	if(istype(potion))
		potion.uses = 1

/obj/item/slimecross/industrial/silver
	colour = SLIME_TYPE_SILVER
	effect_desc = "Produces random food and drink items."
	plasmarequired = 1
	//Item picked below.

/obj/item/slimecross/industrial/silver/process()
	itempath = pick(list(get_random_food(), get_random_drink()))
	..()

/obj/item/slimecross/industrial/bluespace
	colour = SLIME_TYPE_BLUESPACE
	effect_desc = "Produces synthetic bluespace crystals."
	plasmarequired = 7
	itempath = /obj/item/stack/ore/bluespace_crystal/artificial

/obj/item/slimecross/industrial/sepia
	colour = SLIME_TYPE_SEPIA
	effect_desc = "Produces cameras."
	plasmarequired = 2
	itempath = /obj/item/camera

/obj/item/slimecross/industrial/cerulean
	colour = SLIME_TYPE_CERULEAN
	effect_desc = "Produces normal slime extract enhancers."
	plasmarequired = 5
	itempath = /obj/item/slimepotion/enhancer

/obj/item/slimecross/industrial/pyrite
	colour = SLIME_TYPE_PYRITE
	effect_desc = "Produces cans of spraypaint."
	plasmarequired = 2
	itempath = /obj/item/toy/crayon/spraycan

/obj/item/slimecross/industrial/red
	colour = SLIME_TYPE_RED
	effect_desc = "Produces blood orbs."
	plasmarequired = 5
	itempath = /obj/item/slimecrossbeaker/bloodpack

/obj/item/slimecross/industrial/green
	colour = SLIME_TYPE_GREEN
	effect_desc = "Produces self-use-only slime jelly autoinjectors."
	plasmarequired = 7
	itempath = /obj/item/slimecrossbeaker/autoinjector/slimejelly

/obj/item/slimecross/industrial/pink
	colour = SLIME_TYPE_PINK
	effect_desc = "Produces synthpax and space drug autoinjectors."
	plasmarequired = 6
	itempath = /obj/item/slimecrossbeaker/autoinjector/peaceandlove

/obj/item/slimecross/industrial/gold
	colour = SLIME_TYPE_GOLD
	effect_desc = "Produces random coins."
	plasmarequired = 10

/obj/item/slimecross/industrial/gold/process()
	itempath = pick(/obj/item/coin/silver, /obj/item/coin/iron, /obj/item/coin/gold, /obj/item/coin/diamond, /obj/item/coin/plasma, /obj/item/coin/uranium)
	..()

/obj/item/slimecross/industrial/oil
	colour = SLIME_TYPE_OIL
	effect_desc = "Produces IEDs."
	plasmarequired = 4
	itempath = /obj/item/grenade/iedcasing
	dangerous = TRUE

/obj/item/slimecross/industrial/black //What does this have to do with black slimes? No clue! Fun, though
	colour = SLIME_TYPE_BLACK
	effect_desc = "Produces slime brand regenerative cigarettes."
	plasmarequired = 6
	itempath = /obj/item/storage/fancy/cigarettes/cigpack_xeno

/obj/item/slimecross/industrial/lightpink
	colour = SLIME_TYPE_LIGHT_PINK
	effect_desc = "Produces heart shaped boxes that have candies in them."
	plasmarequired = 3
	itempath = /obj/item/storage/fancy/heart_box

/obj/item/slimecross/industrial/adamantine
	colour = SLIME_TYPE_ADAMANTINE
	effect_desc = "Produces sheets of adamantine."
	plasmarequired = 10
	itempath = /obj/item/stack/sheet/mineral/adamantine

/obj/item/slimecross/industrial/rainbow
	colour = SLIME_TYPE_RAINBOW
	effect_desc = "Produces random slime extracts."
	plasmarequired = 5
	//Item picked below.

/obj/item/slimecross/industrial/rainbow/process()
	itempath = pick(subtypesof(/obj/item/slime_extract))
	..()

// TURBINE v2 AKA rev4407 Engine reborn!

// How to use it? - Mappers
//
// This is a very good power generating mechanism. All you need is a blast furnace with soaring flames and output.
// Not everything is included yet so the turbine can run out of fuel quiet quickly. The best thing about the turbine is that even
// though something is on fire that passes through it, it won't be on fire as it passes out of it. So the exhaust fumes can still
// containt unreacted fuel - plasma and oxygen that needs to be filtered out and re-routed back. This of course requires smart piping
// For a computer to work with the turbine the compressor requires a comp_id matching with the turbine computer's id. This will be
// subjected to a change in the near future mind you. Right now this method of generating power is a good backup but don't expect it
// become a main power source unless some work is done. Have fun. At 50k RPM it generates 60k power. So more than one turbine is needed!
//
// - Numbers
//
// Example setup	 S - sparker
//					 B - Blast doors into space for venting
// *BBB****BBB*		 C - Compressor
// S    CT    *		 T - Turbine
// * ^ *  * V *		 D - Doors with firedoor
// **|***D**|**      ^ - Fuel feed (Not vent, but a gas outlet)
//   |      |        V - Suction vent (Like the ones in atmos
//


/obj/machinery/power/compressor
	name = "compressor"
	desc = "The compressor stage of a gas turbine generator."
	icon = 'icons/obj/atmospherics/pipes/simple.dmi'
	icon_state = "compressor"
	density = TRUE
	resistance_flags = FIRE_PROOF
	can_atmos_pass = ATMOS_PASS_DENSITY
	circuit = /obj/item/circuitboard/machine/power_compressor
	var/obj/machinery/power/turbine/turbine
	var/datum/gas_mixture/gas_contained
	var/turf/inturf
	var/starter = 0
	var/rpm = 0
	var/rpmtarget = 0
	var/capacity = 1e6
	var/comp_id = 0
	var/efficiency

/obj/machinery/power/compressor/Destroy()
	if (turbine && turbine.compressor == src)
		turbine.compressor = null
	turbine = null
	return ..()

/obj/machinery/power/turbine
	name = "gas turbine generator"
	desc = "A gas turbine used for backup power generation."
	icon = 'icons/obj/atmospherics/pipes/simple.dmi'
	icon_state = "turbine"
	density = TRUE
	resistance_flags = FIRE_PROOF
	can_atmos_pass = ATMOS_PASS_DENSITY
	circuit = /obj/item/circuitboard/machine/power_turbine


	var/opened = 0
	var/obj/machinery/power/compressor/compressor
	var/turf/outturf
	var/lastgen
	var/productivity = 1
	var/destroy_output = FALSE //Destroy the output gas instead of actually outputting it. Used on lavaland to prevent cooking the zlevel

/obj/machinery/power/turbine/lavaland
	destroy_output = TRUE

/obj/machinery/power/turbine/Destroy()
	if (compressor && compressor.turbine == src)
		compressor.turbine = null
	compressor = null
	return ..()

// the inlet stage of the gas turbine electricity generator

/obj/machinery/power/compressor/Initialize(mapload)
	. = ..()
	// The inlet of the compressor is the direction it faces
	gas_contained = new
	inturf = get_step(src, dir)
	locate_machinery()
	if(!turbine)
		atom_break()


#define COMPFRICTION 5e5

/obj/machinery/power/compressor/locate_machinery()
	if(turbine)
		return
	turbine = locate() in get_step(src, get_dir(inturf, src))
	if(turbine)
		turbine.locate_machinery()

/obj/machinery/power/compressor/RefreshParts()
	var/E = 0
	for(var/obj/item/stock_parts/manipulator/M in component_parts)
		E += M.rating
	efficiency = E / 6

/obj/machinery/power/compressor/examine(mob/user)
	. = ..()
	if(in_range(user, src) || isobserver(user))
		. += span_notice("The status display reads: Efficiency at <b>[efficiency*100]%</b>.")

/obj/machinery/power/compressor/attackby(obj/item/I, mob/user, params)
	if(default_deconstruction_screwdriver(user, initial(icon_state), initial(icon_state), I))
		return

	if(default_change_direction_wrench(user, I))
		turbine = null
		inturf = get_step(src, dir)
		locate_machinery()
		if(turbine)
			to_chat(user, span_notice("Turbine connected."))
			set_machine_stat(machine_stat & ~BROKEN)
		else
			to_chat(user, span_alert("Turbine not connected."))
			atom_break()
		return

	default_deconstruction_crowbar(I)

/obj/machinery/power/compressor/process()
	if(!starter)
		return
	if(!turbine || (turbine.machine_stat & BROKEN))
		starter = FALSE
	if(machine_stat & BROKEN || panel_open)
		starter = FALSE
		return
	cut_overlays()

	if(istype(inturf, /turf/open))
		rpm = 0.9 * rpm + 0.1 * rpmtarget
		var/datum/gas_mixture/environment = inturf.return_air()

	// It's a simplified version taking only 1/10 of the moles from the turf nearby. It should be later changed into a better version

		var/transfer_moles = environment.total_moles()/10
		var/datum/gas_mixture/removed = inturf.remove_air(transfer_moles)
		gas_contained.merge(removed)
	else
		rpm = 0.9 * rpm // rpmtarget is basically 0, the intake is completely blocked with no airflow

// RPM function to include compression friction - be advised that too low/high of a compfriction value can make things screwy

	rpm = min(rpm, (COMPFRICTION*efficiency)/2)
	rpm = max(0, rpm - (rpm*rpm)/(COMPFRICTION*efficiency))

	if(starter && !(machine_stat & NOPOWER))
		use_power(2800)
		if(rpm<1000)
			rpmtarget = 1000
	else
		if(rpm<1000)
			rpmtarget = 0

	if(rpm>50000)
		add_overlay(mutable_appearance(icon, "comp-o4", FLY_LAYER))
	else if(rpm>10000)
		add_overlay(mutable_appearance(icon, "comp-o3", FLY_LAYER))
	else if(rpm>2000)
		add_overlay(mutable_appearance(icon, "comp-o2", FLY_LAYER))
	else if(rpm>500)
		add_overlay(mutable_appearance(icon, "comp-o1", FLY_LAYER))
	//TODO: DEFERRED

// These are crucial to working of a turbine - the stats modify the power output. TurbGenQ modifies how much raw energy can you get from
// rpms, TurbGenG modifies the shape of the curve - the lower the value the less straight the curve is.

#define TURBGENQ 100000
#define TURBGENG 0.5

/obj/machinery/power/turbine/Initialize(mapload)
	. = ..()
// The outlet is pointed at the direction of the turbine component
	outturf = get_step(src, dir)
	locate_machinery()
	if(!compressor)
		atom_break()
	connect_to_network()

/obj/machinery/power/turbine/RefreshParts()
	var/P = 0
	for(var/obj/item/stock_parts/capacitor/C in component_parts)
		P += C.rating
	productivity = P / 6

/obj/machinery/power/turbine/examine(mob/user)
	. = ..()
	if(in_range(user, src) || isobserver(user))
		. += span_notice("The status display reads: Productivity at <b>[productivity*100]%</b>.")

/obj/machinery/power/turbine/locate_machinery()
	if(compressor)
		return
	compressor = locate() in get_step(src, get_dir(outturf, src))
	if(compressor)
		compressor.locate_machinery()

/obj/machinery/power/turbine/process()

	if(!compressor)
		machine_stat = BROKEN

	if((machine_stat & BROKEN) || panel_open)
		return
	if(!compressor.starter)
		return
	cut_overlays()

	// This is the power generation function. If anything is needed it's good to plot it in EXCEL before modifying
	// the TURBGENQ and TURBGENG values

	lastgen = ((compressor.rpm / TURBGENQ)**TURBGENG) * TURBGENQ * productivity

	add_avail(lastgen)

	// Weird function but it works. Should be something else...

	var/newrpm = ((compressor.gas_contained.temperature) * compressor.gas_contained.total_moles())/4

	newrpm = max(0, newrpm)

	if(!compressor.starter || newrpm > 1000)
		compressor.rpmtarget = newrpm

	if(compressor.gas_contained.total_moles()>0)
		var/oamount = min(compressor.gas_contained.total_moles(), (compressor.rpm+100)/35000*compressor.capacity)
		var/datum/gas_mixture/removed = compressor.gas_contained.remove(oamount)
		outturf.assume_air(removed)

// If it works, put an overlay that it works!

	if(lastgen > 100)
		add_overlay(mutable_appearance(icon, "turb-o", FLY_LAYER))

/obj/machinery/power/turbine/attackby(obj/item/I, mob/user, params)
	if(default_deconstruction_screwdriver(user, initial(icon_state), initial(icon_state), I))
		return

	if(default_change_direction_wrench(user, I))
		compressor = null
		outturf = get_step(src, dir)
		locate_machinery()
		if(compressor)
			to_chat(user, span_notice("Compressor connected."))
			set_machine_stat(machine_stat & ~BROKEN)
		else
			to_chat(user, span_alert("Compressor not connected."))
			atom_break()
		return

	default_deconstruction_crowbar(I)


/obj/machinery/power/turbine/ui_state(mob/user)
	return GLOB.default_state

/obj/machinery/power/turbine/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "TurbineComputer")
		ui.open()
		ui.set_autoupdate(TRUE) // Turbine stats (power, RPM, temperature)

/obj/machinery/power/turbine/ui_data(mob/user)
	var/list/data = list()
	data["compressor"] = compressor ? TRUE : FALSE
	data["compressor_broke"] = (!compressor || (compressor.machine_stat & BROKEN)) ? TRUE : FALSE
	data["turbine"] = compressor?.turbine ? TRUE : FALSE
	data["turbine_broke"] = (!compressor || !compressor.turbine || (compressor.turbine.machine_stat & BROKEN)) ? TRUE : FALSE
	data["online"] = compressor?.starter
	data["power"] = display_power(compressor?.turbine?.lastgen)
	data["rpm"] = compressor?.rpm
	data["temp"] = compressor?.gas_contained.temperature
	return data

/obj/machinery/power/turbine/ui_act(action, params)
	if(..())
		return

	switch(action)
		if("toggle_power")
			if(compressor && compressor.turbine)
				compressor.starter = !compressor.starter
				. = TRUE
		if("reconnect")
			locate_machinery()
			. = TRUE


/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// COMPUTER NEEDS A SERIOUS REWRITE.

/obj/machinery/computer/turbine_computer
	name = "gas turbine control computer"
	desc = "A computer to remotely control a gas turbine."
	icon_screen = "turbinecomp"
	icon_keyboard = "tech_key"
	circuit = /obj/item/circuitboard/computer/turbine_computer


	var/obj/machinery/power/compressor/compressor
	var/id = 0

/obj/machinery/computer/turbine_computer/Initialize(mapload)
	. = ..()
	return INITIALIZE_HINT_LATELOAD

/obj/machinery/computer/turbine_computer/LateInitialize()
	locate_machinery()

/obj/machinery/computer/turbine_computer/locate_machinery()
	if(id)
		for(var/obj/machinery/power/compressor/C in GLOB.machines)
			if(C.comp_id == id)
				compressor = C
				return
	// Couldn't find compressor, time to do search indiscriminately
	compressor = locate(/obj/machinery/power/compressor) in range(7, src)

/obj/machinery/computer/turbine_computer/ui_interact(mob/user, ui_key = "main", datum/tgui/ui = null, force_open = FALSE, \
									datum/tgui/master_ui = null, datum/ui_state/state = GLOB.default_state)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "TurbineComputer")
		ui.open()
		ui.set_autoupdate(TRUE) // Turbine stats (power, RPM, temperature)

/obj/machinery/computer/turbine_computer/ui_data(mob/user)
	var/list/data = list()
	data["compressor"] = compressor ? TRUE : FALSE
	data["compressor_broke"] = (!compressor || (compressor.machine_stat & BROKEN)) ? TRUE : FALSE
	data["turbine"] = compressor?.turbine ? TRUE : FALSE
	data["turbine_broke"] = (!compressor || !compressor.turbine || (compressor.turbine.machine_stat & BROKEN)) ? TRUE : FALSE
	data["online"] = compressor?.starter
	data["power"] = display_power(compressor?.turbine?.lastgen)
	data["rpm"] = compressor?.rpm
	data["temp"] = compressor?.gas_contained.temperature
	return data

/obj/machinery/computer/turbine_computer/ui_act(action, params)
	if(..())
		return

	switch(action)
		if("toggle_power")
			if(compressor && compressor.turbine)
				compressor.starter = !compressor.starter
				. = TRUE
		if("reconnect")
			locate_machinery()
			. = TRUE

#undef COMPFRICTION
#undef TURBGENQ
#undef TURBGENG

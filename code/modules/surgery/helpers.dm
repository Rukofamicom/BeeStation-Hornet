/proc/attempt_initiate_surgery(obj/item/I, mob/living/M, mob/user)
	if(!istype(M))
		return

	var/datum/surgery/current_surgery

	for(var/datum/surgery/S in M.surgeries)
		current_surgery = S

	if(!current_surgery)
		var/datum/task/zone_selector = user.select_bodyzone(M, TRUE)
		zone_selector.continue_with(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(initiate_surgery_at_zone), I, M, user))

	else if(!current_surgery.step_in_progress)
		attempt_cancel_surgery(current_surgery, I, M, user)

	return 1

/proc/initiate_surgery_at_zone(obj/item/I, mob/living/M, mob/user, target_zone)
	var/list/all_surgeries = GLOB.surgeries_list.Copy()
	var/list/available_surgeries = list()

	var/mob/living/carbon/C
	if (iscarbon(M))
		C = M

	var/obj/item/bodypart/affecting = M.get_bodypart(check_zone(target_zone))

	for(var/datum/surgery/S in all_surgeries)
		if(!S.possible_locs.Find(target_zone))
			continue
		if(affecting)
			if(!S.requires_bodypart)
				continue
			if(S.requires_bodypart_type && !(affecting.bodytype & S.requires_bodypart_type))
				continue
			if(S.requires_real_bodypart && affecting.is_pseudopart)
				continue
		else if(C && S.requires_bodypart) //mob with no limb in surgery zone when we need a limb
			continue
		if(S.lying_required && M.body_position != LYING_DOWN)
			continue
		if(!S.can_start(user, M, target_zone))
			continue
		for(var/path in S.target_mobtypes)
			if(istype(M, path))
				available_surgeries[S.name] = S
				break

	if(!available_surgeries.len)
		return

	var/P = tgui_input_list(user, "Begin which procedure?", "Surgery", sort_list(available_surgeries))
	if(isnull(P))
		return
	if(user && user.Adjacent(M) && (I in user))
		var/datum/surgery/S = available_surgeries[P]

		for(var/datum/surgery/other in M.surgeries)
			if(other.location == S.location)
				return //during the input() another surgery was started at the same location.

		//we check that the surgery is still doable after the input() wait.
		if(C)
			affecting = C.get_bodypart(check_zone(target_zone))
		if(affecting)
			if(!S.requires_bodypart)
				return
			if(S.requires_bodypart_type && !(affecting.bodytype & S.requires_bodypart_type))
				return
		else if(C && S.requires_bodypart)
			return
		if(S.lying_required && M.body_position != LYING_DOWN)
			return
		if(!S.can_start(user, M, target_zone))
			return

		if(S.ignore_clothes || get_location_accessible(M, target_zone))
			var/datum/surgery/procedure = new S.type(M, target_zone, affecting)
			user.visible_message("[user] drapes [I] over [M]'s [parse_zone(target_zone)] to prepare for surgery.",
			span_notice("You drape [I] over [M]'s [parse_zone(target_zone)] to prepare for \an [procedure.name]."))
			I.balloon_alert(user, "You drape over [parse_zone(target_zone)].")

			log_combat(user, M, "operated on", null, "(OPERATION TYPE: [procedure.name]) (TARGET AREA: [target_zone])")
		else
			I.balloon_alert(user, "[parse_zone(target_zone)] is covered up!")

/proc/attempt_cancel_surgery(datum/surgery/S, obj/item/I, mob/living/M, mob/user)
	if(S.status == 1)
		M.surgeries -= S
		user.visible_message("[user] removes [I] from [M]'s [parse_zone(S.location)].", \
			span_notice("You remove [I] from [M]'s [parse_zone(S.location)]."))
		I.balloon_alert(user, "You remove [I] from [parse_zone(S.location)].")
		qdel(S)
		return

	if(S.can_cancel)
		var/required_tool_type = TOOL_CAUTERY
		var/obj/item/close_tool = user.get_inactive_held_item()
		var/is_robotic = S.requires_bodypart_type == BODYTYPE_ROBOTIC

		if(is_robotic)
			required_tool_type = TOOL_SCREWDRIVER

		if(iscyborg(user))
			close_tool = locate(/obj/item/cautery) in user.held_items
			if(!close_tool)
				to_chat(user, span_warning("You need to equip a cautery in an inactive slot to stop [M]'s surgery!"))
				return
		else if(close_tool?.tool_behaviour != required_tool_type)
			to_chat(user, span_warning("You need to hold a [is_robotic ? "screwdriver" : "cautery"] in your inactive hand to stop [M]'s surgery!"))
			return
		M.surgeries -= S
		user.visible_message(span_notice("[user] closes [M]'s [parse_zone(S.location)] with [close_tool] and removes [I]."), \
			span_notice("You close [M]'s [parse_zone(S.location)] with [close_tool] and remove [I]."))
		qdel(S)

/proc/get_location_accessible(mob/M, location)
	var/covered_locations = 0	//based on body_parts_covered
	var/face_covered = 0	//based on flags_inv
	var/eyesmouth_covered = 0	//based on flags_cover
	if(iscarbon(M))
		var/mob/living/carbon/C = M
		for(var/obj/item/clothing/I in list(C.back, C.wear_mask, C.head))
			covered_locations |= I.body_parts_covered
			face_covered |= I.flags_inv
			eyesmouth_covered |= I.flags_cover
		if(ishuman(C))
			var/mob/living/carbon/human/H = C
			for(var/obj/item/I in list(H.wear_suit, H.w_uniform, H.shoes, H.belt, H.gloves, H.glasses, H.ears))
				covered_locations |= I.body_parts_covered
				face_covered |= I.flags_inv
				eyesmouth_covered |= I.flags_cover

	switch(location)
		if(BODY_ZONE_HEAD)
			if(covered_locations & HEAD)
				return 0
		if(BODY_ZONE_PRECISE_EYES)
			if(covered_locations & HEAD || face_covered & HIDEEYES || eyesmouth_covered & GLASSESCOVERSEYES)
				return 0
		if(BODY_ZONE_PRECISE_MOUTH)
			if(covered_locations & HEAD || face_covered & HIDEFACE || eyesmouth_covered & MASKCOVERSMOUTH || eyesmouth_covered & HEADCOVERSMOUTH)
				return 0
		if(BODY_ZONE_CHEST)
			if(covered_locations & CHEST)
				return 0
		if(BODY_ZONE_PRECISE_GROIN)
			if(covered_locations & GROIN)
				return 0
		if(BODY_ZONE_L_ARM)
			if(covered_locations & ARM_LEFT)
				return 0
		if(BODY_ZONE_R_ARM)
			if(covered_locations & ARM_RIGHT)
				return 0
		if(BODY_ZONE_L_LEG)
			if(covered_locations & LEG_LEFT)
				return 0
		if(BODY_ZONE_R_LEG)
			if(covered_locations & LEG_RIGHT)
				return 0
		if(BODY_ZONE_PRECISE_L_HAND)
			if(covered_locations & HAND_LEFT)
				return 0
		if(BODY_ZONE_PRECISE_R_HAND)
			if(covered_locations & HAND_RIGHT)
				return 0
		if(BODY_ZONE_PRECISE_L_FOOT)
			if(covered_locations & FOOT_LEFT)
				return 0
		if(BODY_ZONE_PRECISE_R_FOOT)
			if(covered_locations & FOOT_RIGHT)
				return 0

	return 1


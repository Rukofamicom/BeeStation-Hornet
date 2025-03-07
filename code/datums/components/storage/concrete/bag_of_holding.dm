/datum/component/storage/concrete/bluespace/bag_of_holding/handle_item_insertion(obj/item/W, prevent_warning = FALSE, mob/living/user)
	var/atom/A = parent
	if(A == W)		//don't put yourself into yourself.
		return
	var/list/obj/item/storage/backpack/holding/matching = typecache_filter_list(W.GetAllContents(), typecacheof(/obj/item/storage/backpack/holding))
	matching -= A
	if(istype(W, /obj/item/storage/backpack/holding) || matching.len)
		INVOKE_ASYNC(src, PROC_REF(recursive_insertion), W, user)
		return
	. = ..()

/datum/component/storage/concrete/bluespace/bag_of_holding/proc/recursive_insertion(obj/item/W, mob/living/user)
	var/atom/A = parent
	var/safety = alert(user, "Doing this will have extremely dire consequences for the station and its crew. Be sure you know what you're doing.", "Put in [A.name]?", "Abort", "Proceed")
	if(safety != "Proceed" || QDELETED(A) || QDELETED(W) || QDELETED(user) || !user.canUseTopic(A, BE_CLOSE, iscarbon(user)))
		return
	safety = alert(user, "ARE YOU SURE???", "Put in [A.name]?", "YES", "Abort")
	if(safety != "YES" || QDELETED(A) || QDELETED(W) || QDELETED(user) || !user.canUseTopic(A, BE_CLOSE, iscarbon(user)) || !(W in user.contents)) // need to be holding the bag you're "inserting"
		return
	var/turf/loccheck = get_turf(A)
	if(is_reebe(loccheck.z))
		user.visible_message(span_warning("An unseen force knocks [user] to the ground!"), "[span_bigbrass("\"I think not!\"")]")
		user.Paralyze(60)
		return
	to_chat(user, span_danger("The Bluespace interfaces of the two devices catastrophically malfunction!"))
	qdel(W)
	playsound(loccheck,'sound/effects/supermatter.ogg', 200, 1)

	message_admins("[ADMIN_LOOKUPFLW(user)] detonated a bag of holding at [ADMIN_VERBOSEJMP(loccheck)].")
	log_game("[key_name(user)] detonated a bag of holding at [loc_name(loccheck)].")

	user.investigate_log("has been gibbed by a bag of holding recursive insertion.", INVESTIGATE_DEATHS)
	user.gib(TRUE, TRUE, TRUE)
	new/obj/boh_tear(loccheck)
	qdel(A)


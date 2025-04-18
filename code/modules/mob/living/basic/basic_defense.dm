/mob/living/basic/attack_hand(mob/living/carbon/human/user, list/modifiers)
	// so that martial arts don't double dip
	if(..())
		return TRUE

	if(LAZYACCESS(modifiers, RIGHT_CLICK))
		if(user.move_force < move_resist)
			return
		user.do_attack_animation(src, ATTACK_EFFECT_DISARM)
		playsound(src, 'sound/weapons/thudswoosh.ogg', 50, TRUE, -1)
		var/shove_dir = get_dir(user, src)
		if(!Move(get_step(src, shove_dir), shove_dir))
			log_combat(user, src, "shoved (failing to move it)", user)
			visible_message("<span class='danger'>[user] [response_disarm_continuous] [src]!</span>", \
							"<span class='userdanger'>[user] [response_disarm_continuous] you!</span>", \
							"<span class='hear'>You hear aggressive shuffling!</span>", COMBAT_MESSAGE_RANGE, list(user))
			to_chat(user, "<span class='danger'>You [response_disarm_simple] [src]!</span>")
			return TRUE
		else
			log_combat(user, src, "shoved", user)
			visible_message("<span class='danger'>[user] [response_disarm_continuous] [src], pushing [p_them()]!</span>", \
							"<span class='userdanger'>You're pushed by [user]!</span>", \
							"<span class='hear'>You hear aggressive shuffling!</span>", COMBAT_MESSAGE_RANGE, list(user))
			to_chat(user, "<span class='danger'>You [response_disarm_simple] [src], pushing [p_them()]!</span>")
		return TRUE

	if(!user.combat_mode)
		if(stat == DEAD)
			return
		visible_message("<span class='notice'>[user] [response_help_continuous] [src].</span>", \
						"<span class='notice'>[user] [response_help_continuous] you.</span>", null, null, list(user))
		to_chat(user, "<span class='notice'>You [response_help_simple] [src].</span>")
		playsound(loc, 'sound/weapons/thudswoosh.ogg', 50, TRUE, -1)
	else
		if(HAS_TRAIT(user, TRAIT_PACIFISM))
			to_chat(user, "<span class='warning'>You don't want to hurt [src]!</span>")
			return
		user.do_attack_animation(src, ATTACK_EFFECT_PUNCH)
		visible_message("<span class='danger'>[user] [response_harm_continuous] [src]!</span>",\
						"<span class='userdanger'>[user] [response_harm_continuous] you!</span>", null, COMBAT_MESSAGE_RANGE, list(user))
		to_chat(user, "<span class='danger'>You [response_harm_simple] [src]!</span>")
		playsound(loc, attacked_sound, 25, TRUE, -1)

		attack_threshold_check(user.dna.species.punchdamage)
		log_combat(user, src, "attacked", user)
		updatehealth()
		return TRUE

/mob/living/basic/attack_hulk(mob/living/carbon/human/user)
	. = ..()
	if(!.)
		return
	playsound(loc, "punch", 25, TRUE, -1)
	visible_message(span_danger("[user] punches [src]!"), \
					span_userdanger("You're punched by [user]!"), null, COMBAT_MESSAGE_RANGE, user)
	to_chat(user, span_danger("You punch [src]!"))
	adjustBruteLoss(15)

/mob/living/basic/attack_paw(mob/living/carbon/human/user, list/modifiers)
	if(..()) //successful monkey bite.
		if(stat != DEAD)
			var/damage = rand(1, 3)
			attack_threshold_check(damage)
			return 1
	if (!user.combat_mode)
		if (health > 0)
			visible_message(span_notice("[user.name] [response_help_continuous] [src]."), \
							span_notice("[user.name] [response_help_continuous] you."), null, COMBAT_MESSAGE_RANGE, user)
			to_chat(user, span_notice("You [response_help_simple] [src]."))
			playsound(loc, 'sound/weapons/thudswoosh.ogg', 50, TRUE, -1)


/mob/living/basic/attack_alien(mob/living/carbon/alien/humanoid/user, list/modifiers)
	if(..()) //if harm or disarm intent.
		if(LAZYACCESS(modifiers, RIGHT_CLICK))
			playsound(loc, 'sound/weapons/pierce.ogg', 25, TRUE, -1)
			visible_message(span_danger("[user] [response_disarm_continuous] [name]!"), \
							span_userdanger("[user] [response_disarm_continuous] you!"), null, COMBAT_MESSAGE_RANGE, user)
			to_chat(user, span_danger("You [response_disarm_simple] [name]!"))
			log_combat(user, src, "disarmed", user)
		else
			var/damage = rand(15, 30)
			visible_message(span_danger("[user] slashes at [src]!"), \
							span_userdanger("You're slashed at by [user]!"), null, COMBAT_MESSAGE_RANGE, user)
			to_chat(user, span_danger("You slash at [src]!"))
			playsound(loc, 'sound/weapons/slice.ogg', 25, TRUE, -1)
			attack_threshold_check(damage)
			log_combat(user, src, "attacked", user)
		return 1

/mob/living/basic/attack_larva(mob/living/carbon/alien/larva/L, list/modifiers)
	. = ..()
	if(. && stat != DEAD) //successful larva bite
		var/damage = rand(5, 10)
		. = attack_threshold_check(damage)
		if(.)
			L.amount_grown = min(L.amount_grown + damage, L.max_grown)

/mob/living/basic/attack_basic_mob(mob/living/basic/user)
	. = ..()
	if(.)
		// var/damage = rand(user.melee_damage_lower, user.melee_damage_upper) // We don't have melee_damage_lower and melee_damage_upper, kept to make this easier to understand and drop-in in the future
		return attack_threshold_check(user.melee_damage, user.melee_damage_type)

/mob/living/basic/attack_animal(mob/living/simple_animal/user)
	. = ..()
	if(.)
		// var/damage = rand(user.melee_damage_lower, user.melee_damage_upper) // We don't have melee_damage_lower and melee_damage_upper, kept to make this easier to understand and drop-in in the future
		return attack_threshold_check(user.melee_damage, user.melee_damage_type)

/mob/living/basic/attack_slime(mob/living/simple_animal/slime/M, list/modifiers)
	if(..()) //successful slime attack
		var/damage = 20
		if(M.is_adult)
			damage = 30
		if(M.transformeffects & SLIME_EFFECT_RED)
			damage *= 1.1
		return attack_threshold_check(damage)

/mob/living/basic/attack_drone(mob/living/simple_animal/drone/M)
	if(M.combat_mode) //No kicking dogs even as a rogue drone. Use a weapon.
		return
	return ..()

/mob/living/basic/attack_drone_secondary(mob/living/simple_animal/drone/M)
	if(M.combat_mode)
		return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN
	return ..()

/mob/living/basic/proc/attack_threshold_check(damage, damagetype = BRUTE, armorcheck = MELEE, actuallydamage = TRUE)
	var/temp_damage = damage
	if(!damage_coeff[damagetype])
		temp_damage = 0
	else
		temp_damage *= damage_coeff[damagetype]

	if(temp_damage >= 0 && temp_damage <= force_threshold)
		visible_message(span_warning("[src] looks unharmed."))
		return FALSE
	else
		apply_damage(damage, damagetype, null, getarmor(null, armorcheck))
		return TRUE

/mob/living/basic/bullet_act(obj/projectile/Proj, def_zone, piercing_hit = FALSE)
	apply_damage(Proj.damage, Proj.damage_type)
	Proj.on_hit(src, 0, piercing_hit)
	return BULLET_ACT_HIT

/mob/living/basic/ex_act(severity, target, origin)
	if(origin && istype(origin, /datum/spacevine_mutation) && isvineimmune(src))
		return FALSE

	..()
	if(QDELETED(src))
		return
	var/bomb_armor = getarmor(null, BOMB)
	switch (severity)
		if (EXPLODE_DEVASTATE)
			if(prob(bomb_armor))
				adjustBruteLoss(500)
			else
				investigate_log("has been gibbed by an explosion.", INVESTIGATE_DEATHS)
				gib()
				return
		if (EXPLODE_HEAVY)
			var/bloss = 60
			if(prob(bomb_armor))
				bloss = bloss / 1.5
			adjustBruteLoss(bloss)

		if (EXPLODE_LIGHT)
			var/bloss = 30
			if(prob(bomb_armor))
				bloss = bloss / 1.5
			adjustBruteLoss(bloss)

/mob/living/basic/blob_act(obj/structure/blob/B)
	adjustBruteLoss(20)
	return

/mob/living/basic/do_attack_animation(atom/A, visual_effect_icon, used_item, no_effect)
	if(!no_effect && !visual_effect_icon && melee_damage)
		if(melee_damage < 10)
			visual_effect_icon = ATTACK_EFFECT_PUNCH
		else
			visual_effect_icon = ATTACK_EFFECT_SMASH
	..()


/mob/living/basic/update_stat()
	if(status_flags & GODMODE)
		return
	if(stat != DEAD)
		if(health <= 0)
			death()
		else
			set_stat(CONSCIOUS)
	med_hud_set_status()

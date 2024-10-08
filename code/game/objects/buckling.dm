
/atom/movable
	var/can_buckle = 0
	var/buckle_lying = -1 //bed-like behaviour, forces mob.lying = buckle_lying if != -1
	var/buckle_requires_restraints = 0 //require people to be handcuffed before being able to buckle. eg: pipes
	var/list/mob/living/buckled_mobs = null //list()
	var/max_buckled_mobs = 1
	var/buckle_prevents_pull = FALSE

//Interaction
/atom/movable/attack_hand(mob/living/user)
	. = ..()
	if(.)
		return
	if(can_buckle && has_buckled_mobs())
		if(buckled_mobs.len > 1)
			var/unbuckled = input(user, "Who do you wish to unbuckle?","Unbuckle Who?") as null|mob in buckled_mobs
			if(user_unbuckle_mob(unbuckled,user))
				return 1
		else
			if(user_unbuckle_mob(buckled_mobs[1],user))
				return 1

/atom/movable/MouseDrop_T(mob/living/M, mob/living/user)
	. = ..()
	if(can_buckle && istype(M) && istype(user))
		if(user_buckle_mob(M, user))
			return 1

/atom/movable/proc/has_buckled_mobs()
	if(!buckled_mobs)
		return FALSE
	if(buckled_mobs.len)
		return TRUE

//procs that handle the actual buckling and unbuckling
/atom/movable/proc/buckle_mob(mob/living/M, force = FALSE, check_loc = TRUE)
	if(!buckled_mobs)
		buckled_mobs = list()

	if(!istype(M))
		return FALSE

	if(check_loc && M.loc != loc)
		return FALSE

	if((!can_buckle && !force) || M.buckled || (buckled_mobs.len >= max_buckled_mobs) || (buckle_requires_restraints && !M.restrained()) || M == src)
		return FALSE
	M.buckling = src
	if(!M.can_buckle() && !force)
		if(M == usr)
			to_chat(M, "<span class='warning'>You are unable to buckle yourself to [src]!</span>")
		else
			to_chat(usr, "<span class='warning'>You are unable to buckle [M] to [src]!</span>")
		M.buckling = null
		return FALSE

	if(M.pulledby && buckle_prevents_pull)
		M.pulledby.stop_pulling()

	if(!check_loc && M.loc != loc)
		M.forceMove(loc)

	M.buckling = null
	M.buckled = src
	M.setDir(dir)
	buckled_mobs |= M
	M.update_canmove()
	M.throw_alert("buckled", /obj/screen/alert/restrained/buckled)
	M.set_glide_size(glide_size)
	post_buckle_mob(M)

	SEND_SIGNAL(src, COMSIG_MOVABLE_BUCKLE, M, force)
	return TRUE

/obj/buckle_mob(mob/living/M, force = FALSE, check_loc = TRUE)
	. = ..()
	if(.)
		if(resistance_flags & ON_FIRE) //Sets the mob on fire if you buckle them to a burning atom/movableect
			M.adjust_fire_stacks(1)
			M.IgniteMob()

/atom/movable/proc/unbuckle_mob(mob/living/buckled_mob, force=FALSE)
	if(istype(buckled_mob) && buckled_mob.buckled == src && (buckled_mob.can_unbuckle() || force))
		. = buckled_mob
		buckled_mob.buckled = null
		buckled_mob.anchored = initial(buckled_mob.anchored)
		buckled_mob.update_canmove()
		buckled_mob.clear_alert("buckled")
		buckled_mob.set_glide_size(DELAY_TO_GLIDE_SIZE(buckled_mob.total_multiplicative_slowdown()))
		buckled_mobs -= buckled_mob
		SEND_SIGNAL(src, COMSIG_MOVABLE_UNBUCKLE, buckled_mob, force)

		post_unbuckle_mob(.)

/atom/movable/proc/unbuckle_all_mobs(force=FALSE)
	if(!has_buckled_mobs())
		return
	for(var/m in buckled_mobs)
		unbuckle_mob(m, force)

//Handle any extras after buckling
//Called on buckle_mob()
/atom/movable/proc/post_buckle_mob(mob/living/M)

//same but for unbuckle
/atom/movable/proc/post_unbuckle_mob(mob/living/M)

//Wrapper procs that handle sanity and user feedback
/atom/movable/proc/user_buckle_mob(mob/living/carbon/M, mob/user, check_loc = TRUE)
	if(!in_range(user, src) || !isturf(user.loc) || user.incapacitated() || M.anchored)
		return FALSE

	add_fingerprint(user)
	. = buckle_mob(M, check_loc = check_loc)
	if(!.)
		return

	var/breaking_weight = M?.client?.prefs?.chair_breakage
	if(isnull(breaking_weight) || (breaking_weight < 10) || (M != user) || ((breaking_weight / 3) > M.fatness))
		M.visible_message(\
			"<span class='warning'>[user] buckles [M] to [src]!</span>",\
			"<span class='warning'>[user] buckles you to [src]!</span>",\
			"<span class='italics'>You hear metal clanking.</span>")
		return

	if ((M.fatness >= breaking_weight) && istype(src, /obj/structure/chair)) //GS13 stuff - chair breaking mechanics
		M.visible_message(\
			"<span class='notice'>[M] slowly buckles [M.p_them()]self to [src]. their movements slow and deliberate. As [M] settles into the seat, a sudden, violent crash echoes through the air. [M]'s massive weight mercilessly crushes the poor [src], reducing it to pieces! </span>",\
			"<span class='notice'>You slowly try to buckle yourself to [src]. But it breaks under your massive ass!</span>",\
			"<span class='italics'>You hear metal clanking.</span>")
		playsound(loc, 'sound/effects/snap.ogg', 50, 1)
		playsound(loc, 'sound/effects/woodhit.ogg', 50, 1)
		playsound(loc, 'sound/effects/bodyfall4.ogg', 50, 1)
					// Destroy the src object
		src.Destroy()
	else if(M.fatness >= (breaking_weight / 2))
		M.visible_message(\
			"<span class='notice'>[M] buckles [M.p_them()]self to the creaking [src]. The [src] protests audibly under the weight as [M]'s ample form settles onto its surface. .</span>",\
			"<span class='notice'>You buckle yourself to [src].The [src] is cracking and is barely able to hold your weight </span>",\
			"<span class='italics'>You hear metal clanking.</span>")
		playsound(loc, 'sound/effects/crossed.ogg', 50, 1)
	else if(M.fatness >= (breaking_weight / 3))
		M.visible_message(\
			"<span class='notice'>[M] buckles [M.p_them()]self to the creaking [src] as their weight spreads all over it.</span>",\
			"<span class='notice'>You buckle yourself to [src].The [src] is creaking as you shuffle a bit </span>",\
			"<span class='italics'>You hear metal clanking.</span>")
		playsound(loc, 'sound/effects/crossed.ogg', 50, 1)


/atom/movable/proc/user_unbuckle_mob(mob/living/buckled_mob, mob/user)
	var/mob/living/M = unbuckle_mob(buckled_mob)
	if(M)
		if(M != user)
			M.visible_message(\
				"<span class='notice'>[user] unbuckles [M] from [src].</span>",\
				"<span class='notice'>[user] unbuckles you from [src].</span>",\
				"<span class='italics'>You hear metal clanking.</span>")
		else
			M.visible_message(\
				"<span class='notice'>[M] unbuckles [M.p_them()]self from [src].</span>",\
				"<span class='notice'>You unbuckle yourself from [src].</span>",\
				"<span class='italics'>You hear metal clanking.</span>")
		add_fingerprint(user)
	return M

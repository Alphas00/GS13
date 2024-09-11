/obj/item/dumbbell
	desc = "A weighty dumbbell, perfect for arm exercise!"
	name = "dumbbell"
	icon = 'GainStation13/icons/obj/dumbbell.dmi'
	icon_state = "pen"
	item_state = "pen"
	throwforce = 20
	w_class = WEIGHT_CLASS_BULKY
	throw_speed = 2
	throw_range = 3
	materials = list(MAT_METAL=10)
	pressure_resistance = 2
	var/reps = 0
	var/using = FALSE

/obj/item/dumbbell/dropped(mob/user, silent)
	reps = 0
	. = ..()
	
/obj/item/dumbbell/attack_self(mob/user)
	. = ..()
	if(!using)
		using = TRUE
		to_chat(user, "<span>You do a rep with the [src]. YEEEEEAH!!!</span>")
		if(do_after(usr, CLICK_CD_RESIST-reps, 0, usr, 1))
			if(iscarbon(user))
				var/mob/living/carbon/U = user
				U.adjust_fatness(-10, FATTENING_TYPE_WEIGHT_LOSS)
			if(reps < 16)
				reps += 0.4
		else
			to_chat(user, "<span>You couldn't complete the rep. YOU'LL GET IT NEXT TIME CHAMP!!!</span>")
		using = FALSE

/obj/machinery/conveyor/treadmill
	name = "treadmill"
	desc = "A treadmil, for losing weight!"

/obj/machinery/conveyor/treadmill/convey(list/affecting)
	for(var/am in affecting)
		if(!ismovable(am))	//This is like a third faster than for(var/atom/movable in affecting)
			continue
		var/atom/movable/movable_thing = am
		//Give this a chance to yield if the server is busy
		stoplag()
		if(QDELETED(movable_thing) || (movable_thing.loc != loc))
			continue
		if(iseffect(movable_thing) || isdead(movable_thing))
			continue
		if(isliving(movable_thing))
			var/mob/living/zoommob = movable_thing
			if((zoommob.movement_type & FLYING) && !zoommob.stat)
				continue
		if(!movable_thing.anchored && movable_thing.has_gravity())
			step(movable_thing, movedir)
			if(iscarbon(A))
				var/mob/living/carbon/C = A
				C.adjust_fatness(-10, FATTENING_TYPE_WEIGHT_LOSS)
	conveying = FALSE

/obj/machinery/conveyor/treadmill/attackby(obj/item/I, mob/user, params)
	if(I.tool_behavior == TOOL_CROWBAR)
		user.visible_message("<span class='notice'>[user] struggles to pry up \the [src] with \the [I].</span>", \
		"<span class='notice'>You struggle to pry up \the [src] with \the [I].</span>")
		if(I.use_tool(src, user, 40, volume=40))
			if(!(stat & BROKEN))
				var/obj/item/conveyor_construct/treadmill/C = new/obj/item/conveyor_construct/treadmill(src.loc)
				C.id = id
				transfer_fingerprints_to(C)
			to_chat(user, "<span class='notice'>You remove the conveyor belt.</span>")
			qdel(src)

	else if(I.tool_behaviour == TOOL_WRENCH)
		if(!(stat & BROKEN))
			I.play_tool_sound(src)
			setDir(turn(dir,-45))
			update_move_direction()
			to_chat(user, "<span class='notice'>You rotate [src].</span>")

	else if(I.tool_behavior == TOOL_SCREWDRIVER)
		if(!(stat & BROKEN))
			verted = verted * -1
			update_move_direction()
			to_chat(user, "<span class='notice'>You reverse [src]'s direction.</span>")

	else if(user.a_intent != INTENT_HARM)
		user.transferItemToLoc(I, drop_location())
	else
		return ..()

/obj/item/conveyor_construct/treadmill
	icon = 'icons/obj/recycling.dmi'
	icon_state = "conveyor_construct"
	name = "treadmill assembly"
	desc = "A treadmill assembly."
	w_class = WEIGHT_CLASS_BULKY
	id = "" //inherited by the belt

/obj/item/conveyor_construct/treadmill/afterattack(atom/A, mob/user, proximity, click_parameters)
	SEND_SIGNAL(src, COMSIG_ITEM_AFTERATTACK, A, user, proximity, click_parameters)
	SEND_SIGNAL(user, COMSIG_MOB_ITEM_AFTERATTACK, A, user, proximity, click_parameters)
	if(!proximity || user.stat || !isfloorturf(A) || istype(A, /area/shuttle))
		return
	var/cdir = get_dir(A, user)
	if(A == user.loc)
		to_chat(user, "<span class='notice'>You cannot place a conveyor belt under yourself.</span>")
		return
	var/obj/machinery/conveyor/treadmill/C = new/obj/machinery/conveyor/treadmill(A, cdir, id)
	transfer_fingerprints_to(C)
	qdel(src)

/datum/design/dumbbell
	name = "Dumbbell"
	id = "dumbbell"
	build_type = AUTOLATHE
	materials = list(MAT_METAL = 2000)
	build_path = /obj/item/dumbbell
	category = list("initial", "Tools")

/datum/design/treadmill
	name = "Treadmill"
	id = "treadmill"
	build_type = AUTOLATHE
	materials = list(MAT_METAL = 5000)
	build_path = /obj/item/conveyor_construct/treadmill
	category = list("initial", "Construction")

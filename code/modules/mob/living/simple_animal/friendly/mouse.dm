/mob/living/simple_animal/mouse
	name = "mouse"
	desc = "It's a nasty, ugly, evil, disease-ridden rodent."
	icon_state = "mouse_gray"
	icon_living = "mouse_gray"
	icon_dead = "mouse_gray_dead"
	speak = list("Squeak!","SQUEAK!","Squeak?")
	speak_emote = list("squeaks")
	emote_hear = list("squeaks.")
	emote_see = list("runs in a circle.", "shakes.")
	speak_chance = 1
	turns_per_move = 5
	blood_volume = 250
	see_in_dark = 6
	maxHealth = 5
	health = 5
	butcher_results = list(/obj/item/reagent_containers/food/snacks/meat/slab = 1)
	response_help  = "pets"
	response_disarm = "gently pushes aside"
	response_harm   = "splats"
	density = FALSE
	ventcrawler = VENTCRAWLER_ALWAYS
	pass_flags = PASSTABLE | PASSGRILLE | PASSMOB
	mob_size = MOB_SIZE_TINY
	mob_biotypes = MOB_ORGANIC|MOB_BEAST
	var/body_color //brown, gray and white, leave blank for random
	gold_core_spawnable = FRIENDLY_SPAWN
	var/chew_probability = 1
	size_multiplier = 0.5
	faction = list("rat")

/mob/living/simple_animal/mouse/Initialize()
	. = ..()
	AddComponent(/datum/component/squeak, list('sound/effects/mousesqueek.ogg'=1), 100)
	if(!body_color)
		body_color = pick(list("brown","gray","white"))
	AddElement(/datum/element/mob_holder, "mouse_[body_color]")
	icon_state = "mouse_[body_color]"
	icon_living = "mouse_[body_color]"
	icon_dead = "mouse_[body_color]_dead"
	if(name == "mouse") // Faster than checking for mobtypes, just checks if this mouse is a generic mouse.
		if(prob(1)) //1% chance to turn a generic mouse into a boommouse
			new /mob/living/simple_animal/mouse/boommouse(src.loc)
			qdel(src)

/mob/living/simple_animal/mouse/proc/splat()
	src.health = 0
	src.icon_dead = "mouse_[body_color]_splat"
	death()

/mob/living/simple_animal/mouse/death(gibbed, toast)
	if(!ckey)
		..(1)
		if(!gibbed)
			var/obj/item/reagent_containers/food/snacks/deadmouse/M = new(loc)
			M.icon_state = icon_dead
			M.name = name
			if(toast)
				M.add_atom_colour("#3A3A3A", FIXED_COLOUR_PRIORITY)
				M.desc = "It's toast."
		qdel(src)
	else
		..(gibbed)


/mob/living/simple_animal/mouse/Crossed(AM as mob|obj)
	if( ishuman(AM) )
		if(!stat)
			var/mob/M = AM
			to_chat(M, "<span class='notice'>[icon2html(src, M)] Squeak!</span>")
	if(istype(AM, /obj/item/reagent_containers/food/snacks/royalcheese))
		evolve()
		qdel(AM)
	..()

/mob/living/simple_animal/mouse/handle_automated_action()
	if(isbelly(loc))
		return

	if(prob(chew_probability))
		var/turf/open/floor/F = get_turf(src)
		if(istype(F) && !F.intact)
			var/obj/structure/cable/C = locate() in F
			if(C && prob(15))
				if(C.avail())
					visible_message("<span class='warning'>[src] chews through the [C]. It's toast!</span>")
					playsound(src, 'sound/effects/sparks2.ogg', 100, 1)
					C.deconstruct()
					death(toast=1)
				else
					C.deconstruct()
					visible_message("<span class='warning'>[src] chews through the [C].</span>")

	for(var/obj/item/reagent_containers/food/snacks/cheesewedge/cheese in range(1, src))
		if(prob(10))
			be_fruitful()
			qdel(cheese)
			return
	for(var/obj/item/reagent_containers/food/snacks/royalcheese/bigcheese in range(1, src))
		qdel(bigcheese)
		evolve()
		return

/**
  *Checks the mouse cap, if it's above the cap, doesn't spawn a mouse. If below, spawns a mouse and adds it to cheeserats.
  */

/mob/living/simple_animal/mouse/proc/be_fruitful()
	var/cap = CONFIG_GET(number/ratcap)
	if(LAZYLEN(SSmobs.cheeserats) >= cap)
		visible_message("<span class='warning'>[src] carefully eats the cheese, hiding it from the [cap] mice on the station!</span>")
		return
	var/mob/living/newmouse = new /mob/living/simple_animal/mouse(loc)
	SSmobs.cheeserats += newmouse
	visible_message("<span class='notice'>[src] nibbles through the cheese, attracting another mouse!</span>")

/**
  *Spawns a new regal rat, says some good jazz, and if sentient, transfers the relivant mind.
  */
/mob/living/simple_animal/mouse/proc/evolve()
	var/mob/living/simple_animal/hostile/regalrat = new /mob/living/simple_animal/hostile/regalrat(loc)
	visible_message("<span class='warning'>[src] devours the cheese! He morphs into something... greater!</span>")
	regalrat.say("RISE, MY SUBJECTS! SCREEEEEEE!")
	if(mind)
		mind.transfer_to(regalrat)
	qdel(src)

/*
 * Mouse types
 */

/mob/living/simple_animal/mouse/white
	body_color = "white"
	icon_state = "mouse_white"

/mob/living/simple_animal/mouse/gray
	body_color = "gray"
	icon_state = "mouse_gray"

/mob/living/simple_animal/mouse/brown
	body_color = "brown"
	icon_state = "mouse_brown"

/mob/living/simple_animal/mouse/Destroy()
	SSmobs.cheeserats -= src
	return ..()

//TOM IS ALIVE! SQUEEEEEEEE~K :)
/mob/living/simple_animal/mouse/brown/Tom
	name = "Tom"
	desc = "Jerry the cat is not amused."
	response_help  = "pets"
	response_disarm = "gently pushes aside"
	response_harm   = "splats"
	gold_core_spawnable = NO_SPAWN

/obj/item/reagent_containers/food/snacks/deadmouse
	name = "dead mouse"
	desc = "It looks like somebody dropped the bass on it. A lizard's favorite meal."
	icon = 'icons/mob/animal.dmi'
	icon_state = "mouse_gray_dead"
	bitesize = 3
	eatverb = "devour"
	list_reagents = list(/datum/reagent/consumable/nutriment = 3, /datum/reagent/consumable/nutriment/vitamin = 2)
	foodtype = GROSS | MEAT | RAW
	grind_results = list(/datum/reagent/blood = 20, /datum/reagent/liquidgibs = 5)

/obj/item/reagent_containers/food/snacks/deadmouse/on_grind()
	reagents.clear_reagents()

/mob/living/simple_animal/mouse/boommouse
	name = "boommouse" //obviously inspired on rimworld
	desc = "A mutated rat with a pack of... Plasma on its back? I wouldn't really touch it if I were you."
	icon = 'hyperstation/icons/mob/animal.dmi'
	icon_state = "mouse_plasma"
	icon_living = "mouse_plasma"
	icon_dead = "mouse_plasma"
	see_in_dark = 12
	maxHealth = 7
	health = 7
	chew_probability = 0

/mob/living/simple_animal/mouse/boommouse/Initialize()
	. = ..()
	//Force icons because mouse/initialize randomizes them
	icon = 'hyperstation/icons/mob/animal.dmi'
	icon_state = "mouse_plasma"
	icon_living = "mouse_plasma"
	icon_dead = "mouse_plasma" //No need for a dead sprite since it qdels itself on death

/mob/living/simple_animal/mouse/boommouse/death(gibbed, toast)
	var/turf/T = get_turf(src)
	message_admins("A boommouse explosion was triggered at [ADMIN_VERBOSEJMP(T)].")
	visible_message("<span class='danger'>The boommouse violently explodes!</span>")
	atmos_spawn_air("plasma=15;TEMP=750")
	explosion(src.loc, 0, 0, 2, 0, 1, 0, 2, 0, 0)
	qdel(src)

/mob/living/simple_animal/mouse/boommouse/attackby(obj/item/I, mob/living/user, params)
	var/turf/T = get_turf(src)
	message_admins("[ADMIN_LOOKUPFLW(user)] is attacking a boommouse at [ADMIN_VERBOSEJMP(T)].")
	if(I.tool_behaviour == TOOL_WELDER)
		var/obj/item/weldingtool/W = I
		if(W.welding)
			user.visible_message("<span class='warning'>[user] burns the boommouse with [user.p_their()] [W.name]!</span>", "<span class='userdanger'>That was stupid of you.</span>")
			var/message_admins = "[ADMIN_LOOKUPFLW(user)] triggered a boommouse explosion at [ADMIN_VERBOSEJMP(T)]."
			GLOB.bombers += message_admins
			message_admins(message_admins)
			user.log_message("triggered a boommouse explosion.", LOG_ATTACK)
			death()
	return ..()

	//TODO - look into attacked_by to make this better and less shitcode

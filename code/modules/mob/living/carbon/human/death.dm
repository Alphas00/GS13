/mob/living/carbon/human/gib_animation()
	new /obj/effect/temp_visual/gib_animation(loc, "gibbed-h")

/mob/living/carbon/human/dust_animation()
	new /obj/effect/temp_visual/dust_animation(loc, "dust-h")

/mob/living/carbon/human/spawn_gibs(with_bodyparts, atom/loc_override)
	var/location = loc_override ? loc_override.drop_location() : drop_location()
	if(dna?.species?.gib_types)
		var/blood_dna = get_blood_dna_list()
		var/datum/species/S = dna.species
		var/length = length(S.gib_types)
		if(length)
			var/path = (with_bodyparts && length > 1) ? S.gib_types[2] : S.gib_types[1]
			new path(location, src, get_static_viruses())
		else
			new S.gib_types(location, src, get_static_viruses(), blood_dna)
	else
		if(with_bodyparts)
			new /obj/effect/gibspawner/human(location, src, get_static_viruses())
		else
			new /obj/effect/gibspawner/human/bodypartless(location, src, get_static_viruses())

/mob/living/carbon/human/spawn_dust(just_ash = FALSE)
	if(just_ash)
		new /obj/effect/decal/cleanable/ash(loc)
	else
		new /obj/effect/decal/remains/human(loc)

/mob/living/carbon/human/death(gibbed)
	if(stat == DEAD)
		return
	stop_sound_channel(CHANNEL_HEARTBEAT)
	var/obj/item/organ/heart/H = getorganslot(ORGAN_SLOT_HEART)
	if(H)
		H.beat = BEAT_NONE

	. = ..()

	dizziness = 0
	jitteriness = 0

	if(ismecha(loc))
		var/obj/mecha/M = loc
		if(M.occupant == src)
			M.go_out()

	dna.species.spec_death(gibbed, src)

	if(SSticker.HasRoundStarted())
		SSblackbox.ReportDeath(src)
	if(is_devil(src))
		INVOKE_ASYNC(is_devil(src), TYPE_PROC_REF(/datum/antagonist/devil, beginResurrectionCheck), src)

	//watching someone die is traumatic
	for(var/mob/living/carbon/human/C in oview(5, src))
		if(C.mind) //We don't need to give this to anything that doesn't have a mind. That's wasted processing.
			if(!HAS_TRAIT(C, TRAIT_APATHETIC) || !C.mind.assigned_role == "Medical Doctor") //Shamelessly stolen from the Doctor's Delight
				SEND_SIGNAL(C, COMSIG_ADD_MOOD_EVENT, "death", /datum/mood_event/deathsaw)
				if(prob(10)) //10% chance to pump adrenaline into their body
					C.jitteriness += 5

/mob/living/carbon/human/proc/makeSkeleton()
	ADD_TRAIT(src, TRAIT_DISFIGURED, TRAIT_GENERIC)
	set_species(/datum/species/skeleton)
	return 1


/mob/living/carbon/proc/Drain()
	become_husk(CHANGELING_DRAIN)
	ADD_TRAIT(src, TRAIT_NOCLONE, CHANGELING_DRAIN)
	blood_volume = 0
	return 1

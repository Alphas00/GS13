/proc/playsound(atom/source, soundin, vol as num, vary, extrarange as num, falloff, frequency = null, channel = 0, pressure_affected = TRUE, ignore_walls = TRUE, soundenvwet = -10000, soundenvdry = 0)
	if(isarea(source))
		throw EXCEPTION("playsound(): source is an area")
		return

	var/turf/turf_source = get_turf(source)

	if (!turf_source)
		return

	//allocate a channel if necessary now so its the same for everyone
	channel = channel || open_sound_channel()

 	// Looping through the player list has the added bonus of working for mobs inside containers
	var/sound/S = sound(get_sfx(soundin))
	var/maxdistance = (world.view + extrarange)
	var/z = turf_source.z
	var/list/listeners = SSmobs.clients_by_zlevel[z]
	if(!ignore_walls) //these sounds don't carry through walls
		listeners = listeners & hearers(maxdistance,turf_source)
	for(var/P in listeners)
		var/mob/M = P
		if(get_dist(M, turf_source) <= maxdistance)
			M.playsound_local(turf_source, soundin, vol, vary, frequency, falloff, channel, pressure_affected, S, soundenvwet, soundenvdry)
	for(var/P in SSmobs.dead_players_by_zlevel[z])
		var/mob/M = P
		if(get_dist(M, turf_source) <= maxdistance)
			M.playsound_local(turf_source, soundin, vol, vary, frequency, falloff, channel, pressure_affected, S, soundenvwet, soundenvdry)

/mob/proc/playsound_local(turf/turf_source, soundin, vol as num, vary, frequency, falloff, channel = 0, pressure_affected = TRUE, sound/S, envwet = -10000, envdry = 0, manual_x, manual_y)
	if(audiovisual_redirect)
		var/turf/T = get_turf(src)
		audiovisual_redirect.playsound_local(turf_source, soundin, vol, vary, frequency, falloff, channel, pressure_affected, S, 0, -1000, turf_source.x - T.x, turf_source.y - T.y)
	if(!client || !can_hear())
		return

	if(!S)
		S = sound(get_sfx(soundin))

	S.wait = 0 //No queue
	S.channel = channel || open_sound_channel()
	S.volume = vol
	S.environment = 7

	if(vary)
		if(frequency)
			S.frequency = frequency
		else
			S.frequency = get_rand_frequency()

	if(isturf(turf_source))
		var/turf/T = get_turf(src)

		//sound volume falloff with distance
		var/distance = 0
		if(!manual_x && !manual_y)
			distance = get_dist(T, turf_source)

		S.volume -= max(distance - world.view, 0) * 2 //multiplicative falloff to add on top of natural audio falloff.

		if(pressure_affected)
			//Atmosphere affects sound
			var/pressure_factor = 1
			var/datum/gas_mixture/hearer_env = T.return_air()
			var/datum/gas_mixture/source_env = turf_source.return_air()

			if(hearer_env && source_env)
				var/pressure = min(hearer_env.return_pressure(), source_env.return_pressure())
				if(pressure < ONE_ATMOSPHERE)
					pressure_factor = max((pressure - SOUND_MINIMUM_PRESSURE)/(ONE_ATMOSPHERE - SOUND_MINIMUM_PRESSURE), 0)
			else //space
				pressure_factor = 0

			S.echo = list(envdry, null, envwet, null, null, null, null, null, null, null, null, null, null, 1, 1, 1, null, null)

			if(distance <= 1)
				pressure_factor = max(pressure_factor, 0.15) //touching the source of the sound

			S.volume *= pressure_factor
			//End Atmosphere affecting sound

		if(S.volume <= 0)
			return //No sound

		var/dx = 0 // Hearing from the right/left
		if(!manual_x)
			dx = turf_source.x - T.x
		else
			dx = manual_x
		S.x = dx
		var/dz = 0 // Hearing from infront/behind
		if(!manual_x)
			dz = turf_source.y - T.y
		else
			dz = manual_y
		S.z = dz
		// The y value is for above your head, but there is no ceiling in 2d spessmens.
		S.y = 1
		S.falloff = (falloff ? falloff : FALLOFF_SOUNDS)

	SEND_SOUND(src, S)

/proc/sound_to_playing_players(soundin, volume = 100, vary = FALSE, frequency = 0, falloff = FALSE, channel = 0, pressure_affected = FALSE, sound/S)
	if(!S)
		S = sound(get_sfx(soundin))
	for(var/m in GLOB.player_list)
		if(ismob(m) && !isnewplayer(m))
			var/mob/M = m
			M.playsound_local(M, null, volume, vary, frequency, falloff, channel, pressure_affected, S)

/proc/open_sound_channel()
	var/static/next_channel = 1	//loop through the available 1024 - (the ones we reserve) channels and pray that its not still being used
	. = ++next_channel
	if(next_channel > CHANNEL_HIGHEST_AVAILABLE)
		next_channel = 1

/mob/proc/stop_sound_channel(chan)
	SEND_SOUND(src, sound(null, repeat = 0, wait = 0, channel = chan))

/client/proc/playtitlemusic(vol = 85)
	set waitfor = FALSE
	UNTIL(SSticker.login_music) //wait for SSticker init to set the login music

	if(prefs && (prefs.toggles & SOUND_LOBBY))
		SEND_SOUND(src, sound(SSticker.login_music, repeat = 0, wait = 0, volume = vol, channel = CHANNEL_LOBBYMUSIC)) // MAD JAMS

/proc/get_rand_frequency()
	return rand(32000, 55000) //Frequency stuff only works with 45kbps oggs.

/proc/get_sfx(soundin)
	if(istext(soundin))
		switch(soundin)
			if ("shatter")
				soundin = pick('sound/effects/glassbr1.ogg','sound/effects/glassbr2.ogg','sound/effects/glassbr3.ogg')
			if ("explosion")
				soundin = pick('sound/effects/explosion1.ogg','sound/effects/explosion2.ogg')
			if ("sparks")
				soundin = pick('sound/effects/sparks1.ogg','sound/effects/sparks2.ogg','sound/effects/sparks3.ogg','sound/effects/sparks4.ogg')
			if ("rustle")
				soundin = pick('sound/effects/rustle1.ogg','sound/effects/rustle2.ogg','sound/effects/rustle3.ogg','sound/effects/rustle4.ogg','sound/effects/rustle5.ogg')
			if ("bodyfall")
				soundin = pick('sound/effects/bodyfall1.ogg','sound/effects/bodyfall2.ogg','sound/effects/bodyfall3.ogg','sound/effects/bodyfall4.ogg')
			if ("punch")
				soundin = pick('sound/weapons/punch1.ogg','sound/weapons/punch2.ogg','sound/weapons/punch3.ogg','sound/weapons/punch4.ogg')
			if ("clownstep")
				soundin = pick('sound/effects/clownstep1.ogg','sound/effects/clownstep2.ogg')
			if ("suitstep")
				soundin = pick('sound/effects/suitstep1.ogg','sound/effects/suitstep2.ogg')
			if ("swing_hit")
				soundin = pick('sound/weapons/genhit1.ogg', 'sound/weapons/genhit2.ogg', 'sound/weapons/genhit3.ogg')
			if ("hiss")
				soundin = pick('sound/voice/hiss1.ogg','sound/voice/hiss2.ogg','sound/voice/hiss3.ogg','sound/voice/hiss4.ogg')
			if ("pageturn")
				soundin = pick('sound/effects/pageturn1.ogg', 'sound/effects/pageturn2.ogg','sound/effects/pageturn3.ogg')
			if ("gunshot")
				soundin = pick('sound/weapons/gunshot.ogg', 'sound/weapons/gunshot2.ogg','sound/weapons/gunshot3.ogg','sound/weapons/gunshot4.ogg')
			if ("ricochet")
				soundin = pick(	'sound/weapons/effects/ric1.ogg', 'sound/weapons/effects/ric2.ogg','sound/weapons/effects/ric3.ogg','sound/weapons/effects/ric4.ogg','sound/weapons/effects/ric5.ogg')
			if ("terminal_type")
				soundin = pick('sound/machines/terminal_button01.ogg', 'sound/machines/terminal_button02.ogg', 'sound/machines/terminal_button03.ogg', \
								'sound/machines/terminal_button04.ogg', 'sound/machines/terminal_button05.ogg', 'sound/machines/terminal_button06.ogg', \
								'sound/machines/terminal_button07.ogg', 'sound/machines/terminal_button08.ogg')
			if ("desceration")
				soundin = pick('sound/misc/desceration-01.ogg', 'sound/misc/desceration-02.ogg', 'sound/misc/desceration-03.ogg')
			if ("im_here")
				soundin = pick('sound/hallucinations/im_here1.ogg', 'sound/hallucinations/im_here2.ogg')
			if ("can_open")
				soundin = pick('sound/effects/can_open1.ogg', 'sound/effects/can_open2.ogg', 'sound/effects/can_open3.ogg')
			if("bullet_miss")
				soundin = pick('sound/weapons/bulletflyby.ogg', 'sound/weapons/bulletflyby2.ogg', 'sound/weapons/bulletflyby3.ogg')
			if("gun_dry_fire")
				soundin = pick('sound/weapons/gun_dry_fire_1.ogg', 'sound/weapons/gun_dry_fire_2.ogg', 'sound/weapons/gun_dry_fire_3.ogg', 'sound/weapons/gun_dry_fire_4.ogg')
			if("gun_insert_empty_magazine")
				soundin = pick('sound/weapons/gun_magazine_insert_empty_1.ogg', 'sound/weapons/gun_magazine_insert_empty_2.ogg', 'sound/weapons/gun_magazine_insert_empty_3.ogg', 'sound/weapons/gun_magazine_insert_empty_4.ogg')
			if("gun_insert_full_magazine")
				soundin = pick('sound/weapons/gun_magazine_insert_full_1.ogg', 'sound/weapons/gun_magazine_insert_full_2.ogg', 'sound/weapons/gun_magazine_insert_full_3.ogg', 'sound/weapons/gun_magazine_insert_full_4.ogg', 'sound/weapons/gun_magazine_insert_full_5.ogg')
			if("gun_remove_empty_magazine")
				soundin = pick('sound/weapons/gun_magazine_remove_empty_1.ogg', 'sound/weapons/gun_magazine_remove_empty_2.ogg', 'sound/weapons/gun_magazine_remove_empty_3.ogg', 'sound/weapons/gun_magazine_remove_empty_4.ogg')
			if("gun_slide_lock")
				soundin = pick('sound/weapons/gun_slide_lock_1.ogg', 'sound/weapons/gun_slide_lock_2.ogg', 'sound/weapons/gun_slide_lock_3.ogg', 'sound/weapons/gun_slide_lock_4.ogg', 'sound/weapons/gun_slide_lock_5.ogg')
			if("law")
				soundin = pick('sound/voice/beepsky/god.ogg', 'sound/voice/beepsky/iamthelaw.ogg', 'sound/voice/beepsky/secureday.ogg', 'sound/voice/beepsky/radio.ogg', 'sound/voice/beepsky/insult.ogg', 'sound/voice/beepsky/creep.ogg')
			if("honkbot_e")
				soundin = pick('sound/items/bikehorn.ogg', 'sound/items/AirHorn2.ogg', 'sound/misc/sadtrombone.ogg', 'sound/items/AirHorn.ogg', 'sound/effects/reee.ogg',  'sound/items/WEEOO1.ogg', 'sound/voice/beepsky/iamthelaw.ogg', 'sound/voice/beepsky/creep.ogg','sound/magic/Fireball.ogg' ,'sound/effects/pray.ogg', 'sound/voice/hiss1.ogg','sound/machines/buzz-sigh.ogg', 'sound/machines/ping.ogg', 'sound/weapons/flashbang.ogg', 'sound/weapons/bladeslice.ogg')
			if("goose")
				soundin = pick('sound/creatures/goose1.ogg', 'sound/creatures/goose2.ogg', 'sound/creatures/goose3.ogg', 'sound/creatures/goose4.ogg')
			if("water_wade")
				soundin = pick('sound/effects/water_wade1.ogg', 'sound/effects/water_wade2.ogg', 'sound/effects/water_wade3.ogg', 'sound/effects/water_wade4.ogg')
			//START OF CIT CHANGES - adds random vore sounds
			if ("struggle_sound")
				soundin = pick( 'sound/vore/pred/struggle_01.ogg','sound/vore/pred/struggle_02.ogg','sound/vore/pred/struggle_03.ogg',
								'sound/vore/pred/struggle_04.ogg','sound/vore/pred/struggle_05.ogg')
			if ("prey_struggle")
				soundin = pick( 'sound/vore/prey/struggle_01.ogg','sound/vore/prey/struggle_02.ogg','sound/vore/prey/struggle_03.ogg',
								'sound/vore/prey/struggle_04.ogg','sound/vore/prey/struggle_05.ogg')
			if ("digest_pred")
				soundin = pick( 'sound/vore/pred/digest_01.ogg','sound/vore/pred/digest_02.ogg','sound/vore/pred/digest_03.ogg',
								'sound/vore/pred/digest_04.ogg','sound/vore/pred/digest_05.ogg','sound/vore/pred/digest_06.ogg',
								'sound/vore/pred/digest_07.ogg','sound/vore/pred/digest_08.ogg','sound/vore/pred/digest_09.ogg',
								'sound/vore/pred/digest_10.ogg','sound/vore/pred/digest_11.ogg','sound/vore/pred/digest_12.ogg',
								'sound/vore/pred/digest_13.ogg','sound/vore/pred/digest_14.ogg','sound/vore/pred/digest_15.ogg',
								'sound/vore/pred/digest_16.ogg','sound/vore/pred/digest_17.ogg','sound/vore/pred/digest_18.ogg')
			if ("death_pred")
				soundin = pick( 'sound/vore/pred/death_01.ogg','sound/vore/pred/death_02.ogg','sound/vore/pred/death_03.ogg',
								'sound/vore/pred/death_04.ogg','sound/vore/pred/death_05.ogg','sound/vore/pred/death_06.ogg',
								'sound/vore/pred/death_07.ogg','sound/vore/pred/death_08.ogg','sound/vore/pred/death_09.ogg',
								'sound/vore/pred/death_10.ogg')
			if ("digest_prey")
				soundin = pick( 'sound/vore/prey/digest_01.ogg','sound/vore/prey/digest_02.ogg','sound/vore/prey/digest_03.ogg',
								'sound/vore/prey/digest_04.ogg','sound/vore/prey/digest_05.ogg','sound/vore/prey/digest_06.ogg',
								'sound/vore/prey/digest_07.ogg','sound/vore/prey/digest_08.ogg','sound/vore/prey/digest_09.ogg',
								'sound/vore/prey/digest_10.ogg','sound/vore/prey/digest_11.ogg','sound/vore/prey/digest_12.ogg',
								'sound/vore/prey/digest_13.ogg','sound/vore/prey/digest_14.ogg','sound/vore/prey/digest_15.ogg',
								'sound/vore/prey/digest_16.ogg','sound/vore/prey/digest_17.ogg','sound/vore/prey/digest_18.ogg')
			if ("death_prey")
				soundin = pick( 'sound/vore/prey/death_01.ogg','sound/vore/prey/death_02.ogg','sound/vore/prey/death_03.ogg',
								'sound/vore/prey/death_04.ogg','sound/vore/prey/death_05.ogg','sound/vore/prey/death_06.ogg',
								'sound/vore/prey/death_07.ogg','sound/vore/prey/death_08.ogg','sound/vore/prey/death_09.ogg',
								'sound/vore/prey/death_10.ogg')
			if("hunger_sounds")
				soundin = pick(	'sound/vore/growl1.ogg','sound/vore/growl2.ogg','sound/vore/growl3.ogg','sound/vore/growl4.ogg',
								'sound/vore/growl5.ogg')
			if("clang")
				soundin = pick('sound/effects/clang1.ogg', 'sound/effects/clang2.ogg')
			if("clangsmall")
				soundin = pick('sound/effects/clangsmall1.ogg', 'sound/effects/clangsmall2.ogg')
			if("slosh")
				soundin = pick('sound/effects/slosh1.ogg', 'sound/effects/slosh2.ogg')
			//END OF CIT CHANGES
			// GS13 Start - Gainstation sounds
			if("belch")
				soundin = pick(	'GainStation13/sound/voice/belch1.ogg', 'GainStation13/sound/voice/belch2.ogg',
								'GainStation13/sound/voice/belch3.ogg', 'GainStation13/sound/voice/belch4.ogg',
								'GainStation13/sound/voice/belch5.ogg', 'GainStation13/sound/voice/belch6.ogg',
								'GainStation13/sound/voice/belch7.ogg', 'GainStation13/sound/voice/belch8.ogg',
								'GainStation13/sound/voice/belch9.ogg', 'GainStation13/sound/voice/belch10.ogg',
								'GainStation13/sound/voice/belch11.ogg')
			if("brap")
				soundin = pick(	'GainStation13/sound/voice/brap1.ogg', 'GainStation13/sound/voice/brap2.ogg',
								'GainStation13/sound/voice/brap3.ogg', 'GainStation13/sound/voice/brap4.ogg',
								'GainStation13/sound/voice/brap5.ogg', 'GainStation13/sound/voice/brap6.ogg',
								'GainStation13/sound/voice/brap7.ogg', 'GainStation13/sound/voice/brap8.ogg')
			if("burp")
				soundin = pick(	'GainStation13/sound/voice/burp1.ogg')
			if("burunyu")
				soundin = pick(	'GainStation13/sound/voice/funnycat.ogg')
			if("fart")
				soundin = pick(	'GainStation13/sound/voice/fart1.ogg', 'GainStation13/sound/voice/fart2.ogg',
								'GainStation13/sound/voice/fart3.ogg', 'GainStation13/sound/voice/fart4.ogg')
			if("gurgle")
				soundin = pick(	'GainStation13/sound/voice/gurgle1.ogg', 'GainStation13/sound/voice/gurgle2.ogg',
								'GainStation13/sound/voice/gurgle3.ogg')
			// GS13 end
	return soundin

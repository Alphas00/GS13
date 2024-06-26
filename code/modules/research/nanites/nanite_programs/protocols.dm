//Replication Protocols
/datum/nanite_program/protocol/kickstart
	name = "Kickstart Protocol"
	desc = "Replication Protocol: the nanites focus on early growth, heavily boosting replication rate for a few minutes after the initial implantation."
	use_rate = 0
	rogue_types = list(/datum/nanite_program/necrotic)
	protocol_class = NANITE_PROTOCOL_REPLICATION
	var/boost_duration = 1200

/datum/nanite_program/protocol/kickstart/check_conditions()
	if(!(world.time < nanites.start_time + boost_duration))
		return FALSE
	return ..()

/datum/nanite_program/protocol/kickstart/active_effect()
	nanites.adjust_nanites(null, 3.5)

/datum/nanite_program/protocol/factory
	name = "Factory Protocol"
	desc = "Replication Protocol: the nanites build a factory matrix within the host, gradually increasing replication speed over time. \
	The factory decays if the protocol is not active, or if the nanites are disrupted by shocks or EMPs."
	use_rate = 0
	rogue_types = list(/datum/nanite_program/necrotic)
	protocol_class = NANITE_PROTOCOL_REPLICATION
	var/factory_efficiency = 0
	var/max_efficiency = 1000 //Goes up to 2 bonus regen per tick after 16 minutes and 40 seconds

/datum/nanite_program/protocol/factory/on_process()
	if(!activated || !check_conditions())
		factory_efficiency = max(0, factory_efficiency - 5)
	..()

/datum/nanite_program/protocol/factory/on_emp(severity)
	..()
	factory_efficiency = max(0, factory_efficiency - 300)

/datum/nanite_program/protocol/factory/on_shock(shock_damage)
	..()
	factory_efficiency = max(0, factory_efficiency - 200)

/datum/nanite_program/protocol/factory/on_minor_shock()
	..()
	factory_efficiency = max(0, factory_efficiency - 100)

/datum/nanite_program/protocol/factory/active_effect()
	factory_efficiency = min(factory_efficiency + 1, max_efficiency)
	nanites.adjust_nanites(null, round(0.002 * factory_efficiency, 0.1))

/datum/nanite_program/protocol/tinker
	name = "Tinker Protocol"
	desc = "Replication Protocol: the nanites learn to use metallic material in the host's bloodstream to speed up the replication process."
	use_rate = 0
	rogue_types = list(/datum/nanite_program/necrotic)
	protocol_class = NANITE_PROTOCOL_REPLICATION
	var/boost = 2
	var/list/valid_reagents = list(
		/datum/reagent/iron,
		/datum/reagent/copper,
		/datum/reagent/gold,
		/datum/reagent/silver,
		/datum/reagent/mercury,
		/datum/reagent/aluminium,
		/datum/reagent/silicon)

/datum/nanite_program/protocol/tinker/check_conditions()
	if(!nanites.host_mob.reagents)
		return FALSE

	var/found_reagent = FALSE

	var/datum/reagents/R = nanites.host_mob.reagents
	for(var/VR in valid_reagents)
		if(R.has_reagent(VR, 0.5))
			R.remove_reagent(VR, 0.5)
			found_reagent = TRUE
			break
	if(!found_reagent)
		return FALSE
	return ..()

/datum/nanite_program/protocol/tinker/active_effect()
	nanites.adjust_nanites(null, boost)

/datum/nanite_program/protocol/offline
	name = "Offline Production Protocol"
	desc = "Replication Protocol: while the host is asleep or otherwise unconcious, the nanites exploit the reduced interference to replicate more quickly."
	use_rate = 0
	rogue_types = list(/datum/nanite_program/necrotic)
	protocol_class = NANITE_PROTOCOL_REPLICATION
	var/boost = 3

/datum/nanite_program/protocol/offline/check_conditions()
	var/is_offline = FALSE
	if(nanites.host_mob.IsSleeping() || nanites.host_mob.IsUnconscious())
		is_offline = TRUE
	if(nanites.host_mob.stat == DEAD || HAS_TRAIT(nanites.host_mob, TRAIT_DEATHCOMA))
		is_offline = TRUE
	if(nanites.host_mob.InCritical() && !HAS_TRAIT(nanites.host_mob, TRAIT_NOSOFTCRIT))
		is_offline = TRUE
	if(nanites.host_mob.InFullCritical() && !HAS_TRAIT(nanites.host_mob, TRAIT_NOHARDCRIT))
		is_offline = TRUE
	if(!is_offline)
		return FALSE
	return ..()

/datum/nanite_program/protocol/offline/active_effect()
	nanites.adjust_nanites(null, boost)

/datum/nanite_program/protocol/hive
	name = "Hive Protocol"
	desc = "The nanites use a more efficient grid arrangment for volume storage, increasing maximum volume in a host by 250."
	rogue_types = list(/datum/nanite_program/skin_decay)
	protocol_class = NANITE_PROTOCOL_STORAGE

/datum/nanite_program/protocol/hive/enable_passive_effect()
	nanites.set_max_volume(src, nanites.max_nanites + 250)
	..()

/datum/nanite_program/protocol/hive/disable_passive_effect()
	nanites.set_max_volume(src, nanites.max_nanites - 250)
	..()

////////////////////NANITE PROTOCOLS//////////////////////////////////////
//Note about the category name: The UI cuts the last 8 characters from the category name to remove the " Nanites" in the other categories
//Because of this, Protocols was getting cut down to "P", so i had to add some padding
/datum/design/nanites/kickstart
	name = "Kickstart Protocol"
	desc = "Replication Protocol: the nanites focus on early growth, heavily boosting replication rate for a few minutes after the initial implantation."
	id = "kickstart_nanites"
	program_type = /datum/nanite_program/protocol/kickstart
	category = list("Protocols_Nanites")

/datum/design/nanites/factory
	name = "Factory Protocol"
	desc = "Replication Protocol: the nanites build a factory matrix within the host, gradually increasing replication speed over time. The factory decays if the protocol is not active."
	id = "factory_nanites"
	program_type = /datum/nanite_program/protocol/factory
	category = list("Protocols_Nanites")

/datum/design/nanites/tinker
	name = "Tinker Protocol"
	desc = "Replication Protocol: the nanites learn to use metallic material in the host's bloodstream to speed up the replication process."
	id = "tinker_nanites"
	program_type = /datum/nanite_program/protocol/tinker
	category = list("Protocols_Nanites")

/datum/design/nanites/offline
	name = "Offline Production Protocol"
	desc = "Replication Protocol: while the host is asleep or otherwise unconcious, the nanites exploit the reduced interference to replicate more quickly."
	id = "offline_nanites"
	program_type = /datum/nanite_program/protocol/offline
	category = list("Protocols_Nanites")

/datum/design/nanites/hive
	name = "Hive Protocol"
	desc = "Storage Protocol: safely increases the maximum volume of nanites in the host by 250."
	id = "hive_nanites"
	program_type = /datum/nanite_program/protocol/hive
	category = list("Protocols_Nanites")

/datum/techweb_node/nanite_protocol
	id = "nanite_protocol"
	display_name = "Nanite Protocols"
	description = "Advanced nanite protocols that massively increase their efficiency."
	prereq_ids = list("nanite_synaptic", "nanite_harmonic")
	design_ids = list("kickstart_nanites","factory_nanites","tinker_nanites", "offline_nanites", "hive_nanites")
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = 10000)
	export_price = 15000
	boost_item_paths = list(/obj/item/trash/odd_disk)
	hidden = TRUE

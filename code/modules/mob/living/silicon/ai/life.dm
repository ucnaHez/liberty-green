#define POWER_RESTORATION_OFF 0
#define POWER_RESTORATION_START 1
#define POWER_RESTORATION_SEARCH_APC 2
#define POWER_RESTORATION_APC_FOUND 3

/mob/living/silicon/ai/Life()
	if (src.stat == DEAD)
		return
	else //I'm not removing that shitton of tabs, unneeded as they are. -- Urist
		//Being dead doesn't mean your temperature never changes

		update_gravity(mob_has_gravity())

		if(malfhack)
			if(malfhack.aidisabled)
				src.text2tab("<span class='danger'>ERROR: APC access disabled, hack attempt canceled.</span>")
				malfhacking = 0
				malfhack = null

		if(machine)
			machine.check_eye(src)

		// Handle power damage (oxy)
		if(aiRestorePowerRoutine)
			// Lost power
			adjustOxyLoss(1)
		else
			// Gain Power
			if(getOxyLoss())
				adjustOxyLoss(-1)

		if(!lacks_power())
			var/area/home = get_area(src)
			if(home.powered(EQUIP))
				home.use_power(1000, EQUIP)

			if(aiRestorePowerRoutine >= POWER_RESTORATION_SEARCH_APC)
				ai_restore_power()
				return

		else if(!aiRestorePowerRoutine)
			ai_lose_power()

/mob/living/silicon/ai/proc/lacks_power()
	var/turf/T = get_turf(src)
	var/area/A = get_area(src)
	return !T || !A || ((!A.master.power_equip || istype(T, /turf/open/space)) && !is_type_in_list(src.loc, list(/obj/item, /obj/mecha)))

/mob/living/silicon/ai/updatehealth()
	if(status_flags & GODMODE)
		return
	health = maxHealth - getOxyLoss() - getToxLoss() - getBruteLoss()
	if(!fire_res_on_core)
		health -= getFireLoss()
	update_stat()
	diag_hud_set_health()

/mob/living/silicon/ai/update_stat()
	if(status_flags & GODMODE)
		return
	if(stat != DEAD)
		if(health <= config.health_threshold_dead)
			death()
			return
		else if(stat == UNCONSCIOUS)
			stat = CONSCIOUS
			adjust_blindness(-1)
	diag_hud_set_status()

/mob/living/silicon/ai/update_sight()
	see_invisible = initial(see_invisible)
	see_in_dark = initial(see_in_dark)
	sight = initial(sight)
	if(aiRestorePowerRoutine)
		sight = sight&~SEE_TURFS
		sight = sight&~SEE_MOBS
		sight = sight&~SEE_OBJS
		see_in_dark = 0

	if(see_override)
		see_invisible = see_override


/mob/living/silicon/ai/proc/start_RestorePowerRoutine()
	src.text2tab("Backup battery online. Scanners, camera, and radio interface offline. Beginning fault-detection.")
	sleep(50)
	var/turf/T = get_turf(src)
	var/area/AIarea = get_area(src)
	if(AIarea && AIarea.master.power_equip)
		if(!istype(T, /turf/open/space))
			ai_restore_power()
			return
	src.text2tab("Fault confirmed: missing external power. Shutting down main control system to save power.")
	sleep(20)
	src.text2tab("Emergency control system online. Verifying connection to power network.")
	sleep(50)
	T = get_turf(src)
	if (istype(T, /turf/open/space))
		src.text2tab("Unable to verify! No power connection detected!")
		aiRestorePowerRoutine = POWER_RESTORATION_SEARCH_APC
		return
	src.text2tab("Connection verified. Searching for APC in power network.")
	sleep(50)
	var/obj/machinery/power/apc/theAPC = null

	var/PRP //like ERP with the code, at least this stuff is no more 4x sametext
	for (PRP=1, PRP<=4, PRP++)
		T = get_turf(src)
		AIarea = get_area(src)
		if(AIarea)
			for(var/area/A in AIarea.master.related)
				for (var/obj/machinery/power/apc/APC in A)
					if (!(APC.stat & BROKEN))
						theAPC = APC
						break
		if (!theAPC)
			switch(PRP)
				if(1)
					src.text2tab("Unable to locate APC!")
				else
					src.text2tab("Lost connection with the APC!")
			aiRestorePowerRoutine = POWER_RESTORATION_SEARCH_APC
			return
		if(AIarea.master.power_equip)
			if (!istype(T, /turf/open/space))
				ai_restore_power()
				return
		switch(PRP)
			if (1) src.text2tab("APC located. Optimizing route to APC to avoid needless power waste.")
			if (2) src.text2tab("Best route identified. Hacking offline APC power port.")
			if (3) src.text2tab("Power port upload access confirmed. Loading control program into APC power port software.")
			if (4)
				src.text2tab("Transfer complete. Forcing APC to execute program.")
				sleep(50)
				src.text2tab("Receiving control information from APC.")
				sleep(2)
				apc_override = 1
				theAPC.ui_interact(src, state = conscious_state)
				apc_override = 0
				aiRestorePowerRoutine = POWER_RESTORATION_APC_FOUND
				src.text2tab("Here are your current laws:")
				show_laws()
		sleep(50)
		theAPC = null

/mob/living/silicon/ai/proc/ai_restore_power()
	if(aiRestorePowerRoutine)
		if(aiRestorePowerRoutine == POWER_RESTORATION_APC_FOUND)
			src.text2tab("Alert cancelled. Power has been restored.")
		else
			src.text2tab("Alert cancelled. Power has been restored without our assistance.")
		aiRestorePowerRoutine = POWER_RESTORATION_OFF
		set_blindness(0)
		update_sight()

/mob/living/silicon/ai/proc/ai_lose_power()
	aiRestorePowerRoutine = POWER_RESTORATION_START
	blind_eyes(1)
	update_sight()
	src.text2tab("You've lost power!")
	spawn(20)
		start_RestorePowerRoutine()

#undef POWER_RESTORATION_OFF
#undef POWER_RESTORATION_START
#undef POWER_RESTORATION_SEARCH_APC
#undef POWER_RESTORATION_APC_FOUND
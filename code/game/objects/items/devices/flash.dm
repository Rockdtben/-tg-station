/obj/item/device/flash
	name = "flash"
	desc = "A powerful and versatile flashbulb device, with applications ranging from disorienting attackers to acting as visual receptors in robot production."
	icon_state = "flash"
	item_state = "flashbang"	//looks exactly like a flash (and nothing like a flashbang)
	throwforce = 0
	w_class = 1.0
	throw_speed = 3
	throw_range = 7
	flags = CONDUCT
	origin_tech = "magnets=2;combat=1"

	var/times_used = 0 //Number of times it's been used.
	var/broken = 0     //Is the flash burnt out?
	var/last_used = 0 //last world.time it was used.
	var/burnt = "flashburnt"
	var/flashanim = "flash2"

/obj/item/device/flash/proc/clown_check(mob/user)
	if(user && (CLUMSY in user.mutations) && prob(50))
		user << "<span class='danger'>[src] slips out of your hand.</span>"
		user.drop_item()
		return 0
	return 1

/obj/item/device/flash/proc/flash_recharge()
	//capacitor recharges over time
	for(var/i=0, i<3, i++)
		if(last_used+600 > world.time)
			break
		last_used += 600
		times_used -= 2
	last_used = world.time
	times_used = max(0,round(times_used)) //sanity

/obj/item/device/flash/proc/burn_out(mob/user = null) //Made so you can override it if you want to have an invincible flash from R&D or something.
	broken = 1
	icon_state = burnt
	if(user)
		user << "<span class='warning'>The bulb has burnt out!</span>"


/obj/item/device/flash/attack(mob/living/M, mob/user)
	if(!user || !M)	return	//sanity

	add_logs(user, M, "flashed", object="[src.name]")

	if(!clown_check(user))	return
	if(broken)
		user << "<span class='warning'>[src] is broken.</span>"
		return

	flash_recharge()

	//spamming the flash before it's fully charged (60seconds) increases the chance of it  breaking
	//It will never break on the first use.
	switch(times_used)
		if(0 to 5)
			last_used = world.time
			if(prob(times_used))	//if you use it 5 times in a minute it has a 10% chance to break!
				burn_out(user)
				return
			times_used++
		else	//can only use it  5 times a minute
			user << "<span class='warning'>*click* *click*</span>"
			return
	playsound(src.loc, 'sound/weapons/flash.ogg', 100, 1)
	var/flashfail = 0

	if(iscarbon(M))
		var/safety = M:eyecheck()
		if(safety <= 0)
			M.Weaken(5)
			flick("e_flash", M.flash)

			if(ishuman(M) && ishuman(user) && M.stat != DEAD)
				if(user.mind && ((user.mind in ticker.mode.head_revolutionaries) || (user.mind in ticker.mode.A_bosses) || (user.mind in ticker.mode.B_bosses)))
					if(M.client)
						if(M.stat == CONSCIOUS)
							M.mind_initialize()		//give them a mind datum if they don't have one.
							var/resisted
							if(!isloyal(M))
								if(user.mind in ticker.mode.head_revolutionaries)
									M.mind.has_been_rev = 1
									if(!ticker.mode.add_revolutionary(M.mind))
										resisted = 1
								if(user.mind in ticker.mode.A_bosses)
									if(!ticker.mode.add_gangster(M.mind,"A"))
										resisted = 1
								if(user.mind in ticker.mode.B_bosses)
									if(!ticker.mode.add_gangster(M.mind,"B"))
										resisted = 1
							else
								resisted = 1

							if(resisted)
								user << "<span class='warning'>This mind seems resistant to the flash!</span>"
						else
							user << "<span class='warning'>They must be conscious before you can convert them!</span>"
					else
						user << "<span class='warning'>This mind is so vacant that it is not susceptible to influence!</span>"
		else
			flashfail = 1

	else if(issilicon(M))
		M.Weaken(rand(5,10))
	else
		flashfail = 1

	if(isrobot(user))
		spawn(0)
			var/atom/movable/overlay/animation = new(user.loc)
			animation.layer = user.layer + 1
			animation.icon_state = "blank"
			animation.icon = 'icons/mob/mob.dmi'
			animation.master = user
			flick("blspell", animation)
			sleep(5)
			qdel(animation)

	if(!flashfail)
		flick(flashanim, src)
		if(!issilicon(M))

			user.visible_message("<span class='disarm'>[user] blinds [M] with the flash!</span>")
		else

			user.visible_message("<span class='notice'>[user] overloads [M]'s sensors with the flash!</span>")
	else

		user.visible_message("<span class='notice'>[user] fails to blind [M] with the flash!</span>")




/obj/item/device/flash/attack_self(mob/living/carbon/user, flag = 0, emp = 0)
	if(!user || !clown_check(user)) 	return
	if(broken)
		user.show_message("<span class='warning'>[src] is broken!</span>", 2)
		return

	flash_recharge()

	//spamming the flash before it's fully charged (60seconds) increases the chance of it  breaking
	//It will never break on the first use.
	switch(times_used)
		if(0 to 5)
			if(prob(2*times_used))	//if you use it 5 times in a minute it has a 10% chance to break!
				burn_out(user)
				return
			times_used++
		else	//can only use it  5 times a minute
			user.show_message("<span class='warning'>*click* *click*</span>", 2)
			return
	playsound(src.loc, 'sound/weapons/flash.ogg', 100, 1)
	flick("flash2", src)
	if(user && isrobot(user))
		spawn(0)
			var/atom/movable/overlay/animation = new(user.loc)
			animation.layer = user.layer + 1
			animation.icon_state = "blank"
			animation.icon = 'icons/mob/mob.dmi'
			animation.master = user
			flick("blspell", animation)
			sleep(5)
			qdel(animation)

	for(var/mob/living/carbon/M in oviewers(3, null))
		var/safety = M:eyecheck()
		if(!safety)
			if(!M.blinded)
				flick("flash", M.flash)

	return

/obj/item/device/flash/emp_act(severity)
	if(broken)	return
	flash_recharge()
	switch(times_used)
		if(0 to 5)
			if(prob(2*times_used))
				burn_out()
				return
			times_used++
			if(istype(loc, /mob/living/carbon))
				var/mob/living/carbon/M = loc
				var/safety = M.eyecheck()
				if(safety <= 0)
					M.Weaken(5)
					flick("e_flash", M.flash)
					for(var/mob/O in viewers(M, null))
						O.show_message("<span class='disarm'>[M] is blinded by the flash!</span>")
	..()

/obj/item/device/flash/synthetic
	name = "synthetic flash"
	desc = "When a problem arises, SCIENCE is the solution."
	icon_state = "sflash"
	origin_tech = "magnets=2;combat=1"
	var/construction_cost = list("metal"=750, "glass"=750)
	var/construction_time=100

/obj/item/device/flash/synthetic/attack(mob/living/M, mob/user)
	..()
	if(!broken)
		burn_out(user)

/obj/item/device/flash/synthetic/attack_self(mob/living/carbon/user, flag = 0, emp = 0)
	..()
	if(!broken)
		burn_out(user)

/obj/item/device/flash/memorizer
	name = "memorizer"
	desc = "If you see this, you're not likely to remember it any time soon."
	icon_state = "memorizer"
	item_state = "nullrod"
	burnt = "memorizerburnt"
	flashanim = "memorizer2"

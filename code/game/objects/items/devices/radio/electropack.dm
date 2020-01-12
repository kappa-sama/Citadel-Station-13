/obj/item/electropack
	name = "electropack"
	desc = "Dance my monkeys! DANCE!!!"
	icon = 'icons/obj/radio.dmi'
	icon_state = "electropack0"
	item_state = "electropack"
	lefthand_file = 'icons/mob/inhands/misc/devices_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/misc/devices_righthand.dmi'
	flags_1 = CONDUCT_1
	slot_flags = ITEM_SLOT_BACK
	w_class = WEIGHT_CLASS_HUGE
	materials = list(MAT_METAL=10000, MAT_GLASS=2500)

	var/code = 2
	var/frequency = FREQ_ELECTROPACK
	var/on = TRUE
	var/shock_cooldown = FALSE

/obj/item/electropack/suicide_act(mob/living/carbon/user)
	user.visible_message("<span class='suicide'>[user] hooks [user.p_them()]self to the electropack and spams the trigger! It looks like [user.p_theyre()] trying to commit suicide!</span>")
	return (FIRELOSS)

/obj/item/electropack/Initialize()
	. = ..()
	set_frequency(frequency)

/obj/item/electropack/Destroy()
	SSradio.remove_object(src, frequency)
	. = ..()

//ATTACK HAND IGNORING PARENT RETURN VALUE
/obj/item/electropack/attack_hand(mob/user)
	if(iscarbon(user))
		var/mob/living/carbon/C = user
		if(src == C.back)
			to_chat(user, "<span class='warning'>You need help taking this off!</span>")
			return
	return ..()

/obj/item/electropack/attackby(obj/item/W, mob/living/user, params)
	if(istype(W, /obj/item/clothing/head/helmet))
		var/obj/item/assembly/shock_kit/A = new /obj/item/assembly/shock_kit(user)
		A.icon = 'icons/obj/assemblies.dmi'

		if(!user.transferItemToLoc(W, A))
			to_chat(user, "<span class='warning'>[W] is stuck to your hand, you cannot attach it to [src]!</span>")
			return
		W.master = A
		A.part1 = W

		user.transferItemToLoc(src, A, TRUE)
		master = A
		A.part2 = src

		user.put_in_hands(A)
		A.add_fingerprint(user)
	else
		return ..()

/obj/item/electropack/Topic(href, href_list)
	var/mob/living/carbon/C = usr
	if(usr.stat || usr.restrained() || C.back == src)
		return

	if(!usr.canUseTopic(src, BE_CLOSE))
		usr << browse(null, "window=radio")
		onclose(usr, "radio")
		return

	if(href_list["set"])
		if(href_list["set"] == "freq")
			var/new_freq = input(usr, "Input a new receiving frequency", "Electropack Frequency", format_frequency(frequency)) as num|null
			if(!usr.canUseTopic(src, BE_CLOSE))
				return
			new_freq = unformat_frequency(new_freq)
			new_freq = sanitize_frequency(new_freq, TRUE)
			set_frequency(new_freq)

		if(href_list["set"] == "code")
			var/new_code = input(usr, "Input a new receiving code", "Electropack Code", code) as num|null
			if(!usr.canUseTopic(src, BE_CLOSE))
				return
			new_code = round(new_code)
			new_code = CLAMP(new_code, 1, 100)
			code = new_code

		if(href_list["set"] == "power")
			if(!usr.canUseTopic(src, BE_CLOSE))
				return
			on = !(on)
			icon_state = "electropack[on]"

	if(usr)
		attack_self(usr)

	return

/obj/item/electropack/proc/set_frequency(new_frequency)
	SSradio.remove_object(src, frequency)
	frequency = new_frequency
	SSradio.add_object(src, frequency, RADIO_SIGNALER)
	return

/obj/item/electropack/receive_signal(datum/signal/signal)
	if(!signal || signal.data["code"] != code)
		return

	if(isliving(loc) && on)
		if(shock_cooldown == TRUE)
			return
		shock_cooldown = TRUE
		addtimer(VARSET_CALLBACK(src, shock_cooldown, FALSE), 100)
		var/mob/living/L = loc
		step(L, pick(GLOB.cardinals))

		to_chat(L, "<span class='danger'>You feel a sharp shock!</span>")
		var/datum/effect_system/spark_spread/s = new /datum/effect_system/spark_spread
		s.set_up(3, 1, L)
		s.start()

		L.Knockdown(100)

	if(master)
		master.receive_signal()
	return

/obj/item/electropack/ui_interact(mob/user)
	if(!ishuman(user))
		return

	user.set_machine(src)
	var/dat = {"
<TT>
Turned [on ? "On" : "Off"] - <A href='?src=[REF(src)];set=power'>Toggle</A><BR>
<B>Frequency/Code</B> for electropack:<BR>
Frequency:
[format_frequency(src.frequency)]
<A href='byond://?src=[REF(src)];set=freq'>Set</A><BR>
Code:
[src.code]
<A href='byond://?src=[REF(src)];set=code'>Set</A><BR>
</TT>"}
	user << browse(dat, "window=radio")
	onclose(user, "radio")
	return

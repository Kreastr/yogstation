/mob/living/carbon/human
	name = "Unknown"
	real_name = "Unknown"
	voice_name = "Unknown"
	icon = 'icons/mob/human.dmi'
	icon_state = "blank"



/mob/living/carbon/human/dummy
	real_name = "Test Dummy"
	status_flags = list(GODMODE, CANPUSH)



/mob/living/carbon/human/New()
	verbs += /mob/living/proc/mob_sleep
	verbs += /mob/living/proc/lay_down

	//initialize limbs first
	bodyparts = newlist(/obj/item/bodypart/chest, /obj/item/bodypart/head, /obj/item/bodypart/l_arm,
					 /obj/item/bodypart/r_arm, /obj/item/bodypart/r_leg, /obj/item/bodypart/l_leg)
	for(var/X in bodyparts)
		var/obj/item/bodypart/O = X
		O.owner = src

	//initialize dna. for spawned humans; overwritten by other code
	create_dna(src)
	randomize_human(src)
	dna.initialize_dna()

	if(dna.species)
		set_species(dna.species.type)

	//initialise organs
	if(!(NOHUNGER in dna.species.specflags))
		internal_organs += new /obj/item/organ/appendix

	if(!(NOBREATH in dna.species.specflags))
		internal_organs += new /obj/item/organ/lungs

	if(!(NOBLOOD in dna.species.specflags))
		internal_organs += new /obj/item/organ/heart

	internal_organs += new /obj/item/organ/brain

	//Note: Additional organs are generated/replaced on the dna.species level

	for(var/obj/item/organ/I in internal_organs)
		I.Insert(src, 1)

	martial_art = default_martial_art

	handcrafting = new()

	..()

/mob/living/carbon/human/OpenCraftingMenu()
	handcrafting.ui_interact(src)

/mob/living/carbon/human/prepare_data_huds()
	//Update med hud images...
	..()
	//...sec hud images...
	sec_hud_set_ID()
	sec_hud_set_implants()
	sec_hud_set_security_status()
	//...and display them.
	add_to_all_human_data_huds()

/mob/living/carbon/human/Stat()
	..()

	if(statpanel("Status"))
		stat(null, "Intent: [a_intent]")
		stat(null, "Move Mode: [m_intent]")
		if (internal)
			if (!internal.air_contents)
				qdel(internal)
			else
				stat("Internal Atmosphere Info", internal.name)
				stat("Tank Pressure", internal.air_contents.return_pressure())
				stat("Distribution Pressure", internal.distribute_pressure)
		if(mind)
			if(mind.changeling)
				stat("Chemical Storage", "[mind.changeling.chem_charges]/[mind.changeling.chem_storage]")
				stat("Extracted DNA", mind.changeling.profilecount)
				stat("Absorbed Lifeforms", mind.changeling.absorbedcount)
			if(mind.cyberman)
				stat("Hacking Module: [mind.cyberman.quickhack ? "Enabled" : "Disabled"] [mind.cyberman.emp_hit ? "%$&ERROR EMP DAMAGE [mind.cyberman.emp_hit]% #?@": ""]")
				for(var/obj/status_obj in mind.cyberman.get_status_objs(src))
					stat("", status_obj)


	//NINJACODE
	if(istype(wear_suit, /obj/item/clothing/suit/space/space_ninja)) //Only display if actually a ninja.
		var/obj/item/clothing/suit/space/space_ninja/SN = wear_suit
		if(statpanel("SpiderOS"))
			stat("SpiderOS Status:","[SN.s_initialized ? "Initialized" : "Disabled"]")
			stat("Current Time:", "[worldtime2text()]")
			if(SN.s_initialized)
				//Suit gear
				stat("Energy Charge:", "[round(SN.cell.charge/100)]%")
				stat("Smoke Bombs:", "\Roman [SN.s_bombs]")
				//Ninja status
				stat("Fingerprints:", "[md5(dna.uni_identity)]")
				stat("Unique Identity:", "[dna.unique_enzymes]")
				stat("Overall Status:", "[stat > 1 ? "dead" : "[health]% healthy"]")
				stat("Nutrition Status:", "[nutrition]")
				stat("Oxygen Loss:", "[getOxyLoss()]")
				stat("Toxin Levels:", "[getToxLoss()]")
				stat("Burn Severity:", "[getFireLoss()]")
				stat("Brute Trauma:", "[getBruteLoss()]")
				stat("Radiation Levels:","[radiation] rad")
				stat("Body Temperature:","[bodytemperature-T0C] degrees C ([bodytemperature*1.8-459.67] degrees F)")

				//Virsuses
				if(viruses.len)
					stat("Viruses:", null)
					for(var/datum/disease/D in viruses)
						stat("*", "[D.name], Type: [D.spread_text], Stage: [D.stage]/[D.max_stages], Possible Cure: [D.cure_text]")


/mob/living/carbon/human/ex_act(severity, ex_target)
	var/b_loss = null
	var/f_loss = null
	var/bomb_armor = getarmor(null, "bomb")

	if(locate(/mob/living/simple_animal/hostile/guardian/protector) in src)//if they've got a protector holo inside them
		var/mob/living/simple_animal/hostile/guardian/protector/G = locate(/mob/living/simple_animal/hostile/guardian/protector)
		if(severity == 1 && G.toggle)//can't think of a better way to do this since ex_act only works if the holo is actually hit with the explosion, which it isn't
			apply_damage(20,BRUTE)
		else
			if(G.toggle && severity > 1)
				visible_message("<span class='notice'><i>[src] glows in a <font color=\"[G.namedatum.colour]\">strange light </font>and is protected from the explosion!<i></span>")
				return
			else
				if(severity == 1)
					apply_damage(200,BRUTE)
				if(severity == 2)
					apply_damage(60,BRUTE)
				if(severity == 3)
					apply_damage(30,BRUTE)
		visible_message("<span class='notice'><i>[src] glows in a <font color=\"[G.namedatum.colour]\">strange light </font>and is protected from the explosion!<i></span>")
		return
	switch (severity)
		if (1)
			b_loss += 500
			if (prob(bomb_armor))
				shred_clothing(1,150)
				var/atom/target = get_edge_target_turf(src, get_dir(src, get_step_away(src, src)))
				throw_at(target, 200, 4)
			else
				gib()
				return

		if (2)
			b_loss += 60

			f_loss += 60
			if (prob(bomb_armor))
				b_loss = b_loss/1.5
				f_loss = f_loss/1.5
				shred_clothing(1,25)
			else
				shred_clothing(1,50)

			if (!istype(ears, /obj/item/clothing/ears/earmuffs))
				adjustEarDamage(30, 120)
			if (prob(70))
				Paralyse(10)

		if(3)
			b_loss += 30
			if (prob(bomb_armor))
				b_loss = b_loss/2
			if (!istype(ears, /obj/item/clothing/ears/earmuffs))
				adjustEarDamage(15,60)
			if (prob(50))
				Paralyse(10)

	take_overall_damage(b_loss,f_loss)
	//attempt to dismember bodyparts
	if(severity <= 2 || !bomb_armor)
		var/max_limb_loss = round(4/severity) //so you don't lose four limbs at severity 3.
		for(var/X in bodyparts)
			var/obj/item/bodypart/BP = X
			if(prob(50/severity) && !prob(getarmor(BP, "bomb")) && BP.body_zone != "head" && BP.body_zone != "chest")
				BP.brute_dam = BP.max_damage
				BP.dismember()
				max_limb_loss--
				if(!max_limb_loss)
					break
	..()

/mob/living/carbon/human/blob_act(obj/effect/blob/B)
	if(stat == DEAD)
		return
	show_message("<span class='userdanger'>The blob attacks you!</span>")
	var/dam_zone = pick("chest", "l_hand", "r_hand", "l_leg", "r_leg")
	var/obj/item/bodypart/affecting = get_bodypart(ran_zone(dam_zone))
	apply_damage(5, BRUTE, affecting, run_armor_check(affecting, "melee"))
	return

/mob/living/carbon/human/bullet_act(obj/item/projectile/Proj)
	if(martial_art && martial_art.try_deflect_projectile(src, Proj)) //Some martial arts users can deflect projectiles!
		return
	..()

/mob/living/carbon/human/attack_ui(slot)
	if(!get_bodypart(hand ? "l_arm" : "r_arm"))
		return 0
	return ..()

/mob/living/carbon/human/show_inv(mob/user)
	user.set_machine(src)
	var/has_breathable_mask = istype(wear_mask, /obj/item/clothing/mask)
	var/list/obscured = check_obscured_slots()

	var/dat = {"<table>
	<tr><td><B>Left Hand:</B></td><td><A href='?src=\ref[src];item=[slot_l_hand]'>[(l_hand && !(l_hand.flags&ABSTRACT)) ? l_hand : "<font color=grey>Empty</font>"]</A></td></tr>
	<tr><td><B>Right Hand:</B></td><td><A href='?src=\ref[src];item=[slot_r_hand]'>[(r_hand && !(r_hand.flags&ABSTRACT)) ? r_hand : "<font color=grey>Empty</font>"]</A></td></tr>
	<tr><td>&nbsp;</td></tr>"}

	dat += "<tr><td><B>Back:</B></td><td><A href='?src=\ref[src];item=[slot_back]'>[(back && !(back.flags&ABSTRACT)) ? back : "<font color=grey>Empty</font>"]</A>"
	if(has_breathable_mask && istype(back, /obj/item/weapon/tank))
		dat += "&nbsp;<A href='?src=\ref[src];internal=[slot_back]'>[internal ? "Disable Internals" : "Set Internals"]</A>"

	dat += "</td></tr><tr><td>&nbsp;</td></tr>"

	dat += "<tr><td><B>Head:</B></td><td><A href='?src=\ref[src];item=[slot_head]'>[(head && !(head.flags&ABSTRACT)) ? head : "<font color=grey>Empty</font>"]</A></td></tr>"

	if(slot_wear_mask in obscured)
		dat += "<tr><td><font color=grey><B>Mask:</B></font></td><td><font color=grey>Obscured</font></td></tr>"
	else
		dat += "<tr><td><B>Mask:</B></td><td><A href='?src=\ref[src];item=[slot_wear_mask]'>[(wear_mask && !(wear_mask.flags&ABSTRACT)) ? wear_mask : "<font color=grey>Empty</font>"]</A></td></tr>"

	if(slot_glasses in obscured)
		dat += "<tr><td><font color=grey><B>Eyes:</B></font></td><td><font color=grey>Obscured</font></td></tr>"
	else
		dat += "<tr><td><B>Eyes:</B></td><td><A href='?src=\ref[src];item=[slot_glasses]'>[(glasses && !(glasses.flags&ABSTRACT))	? glasses : "<font color=grey>Empty</font>"]</A></td></tr>"

	if(slot_ears in obscured)
		dat += "<tr><td><font color=grey><B>Ears:</B></font></td><td><font color=grey>Obscured</font></td></tr>"
	else
		dat += "<tr><td><B>Ears:</B></td><td><A href='?src=\ref[src];item=[slot_ears]'>[(ears && !(ears.flags&ABSTRACT))		? ears		: "<font color=grey>Empty</font>"]</A></td></tr>"

	dat += "<tr><td>&nbsp;</td></tr>"

	dat += "<tr><td><B>Exosuit:</B></td><td><A href='?src=\ref[src];item=[slot_wear_suit]'>[(wear_suit && !(wear_suit.flags&ABSTRACT)) ? wear_suit : "<font color=grey>Empty</font>"]</A></td></tr>"
	if(wear_suit)
		dat += "<tr><td>&nbsp;&#8627;<B>Suit Storage:</B></td><td><A href='?src=\ref[src];item=[slot_s_store]'>[(s_store && !(s_store.flags&ABSTRACT)) ? s_store : "<font color=grey>Empty</font>"]</A>"
		if(has_breathable_mask && istype(s_store, /obj/item/weapon/tank))
			dat += "&nbsp;<A href='?src=\ref[src];internal=[slot_s_store]'>[internal ? "Disable Internals" : "Set Internals"]</A>"
		dat += "</td></tr>"
	else
		dat += "<tr><td><font color=grey>&nbsp;&#8627;<B>Suit Storage:</B></font></td></tr>"

	if(slot_shoes in obscured)
		dat += "<tr><td><font color=grey><B>Shoes:</B></font></td><td><font color=grey>Obscured</font></td></tr>"
	else
		dat += "<tr><td><B>Shoes:</B></td><td><A href='?src=\ref[src];item=[slot_shoes]'>[(shoes && !(shoes.flags&ABSTRACT))		? shoes		: "<font color=grey>Empty</font>"]</A></td></tr>"

	if(slot_gloves in obscured)
		dat += "<tr><td><font color=grey><B>Gloves:</B></font></td><td><font color=grey>Obscured</font></td></tr>"
	else
		dat += "<tr><td><B>Gloves:</B></td><td><A href='?src=\ref[src];item=[slot_gloves]'>[(gloves && !(gloves.flags&ABSTRACT))		? gloves	: "<font color=grey>Empty</font>"]</A></td></tr>"

	if(slot_w_uniform in obscured)
		dat += "<tr><td><font color=grey><B>Uniform:</B></font></td><td><font color=grey>Obscured</font></td></tr>"
	else
		dat += "<tr><td><B>Uniform:</B></td><td><A href='?src=\ref[src];item=[slot_w_uniform]'>[(w_uniform && !(w_uniform.flags&ABSTRACT)) ? w_uniform : "<font color=grey>Empty</font>"]</A></td></tr>"

	if((w_uniform == null && !(dna && dna.species.nojumpsuit)) || (slot_w_uniform in obscured))
		dat += "<tr><td><font color=grey>&nbsp;&#8627;<B>Pockets:</B></font></td></tr>"
		dat += "<tr><td><font color=grey>&nbsp;&#8627;<B>ID:</B></font></td></tr>"
		dat += "<tr><td><font color=grey>&nbsp;&#8627;<B>Belt:</B></font></td></tr>"
	else
		dat += "<tr><td>&nbsp;&#8627;<B>Belt:</B></td><td><A href='?src=\ref[src];item=[slot_belt]'>[(belt && !(belt.flags&ABSTRACT)) ? belt : "<font color=grey>Empty</font>"]</A>"
		if(has_breathable_mask && istype(belt, /obj/item/weapon/tank))
			dat += "&nbsp;<A href='?src=\ref[src];internal=[slot_belt]'>[internal ? "Disable Internals" : "Set Internals"]</A>"
		dat += "</td></tr>"
		dat += "<tr><td>&nbsp;&#8627;<B>Pockets:</B></td><td><A href='?src=\ref[src];pockets=left'>[(l_store && !(l_store.flags&ABSTRACT)) ? "Left (Full)" : "<font color=grey>Left (Empty)</font>"]</A>"
		dat += "&nbsp;<A href='?src=\ref[src];pockets=right'>[(r_store && !(r_store.flags&ABSTRACT)) ? "Right (Full)" : "<font color=grey>Right (Empty)</font>"]</A></td></tr>"
		dat += "<tr><td>&nbsp;&#8627;<B>ID:</B></td><td><A href='?src=\ref[src];item=[slot_wear_id]'>[(wear_id && !(wear_id.flags&ABSTRACT)) ? wear_id : "<font color=grey>Empty</font>"]</A></td></tr>"

	for (var/obj/item/bodypart/org in bodyparts)
		if (org.can_be_bandaged && org.bandaged)
			dat += "<tr><td><i>[getLimbDisplayName(org.name)]</i> wrapped with:</td><td><a href='byond://?src=\ref[src];unwrap=\ref[org.bandaged]'>[org.bandaged]</a></td></tr>"

	if(handcuffed)
		dat += "<tr><td><B>Handcuffed:</B> <A href='?src=\ref[src];item=[slot_handcuffed]'>Remove</A></td></tr>"
	if(legcuffed)
		dat += "<tr><td><A href='?src=\ref[src];item=[slot_legcuffed]'>Legcuffed</A></td></tr>"

	dat += {"</table>
	<A href='?src=\ref[user];mach_close=mob\ref[src]'>Close</A>
	"}

	var/datum/browser/popup = new(user, "mob\ref[src]", "[src]", 440, 510)
	popup.set_content(dat)
	popup.open()

// called when something steps onto a human
// this could be made more general, but for now just handle mulebot
/mob/living/carbon/human/Crossed(atom/movable/AM)
	var/mob/living/simple_animal/bot/mulebot/MB = AM
	if(istype(MB))
		MB.RunOver(src)

	spreadFire(AM)

//Added a safety check in case you want to shock a human mob directly through electrocute_act.
/mob/living/carbon/human/electrocute_act(shock_damage, obj/source, siemens_coeff = 1, safety = 0, override = 0, tesla_shock = 0)
	if(tesla_shock)
		var/total_coeff = 1
		if(gloves)
			var/obj/item/clothing/gloves/G = gloves
			if(G.siemens_coefficient <= 0)
				total_coeff -= 0.5
		if(wear_suit)
			var/obj/item/clothing/suit/S = wear_suit
			if(S.siemens_coefficient <= 0)
				total_coeff -= 0.95
		siemens_coeff = total_coeff
	else if(!safety)
		var/gloves_siemens_coeff = 1
		if(gloves)
			var/obj/item/clothing/gloves/G = gloves
			gloves_siemens_coeff = G.siemens_coefficient
		siemens_coeff = gloves_siemens_coeff
	if(heart_attack)
		if(shock_damage * siemens_coeff >= 1 && prob(25))
			heart_attack = 0
			if(stat == CONSCIOUS)
				to_chat(src, "<span class='notice'>You feel your heart beating again!</span>")
	//CYBERMEN STUFF
	//I'd prefer to have an event-listener setup. see emp_act in human_defense.
	if(cyberman_network)
		for(var/datum/cyberman_hack/human/H in cyberman_network.active_cybermen_hacks)
			if(H.target == src)
				H.electrocute_act()
				break
	. = ..(shock_damage,source,siemens_coeff,safety,override,tesla_shock)
	if(.)
		electrocution_animation(40)



/mob/living/carbon/human/Topic(href, href_list)
	if(usr.canUseTopic(src, BE_CLOSE, NO_DEXTERY))

		if(href_list["embedded_object"])
			var/obj/item/I = locate(href_list["embedded_object"])
			var/obj/item/bodypart/L = locate(href_list["embedded_limb"])
			if(!I || !L || I.loc != src || !(I in L.embedded_objects)) //no item, no limb, or item is not in limb or in the person anymore
				return
			var/time_taken = I.embedded_unsafe_removal_time*I.w_class
			usr.visible_message("<span class='warning'>[usr] attempts to remove [I] from their [L.name].</span>","<span class='notice'>You attempt to remove [I] from your [L.name]... (It will take [time_taken/10] seconds.)</span>")
			if(do_after(usr, time_taken, needhand = 1, target = src))
				if(!I || !L || I.loc != src || !(I in L.embedded_objects))
					return
				L.embedded_objects -= I
				L.take_damage(I.embedded_unsafe_removal_pain_multiplier*I.w_class)//It hurts to rip it out, get surgery you dingus.
				I.loc = get_turf(src)
				usr.put_in_hands(I)
				usr.emote("scream")
				usr.visible_message("[usr] successfully rips [I] out of their [L.name]!","<span class='notice'>You successfully remove [I] from your [L.name].</span>")
				if(!has_embedded_objects())
					clear_alert("embeddedobject")
			return

		if(href_list["item"])
			var/slot = text2num(href_list["item"])
			if(slot in check_obscured_slots())
				to_chat(usr, "<span class='warning'>You can't reach that! Something is covering it.</span>")
				return

		if(href_list["pockets"])
			var/pocket_side = href_list["pockets"]
			var/pocket_id = (pocket_side == "right" ? slot_r_store : slot_l_store)
			var/obj/item/pocket_item = (pocket_id == slot_r_store ? r_store : l_store)
			var/obj/item/place_item = usr.get_active_hand() // Item to place in the pocket, if it's empty

			var/delay_denominator = 1
			if(pocket_item && !(pocket_item.flags&ABSTRACT))
				if(pocket_item.flags & NODROP)
					to_chat(usr, "<span class='warning'>You try to empty [src]'s [pocket_side] pocket, it seems to be stuck!</span>")
				to_chat(usr, "<span class='notice'>You try to empty [src]'s [pocket_side] pocket.</span>")
			else if(place_item && place_item.mob_can_equip(src, usr, pocket_id, 1) && !(place_item.flags&ABSTRACT))
				to_chat(usr, "<span class='notice'>You try to place [place_item] into [src]'s [pocket_side] pocket.</span>")
				delay_denominator = 4
			else
				return

			if(do_mob(usr, src, POCKET_STRIP_DELAY/delay_denominator)) //placing an item into the pocket is 4 times faster
				if(pocket_item)
					if(pocket_item == (pocket_id == slot_r_store ? r_store : l_store)) //item still in the pocket we search
						unEquip(pocket_item)
				else
					if(place_item && usr.unEquip(place_item))
						equip_to_slot_if_possible(place_item, pocket_id, 0, 1)

				// Update strip window
				if(usr.machine == src && in_range(src, usr))
					show_inv(usr)
			else
				// Display a warning if the user mocks up
				to_chat(src, "<span class='warning'>You feel your [pocket_side] pocket being fumbled with!</span>")

		..()


///////HUDs///////
	if(href_list["hud"])
		if(istype(usr, /mob/living/carbon/human))
			var/mob/living/carbon/human/H = usr
			var/perpname = get_face_name(get_id_name(""))
			if(istype(H.glasses, /obj/item/clothing/glasses/hud))
				var/datum/data/record/R = find_record("name", perpname, data_core.general)
				if(href_list["photo_front"] || href_list["photo_side"])
					if(R)
						if(!H.canUseHUD())
							return
						else if(!istype(H.glasses, /obj/item/clothing/glasses/hud))
							return
						var/obj/item/weapon/photo/P = null
						if(href_list["photo_front"])
							P = R.fields["photo_front"]
						else if(href_list["photo_side"])
							P = R.fields["photo_side"]
						if(P)
							P.show(H)

				if(href_list["hud"] == "m")
					if(istype(H.glasses, /obj/item/clothing/glasses/hud/health))
						if(href_list["p_stat"])
							var/health = input(usr, "Specify a new physical status for this person.", "Medical HUD", R.fields["p_stat"]) as anything in list("Active", "Physically Unfit", "*Unconscious*", "*Deceased*", "Cancel")
							if(R)
								if(!H.canUseHUD())
									return
								else if(!istype(H.glasses, /obj/item/clothing/glasses/hud/health))
									return
								if(health && health != "Cancel")
									R.fields["p_stat"] = health
							return
						if(href_list["m_stat"])
							var/health = input(usr, "Specify a new mental status for this person.", "Medical HUD", R.fields["m_stat"]) as anything in list("Stable", "*Watch*", "*Unstable*", "*Insane*", "Cancel")
							if(R)
								if(!H.canUseHUD())
									return
								else if(!istype(H.glasses, /obj/item/clothing/glasses/hud/health))
									return
								if(health && health != "Cancel")
									R.fields["m_stat"] = health
							return
						if(href_list["evaluation"])
							if(!getBruteLoss() && !getFireLoss() && !getOxyLoss() && getToxLoss() < 20)
								to_chat(usr, "<span class='notice'>No external injuries detected.</span><br>")
								return
							var/span = "notice"
							var/status = ""
							if(getBruteLoss())
								to_chat(usr, "<b>Physical trauma analysis:</b>")
								for(var/X in bodyparts)
									var/obj/item/bodypart/BP = X
									var/brutedamage = BP.brute_dam
									if(brutedamage > 0)
										status = "received minor physical injuries."
										span = "notice"
									if(brutedamage > 20)
										status = "been seriously damaged."
										span = "danger"
									if(brutedamage > 40)
										status = "sustained major trauma!"
										span = "userdanger"
									if(brutedamage)
										to_chat(usr, "<span class='[span]'>[BP] appears to have [status]</span>")
							if(getFireLoss())
								to_chat(usr, "<b>Analysis of skin burns:</b>")
								for(var/X in bodyparts)
									var/obj/item/bodypart/BP = X
									var/burndamage = BP.burn_dam
									if(burndamage > 0)
										status = "signs of minor burns."
										span = "notice"
									if(burndamage > 20)
										status = "serious burns."
										span = "danger"
									if(burndamage > 40)
										status = "major burns!"
										span = "userdanger"
									if(burndamage)
										to_chat(usr, "<span class='[span]'>[BP] appears to have [status]</span>")
							if(getOxyLoss())
								to_chat(usr, "<span class='danger'>Patient has signs of suffocation, emergency treatment may be required!</span>")
							if(getToxLoss() > 20)
								to_chat(usr, "<span class='danger'>Gathered data is inconsistent with the analysis, possible cause: poisoning.</span>")

				if(href_list["hud"] == "s")
					if(istype(H.glasses, /obj/item/clothing/glasses/hud/security))
						if(usr.stat || usr == src) //|| !usr.canmove || usr.restrained()) Fluff: Sechuds have eye-tracking technology and sets 'arrest' to people that the wearer looks and blinks at.
							return													  //Non-fluff: This allows sec to set people to arrest as they get disarmed or beaten
						// Checks the user has security clearence before allowing them to change arrest status via hud, comment out to enable all access
						var/allowed_access = null
						var/obj/item/clothing/glasses/G = H.glasses
						if (!G.emagged)
							if(H.wear_id)
								var/list/access = H.wear_id.GetAccess()
								if(access_sec_doors in access)
									allowed_access = H.get_authentification_name()
						else
							allowed_access = "@%&ERROR_%$*"


						if(!allowed_access)
							to_chat(H, "<span class='warning'>ERROR: Invalid Access</span>")
							return

						if(perpname)
							R = find_record("name", perpname, data_core.security)
							if(R)
								if(href_list["status"])
									var/setcriminal = input(usr, "Specify a new criminal status for this person.", "Security HUD", R.fields["criminal"]) as anything in list("None", "*Arrest*", "Incarcerated", "Parolled", "Discharged", "Cancel")
									if(setcriminal != "Cancel")
										if(R)
											if(H.canUseHUD())
												if(istype(H.glasses, /obj/item/clothing/glasses/hud/security))
													investigate_log("[src.key] has been set from [R.fields["criminal"]] to [setcriminal] by [usr.name] ([usr.key]).", "records")
													R.fields["criminal"] = setcriminal
													sec_hud_set_security_status()
									return

								if(href_list["view"])
									if(R)
										if(!H.canUseHUD())
											return
										else if(!istype(H.glasses, /obj/item/clothing/glasses/hud/security))
											return
										to_chat(usr, "<b>Name:</b> [R.fields["name"]]	<b>Criminal Status:</b> [R.fields["criminal"]]")
										to_chat(usr, "<b>Minor Crimes:</b>")
										for(var/datum/data/crime/c in R.fields["mi_crim"])
											to_chat(usr, "<b>Crime:</b> [c.crimeName]")
											to_chat(usr, "<b>Details:</b> [c.crimeDetails]")
											to_chat(usr, "Added by [c.author] at [c.time]")
											to_chat(usr, "----------")
										to_chat(usr, "<b>Major Crimes:</b>")
										for(var/datum/data/crime/c in R.fields["ma_crim"])
											to_chat(usr, "<b>Crime:</b> [c.crimeName]")
											to_chat(usr, "<b>Details:</b> [c.crimeDetails]")
											to_chat(usr, "Added by [c.author] at [c.time]")
											to_chat(usr, "----------")
										to_chat(usr, "<b>Notes:</b> [R.fields["notes"]]")
									return

								if(href_list["add_crime"])
									switch(alert("What crime would you like to add?","Security HUD","Minor Crime","Major Crime","Cancel"))
										if("Minor Crime")
											if(R)
												var/t1 = stripped_input(usr, "Please input minor crime names:", "Security HUD", "", null)
												var/t2 = stripped_multiline_input("Please input minor crime details:", "Security HUD", "", null)
												if(R)
													if (!t1 || !t2 || !allowed_access)
														return
													else if(!H.canUseHUD())
														return
													else if(!istype(H.glasses, /obj/item/clothing/glasses/hud/security))
														return
													var/crime = data_core.createCrimeEntry(t1, t2, allowed_access, worldtime2text())
													data_core.addMinorCrime(R.fields["id"], crime)
													to_chat(usr, "<span class='notice'>Successfully added a minor crime.</span>")
													return
										if("Major Crime")
											if(R)
												var/t1 = stripped_input(usr, "Please input major crime names:", "Security HUD", "", null)
												var/t2 = stripped_multiline_input("Please input major crime details:", "Security HUD", "", null)
												if(R)
													if (!t1 || !t2 || !allowed_access)
														return
													else if (!H.canUseHUD())
														return
													else if (!istype(H.glasses, /obj/item/clothing/glasses/hud/security))
														return
													var/crime = data_core.createCrimeEntry(t1, t2, allowed_access, worldtime2text())
													data_core.addMajorCrime(R.fields["id"], crime)
													to_chat(usr, "<span class='notice'>Successfully added a major crime.</span>")
									return

								if(href_list["view_comment"])
									if(R)
										if(!H.canUseHUD())
											return
										else if(!istype(H.glasses, /obj/item/clothing/glasses/hud/security))
											return
										to_chat(usr, "<b>Comments/Log:</b>")
										var/counter = 1
										while(R.fields[text("com_[]", counter)])
											to_chat(usr, R.fields[text("com_[]", counter)])
											to_chat(usr, "----------")
											counter++
										return

								if(href_list["add_comment"])
									if(R)
										var/t1 = stripped_multiline_input("Add Comment:", "Secure. records", null, null)
										if(R)
											if (!t1 || !allowed_access)
												return
											else if(!H.canUseHUD())
												return
											else if(!istype(H.glasses, /obj/item/clothing/glasses/hud/security))
												return
											var/counter = 1
											while(R.fields[text("com_[]", counter)])
												counter++
											R.fields[text("com_[]", counter)] = text("Made by [] on [] [], []<BR>[]", allowed_access, worldtime2text(), time2text(world.realtime, "MMM DD"), year_integer+540, t1,)
											to_chat(usr, "<span class='notice'>Successfully added comment.</span>")
											return
							to_chat(usr, "<span class='warning'>Unable to locate a data core entry for this person.</span>")

/mob/living/carbon/human/proc/canUseHUD()
	return !(src.stat || src.weakened || src.stunned || src.restrained())

/mob/living/carbon/human/can_inject(mob/user, error_msg, target_zone, var/penetrate_thick = 0)
	. = 1 // Default to returning true.
	if(user && !target_zone)
		target_zone = user.zone_selected
	if(dna && (PIERCEIMMUNE in dna.species.specflags))
		. = 0
	// If targeting the head, see if the head item is thin enough.
	// If targeting anything else, see if the wear suit is thin enough.
	if(above_neck(target_zone))
		if(head && head.flags & THICKMATERIAL && !penetrate_thick)
			. = 0
	else
		if(wear_suit && wear_suit.flags & THICKMATERIAL && !penetrate_thick)
			. = 0
	if(!. && error_msg && user)
		// Might need re-wording.
		to_chat(user, "<span class='alert'>There is no exposed flesh or thin material [above_neck(target_zone) ? "on their head" : "on their body"].</span>")

/mob/living/carbon/human/proc/check_obscured_slots()
	var/list/obscured = list()

	if(wear_suit)
		if(wear_suit.flags_inv & HIDEGLOVES)
			obscured |= slot_gloves
		if(wear_suit.flags_inv & HIDEJUMPSUIT)
			obscured |= slot_w_uniform
		if(wear_suit.flags_inv & HIDESHOES)
			obscured |= slot_shoes

	if(head)
		if(head.flags_inv & HIDEMASK)
			obscured |= slot_wear_mask
		if(head.flags_inv & HIDEEYES)
			obscured |= slot_glasses
		if(head.flags_inv & HIDEEARS)
			obscured |= slot_ears

	if(wear_mask)
		if(wear_mask.flags_inv & HIDEEYES)
			obscured |= slot_glasses

	if(obscured.len > 0)
		return obscured
	else
		return null

/mob/living/carbon/human/assess_threat(mob/living/simple_animal/bot/secbot/judgebot, lasercolor)
	if(judgebot.emagged == 2)
		return 10 //Everyone is a criminal!

	var/threatcount = 0

	//Lasertag bullshit
	if(lasercolor)
		if(lasercolor == "b")//Lasertag turrets target the opposing team, how great is that? -Sieve
			if(istype(wear_suit, /obj/item/clothing/suit/redtag))
				threatcount += 4
			if((istype(r_hand,/obj/item/weapon/gun/energy/laser/redtag)) || (istype(l_hand,/obj/item/weapon/gun/energy/laser/redtag)))
				threatcount += 4
			if(istype(belt, /obj/item/weapon/gun/energy/laser/redtag))
				threatcount += 2

		if(lasercolor == "r")
			if(istype(wear_suit, /obj/item/clothing/suit/bluetag))
				threatcount += 4
			if((istype(r_hand,/obj/item/weapon/gun/energy/laser/bluetag)) || (istype(l_hand,/obj/item/weapon/gun/energy/laser/bluetag)))
				threatcount += 4
			if(istype(belt, /obj/item/weapon/gun/energy/laser/bluetag))
				threatcount += 2

		return threatcount

	//Check for ID
	var/obj/item/weapon/card/id/idcard = get_idcard()
	if(judgebot.idcheck && !idcard && name=="Unknown")
		threatcount += 4

	//Check for weapons
	if(judgebot.weaponscheck)
		if(!idcard || !(access_weapons in idcard.access))
			if(judgebot.check_for_weapons(l_hand))
				threatcount += 4
			if(judgebot.check_for_weapons(r_hand))
				threatcount += 4
			if(judgebot.check_for_weapons(belt))
				threatcount += 2

	//Check for arrest warrant
	if(judgebot.check_records)
		var/perpname = get_face_name(get_id_name())
		var/datum/data/record/R = find_record("name", perpname, data_core.security)
		if(R && R.fields["criminal"])
			switch(R.fields["criminal"])
				if("*Arrest*")
					threatcount += 5
				if("Incarcerated")
					threatcount += 2
				if("Parolled")
					threatcount += 2

	//Check for dresscode violations
	if(istype(head, /obj/item/clothing/head/wizard) || istype(head, /obj/item/clothing/head/helmet/space/hardsuit/wizard))
		threatcount += 2

	//Check for nonhuman scum
	if(dna && dna.species.id && dna.species.id != "human")
		threatcount += 1

	//mindshield implants imply trustworthyness
	if(isloyal(src))
		threatcount -= 1

	//Agent cards lower threatlevel.
	if(istype(idcard, /obj/item/weapon/card/id/syndicate))
		threatcount -= 5

	return threatcount


//Used for new human mobs created by cloning/goleming/podding
/mob/living/carbon/human/proc/set_cloned_appearance()
	if(gender == MALE)
		facial_hair_style = "Full Beard"
	else
		facial_hair_style = "Shaved"
	hair_style = pick("Bedhead", "Bedhead 2", "Bedhead 3")
	underwear = "Nude"
	update_body()
	update_hair()

/mob/living/carbon/human/singularity_act()
	var/gain = 20
	if(mind)
		if((mind.assigned_role == "Station Engineer") || (mind.assigned_role == "Chief Engineer") )
			gain = 100
		if(mind.assigned_role == "Clown")
			gain = rand(-300, 300)
	investigate_log("([key_name(src)]) has been consumed by the singularity.","singulo") //Oh that's where the clown ended up!
	gib()
	return(gain)

/mob/living/carbon/human/singularity_pull(S, current_size)
	if(current_size >= STAGE_THREE)
		var/list/handlist = list(l_hand, r_hand)
		for(var/obj/item/hand in handlist)
			if(prob(current_size * 5) && hand.w_class >= ((11-current_size)/2)  && unEquip(hand))
				step_towards(hand, src)
				to_chat(src, "<span class='warning'>\The [S] pulls \the [hand] from your grip!</span>")
	rad_act(current_size * 3)
	if(mob_negates_gravity())
		return
	..()


/mob/living/carbon/human/help_shake_act(mob/living/carbon/M)
	if(!istype(M))
		return

	if(health >= 0)
		if(src == M)
			visible_message( \
				"[src] examines \himself.", \
				"<span class='notice'>You check yourself for injuries.</span>")

			var/list/missing = list("head", "chest", "l_arm", "r_arm", "l_leg", "r_leg")
			for(var/X in bodyparts)
				var/obj/item/bodypart/LB = X
				missing -= LB.body_zone
				var/status = ""
				var/brutedamage = LB.brute_dam
				var/burndamage = LB.burn_dam
				if(hallucination)
					if(prob(30))
						brutedamage += rand(30,40)
					if(prob(30))
						burndamage += rand(30,40)

				if(brutedamage > 0)
					status = "bruised"
				if(brutedamage > 20)
					status = "battered"
				if(brutedamage > 40)
					status = "mangled"
				if(brutedamage > 0 && burndamage > 0)
					status += " and "
				if(burndamage > 40)
					status += "peeling away"

				else if(burndamage > 10)
					status += "blistered"
				else if(burndamage > 0)
					status += "numb"
				if(status == "")
					status = "OK"
				to_chat(src, "\t [status == "OK" ? "\blue" : "\red"] Your [LB.name] is [status].")

				for(var/obj/item/I in LB.embedded_objects)
					to_chat(src, "\t <a href='byond://?src=\ref[src];embedded_object=\ref[I];embedded_limb=\ref[LB]'>\red There is \a [I] embedded in your [LB.name]!</a>")

			for(var/t in missing)
				to_chat(src, "<span class='boldannounce'>Your [parse_zone(t)] is missing!</span>")

			if(bleed_rate)
				to_chat(src, "<span class='danger'>You are bleeding!</span>")
			if(staminaloss)
				if(staminaloss > 30)
					to_chat(src, "<span class='info'>You're completely exhausted.</span>")
				else
					to_chat(src, "<span class='info'>You feel fatigued.</span>")
		else
			if(wear_suit)
				wear_suit.add_fingerprint(M)
			else if(w_uniform)
				w_uniform.add_fingerprint(M)

			..()


/mob/living/carbon/human/proc/do_cpr(mob/living/carbon/C)
	CHECK_DNA_AND_SPECIES(C)

	if(C.stat == DEAD)
		to_chat(src, "<span class='warning'>[C.name] is dead!</span>")
		return
	if(NOCRIT in C.status_flags)//no crit when you're stimmed
		return
	if(is_mouth_covered())
		to_chat(src, "<span class='warning'>Remove your mask first!</span>")
		return 0
	if(C.is_mouth_covered())
		to_chat(src, "<span class='warning'>Remove their mask first!</span>")
		return 0

	if(C.cpr_time < world.time + 30)
		visible_message("<span class='notice'>[src] is trying to perform CPR on [C.name]!</span>", \
						"<span class='notice'>You try to perform CPR on [C.name]... Hold still!</span>")
		if(!do_mob(src, C))
			to_chat(src, "<span class='warning'>You fail to perform CPR on [C]!</span>")
			return 0

		var/they_breathe = (!(NOBREATH in C.dna.species.specflags))
		var/they_lung = C.getorganslot("lungs")

		if(C.health > config.health_threshold_crit)
			return

		src.visible_message("[src] performs CPR on [C.name]!", "<span class='notice'>You perform CPR on [C.name].</span>")
		C.cpr_time = world.time
		add_logs(src, C, "CPRed")

		if(they_breathe && they_lung)
			var/suff = min(C.getOxyLoss(), 7)
			C.adjustOxyLoss(-suff)
			C.updatehealth()
			to_chat(C, "<span class='unconscious'>You feel a breath of fresh air enter your lungs... It feels good...</span>")
		else if(they_breathe && !they_lung)
			to_chat(C, "<span class='unconscious'>You feel a breath of fresh air... but you don't feel any better...</span>")
		else
			to_chat(C, "<span class='unconscious'>You feel a breath of fresh air... which is a sensation you don't recognise...</span>")

/mob/living/carbon/human/generateStaticOverlay()
	var/image/staticOverlay = image(icon('icons/effects/effects.dmi', "static"), loc = src)
	staticOverlay.override = 1
	staticOverlays["static"] = staticOverlay

	staticOverlay = image(icon('icons/effects/effects.dmi', "blank"), loc = src)
	staticOverlay.override = 1
	staticOverlays["blank"] = staticOverlay

	staticOverlay = getLetterImage(src, "H", 1)
	staticOverlay.override = 1
	staticOverlays["letter"] = staticOverlay

	staticOverlay = getRandomAnimalImage(src)
	staticOverlay.override = 1
	staticOverlays["animal"] = staticOverlay

/mob/living/carbon/human/cuff_resist(obj/item/I)
	if(dna && (dna.check_mutation(HULK) || dna.check_mutation(ACTIVE_HULK)))
		say(pick(";RAAAAAAAARGH!", ";HNNNNNNNNNGGGGGGH!", ";GWAAAAAAAARRRHHH!", "NNNNNNNNGGGGGGGGHH!", ";AAAAAAARRRGH!" ))
		if(..(I, cuff_break = FAST_CUFFBREAK))
			unEquip(I)
	else
		if(..())
			unEquip(I)

/mob/living/carbon/human/clean_blood()
	var/mob/living/carbon/human/H = src
	if(H.gloves)
		if(H.gloves.clean_blood())
			H.update_inv_gloves()
	else
		..() // Clear the Blood_DNA list
		if(H.bloody_hands)
			H.bloody_hands = 0
			H.update_inv_gloves()
	if(H.shoes)
		H.shoes.clean_blood()
	update_icons()	//apply the now updated overlays to the mob


/mob/living/carbon/human/proc/wash_cream()
	//clean both to prevent a rare bug
	overlays -=image('icons/effects/creampie.dmi', "creampie_lizard")
	overlays -=image('icons/effects/creampie.dmi', "creampie_human")


//Turns a mob black, flashes a skeleton overlay
//Just like a cartoon!
/mob/living/carbon/human/proc/electrocution_animation(anim_duration)
	//Handle mutant parts if possible
	if(dna && dna.species)
		overlays += "electrocuted_base"
		spawn(anim_duration)
			if(src)
				overlays -= "electrocuted_base"

	else //or just do a generic animation
		var/list/viewing = list()
		for(var/mob/M in viewers(src))
			if(M.client)
				viewing += M.client
		flick_overlay(image(icon,src,"electrocuted_generic",ABOVE_MOB_LAYER), viewing, anim_duration)

/mob/living/carbon/human/canUseTopic(atom/movable/M, be_close = 0)
	if(incapacitated() || lying )
		return
	if(!Adjacent(M) && (M.loc != src))
		if((be_close == 0) && (dna.check_mutation(TK)))
			if(tkMaxRangeCheck(src, M))
				return 1
		return
	return 1

/mob/living/carbon/human/resist_restraints()
	if(wear_suit && wear_suit.breakouttime)
		changeNext_move(CLICK_CD_BREAKOUT)
		last_special = world.time + CLICK_CD_BREAKOUT
		cuff_resist(wear_suit)
	else
		..()

/mob/living/carbon/human/replace_records_name(oldname,newname) // Only humans have records right now, move this up if changed.
	for(var/list/L in list(data_core.general,data_core.medical,data_core.security,data_core.locked))
		var/datum/data/record/R = find_record("name", oldname, L)
		if(R)
			R.fields["name"] = newname

/mob/living/carbon/human/update_sight()
	if(!client)
		return
	if(stat == DEAD)
		sight = (SEE_TURFS|SEE_MOBS|SEE_OBJS)
		see_in_dark = 8
		see_invisible = SEE_INVISIBLE_OBSERVER
		return

	dna.species.update_sight(src)

/mob/living/carbon/human/get_total_tint()
	. = ..()
	if(glasses)
		. += glasses.tint

/mob/living/carbon/human/update_health_hud()
	if(!client || !hud_used)
		return
	if(dna.species.update_health_hud())
		return
	else
		if(hud_used.healths)
			var/health_amount = health - staminaloss
			if(..(health_amount)) //not dead
				switch(hal_screwyhud)
					if(1)
						hud_used.healths.icon_state = "health6"
					if(2)
						hud_used.healths.icon_state = "health7"
					if(5)
						hud_used.healths.icon_state = "health0"
		if(hud_used.healthdoll)
			hud_used.healthdoll.overlays.Cut()
			if(stat != DEAD)
				hud_used.healthdoll.icon_state = "healthdoll_OVERLAY"
				for(var/X in bodyparts)
					var/obj/item/bodypart/BP = X
					var/damage = BP.burn_dam + BP.brute_dam
					var/comparison = (BP.max_damage/5)
					var/icon_num = 0
					if(damage)
						icon_num = 1
					if(damage > (comparison))
						icon_num = 2
					if(damage > (comparison*2))
						icon_num = 3
					if(damage > (comparison*3))
						icon_num = 4
					if(damage > (comparison*4))
						icon_num = 5
					if(hal_screwyhud == 5)
						icon_num = 0
					if(icon_num)
						hud_used.healthdoll.overlays += image('icons/mob/screen_gen.dmi',"[BP.body_zone][icon_num]")
				for(var/t in get_missing_limbs()) //Missing limbs
					hud_used.healthdoll.overlays += image('icons/mob/screen_gen.dmi',"[t]6")
			else
				hud_used.healthdoll.icon_state = "healthdoll_DEAD"

/mob/living/carbon/human/fully_heal(admin_revive = 0)
	CHECK_DNA_AND_SPECIES(src)

	if(admin_revive)
		regenerate_limbs()

	remove_all_embedded_objects()
	drunkenness = 0
	for(var/datum/mutation/human/HM in dna.mutations)
		if(HM.quality != POSITIVE)
			dna.remove_mutation(HM.name)
	..()

/mob/living/carbon/human/regenerate_organs()
	..()
	CHECK_DNA_AND_SPECIES(src)
	if(!(NOBREATH in dna.species.specflags) && !getorganslot("lungs"))
		var/obj/item/organ/lungs/L = new()
		L.Insert(src)

	if(!(NOBLOOD in dna.species.specflags) && !getorganslot("heart"))
		var/obj/item/organ/heart/H = new()
		H.Insert(src)

	if(!getorganslot("tongue"))
		var/obj/item/organ/tongue/T

		for(var/tongue_type in dna.species.mutant_organs)
			if(ispath(tongue_type, /obj/item/organ/tongue))
				T = new tongue_type()
				T.Insert(src)

		// if they have no mutant tongues, give them a regular one
		if(!T)
			T = new()
			T.Insert(src)

/mob/living/carbon/human/proc/influenceSin()
	var/datum/objective/sintouched/O
	switch(rand(1,7))//traditional seven deadly sins... except lust.
		if(1) // acedia
			log_game("[src] was influenced by the sin of Acedia.")
			O = new /datum/objective/sintouched/acedia
		if(2) // Gluttony
			log_game("[src] was influenced by the sin of gluttony.")
			O = new /datum/objective/sintouched/gluttony
		if(3) // Greed
			log_game("[src] was influenced by the sin of greed.")
			O = new /datum/objective/sintouched/greed
		if(4) // sloth
			log_game("[src] was influenced by the sin of sloth.")
			O = new /datum/objective/sintouched/sloth
		if(5) // Wrath
			log_game("[src] was influenced by the sin of wrath.")
			O = new /datum/objective/sintouched/wrath
		if(6) // Envy
			log_game("[src] was influenced by the sin of envy.")
			O = new /datum/objective/sintouched/envy
		if(7) // Pride
			log_game("[src] was influenced by the sin of pride.")
			O = new /datum/objective/sintouched/pride
	ticker.mode.sintouched += src.mind
	src.mind.objectives += O
	var/obj_count = 1
	to_chat(src, "<span class='notice'>Your current objectives:</span>")
	for(O in src.mind.objectives)
		var/datum/objective/objective = O
		to_chat(src, "<B>Objective #[obj_count]</B>: [objective.explanation_text]")
		obj_count++

/mob/living/carbon/human/check_weakness(obj/item/weapon, mob/living/attacker)
	. = ..()
	if (dna && dna.species)
		. += dna.species.check_weakness(weapon, attacker)

/mob/living/carbon/human/is_literate()
	return 1

/mob/living/carbon/human/update_gravity(has_gravity,override = 0)
	override = dna.species.override_float
	..()

/mob/living/carbon/human/flash_eyes(intensity = 1, override_blindness_check = 0, affect_silicon = 0, visual = 0)
	if(dna && dna.species && dna.species.handle_flash(src, intensity, override_blindness_check, affect_silicon, visual))
		return 0
	return ..()

/mob/living/carbon/human/is_nearcrit()
	if(health <= config.health_threshold_crit && health > HEALTH_THRESHOLD_DEEPCRIT)
		if(!(NOCRIT in status_flags))
			return TRUE
	return FALSE

/mob/living/carbon/human/proc/hulk_health_check(oldhealth)
	if(dna.check_mutation(ACTIVE_HULK))
		if(health < config.health_threshold_crit)
			dna.remove_mutation(ACTIVE_HULK)
			return
		if(health < oldhealth)
			adjustStaminaLoss(-1.5 * (oldhealth - health))
	else
		if(!dna.check_mutation(HULK) && dna.check_mutation(GENETICS_HULK) && stat == CONSCIOUS && oldhealth >= health + 10)
			dna.add_mutation(ACTIVE_HULK)

/mob/living/carbon/human/proc/hulk_stamina_check()
	if(dna.check_mutation(ACTIVE_HULK))
		if(staminaloss >= 90)
			dna.remove_mutation(ACTIVE_HULK)
			to_chat(src, "<span class='notice'>You have calm down enough to become human again.</span>")
			Weaken(6)
		return 1
	else
		return 0

/client/verb/ooc(msg as text)
	set name = "OOC" //Gave this shit a shorter name so you only have to time out "ooc" rather than "ooc message" to use it --NeoFite
	set category = "OOC"

	if(say_disabled)	//This is here to try to identify lag problems
		usr.text2tab("<span class='danger'>Speech is currently admin-disabled.</span>","ooc")
		return

	if(!mob)
		return
	if(IsGuestKey(key))
		src.text2tab("Guests may not use OOC.","ooc")
		return

	msg = copytext(sanitize(msg), 1, MAX_MESSAGE_LEN)
	if(!msg)
		return

	if(!(prefs.chat_toggles & CHAT_OOC))
		src.text2tab("<span class='danger'>You have OOC muted.</span>","ooc")
		return

	if(!holder)
		if(!ooc_allowed)
			src.text2tab("<span class='danger'>OOC is globally muted.</span>","ooc")
			return
		if(!dooc_allowed && (mob.stat == DEAD))
			usr.text2tab("<span class='danger'>OOC for dead mobs has been turned off.</span>","ooc")
			return
		if(prefs.muted & MUTE_OOC)
			src.text2tab("<span class='danger'>You cannot use OOC (muted).</span>","ooc")
			return
		if(src.mob)
			if(jobban_isbanned(src.mob, "OOC"))
				src.text2tab("<span class='danger'>You have been banned from OOC.</span>","ooc")
				return
		if(handle_spam_prevention(msg,MUTE_OOC))
			return
		if(findtext(msg, "byond://"))
			src.text2tab("<B>Advertising other servers is not allowed.</B>","ooc")
			log_admin("[key_name(src)] has attempted to advertise in OOC: [msg]")
			message_admins("[key_name_admin(src)] has attempted to advertise in OOC: [msg]")
			return

	var/raw_msg = msg

	msg = emoji_parse(msg)

	if((copytext(msg, 1, 2) in list(".",";",":","#")) || (findtext(lowertext(copytext(msg, 1, 5)), "say")))
		if(alert("Your message \"[raw_msg]\" looks like it was meant for in game communication, say it in OOC?", "Meant for OOC?", "No", "Yes") != "Yes")
			return

	log_ooc("[mob.name]/[key] : [raw_msg]")

	var/keyname = key
	if(prefs.unlock_content)
		if(prefs.toggles & MEMBER_PUBLIC)
			keyname = "<font color='[prefs.ooccolor ? prefs.ooccolor : normal_ooc_colour]'><img style='width:9px;height:9px;' class=icon src=\ref['icons/member_content.dmi'] iconstate=blag>[keyname]</font>"

	for(var/client/C in clients)
		if(C.prefs.chat_toggles & CHAT_OOC)
			if(holder)
				if(!holder.fakekey || C.holder)
					if(check_rights_for(src, R_TRIALADMIN))
						C.text2tab("<span class='adminooc'>[config.allow_admin_ooccolor && prefs.ooccolor ? "<font color=[prefs.ooccolor]>" :"" ]<span class='prefix'>OOC:</span> <EM>[keyname][holder.fakekey ? "/([holder.fakekey])" : ""]:</EM> <span class='message'>[msg]</span></span></font>","ooc")
					else
						C.text2tab("<span class='adminobserverooc'><span class='prefix'>OOC:</span> <EM>[keyname][holder.fakekey ? "/([holder.fakekey])" : ""]:</EM> <span class='message'>[msg]</span></span>","ooc")
				else
					C.text2tab("<font color='[normal_ooc_colour]'><span class='ooc'><span class='prefix'>OOC:</span> <EM>[holder.fakekey ? holder.fakekey : key]:</EM> <span class='message'>[msg]</span></span></font>","ooc")
			else if(!(key in C.prefs.ignoring))
				C.text2tab("<font color='[normal_ooc_colour]'><span class='ooc'><span class='prefix'>OOC:</span> <EM>[keyname]:</EM> <span class='message'>[msg]</span></span></font>","ooc")

/proc/toggle_ooc(toggle = null)
	if(toggle != null) //if we're specifically en/disabling ooc
		if(toggle != ooc_allowed)
			ooc_allowed = toggle
		else
			return
	else //otherwise just toggle it
		ooc_allowed = !ooc_allowed
	text2world("<B>The OOC channel has been globally [ooc_allowed ? "enabled" : "disabled"].</B>","ooc")

var/global/normal_ooc_colour = OOC_COLOR

/client/proc/set_ooc(newColor as color)
	set name = "Set Player OOC Color"
	set desc = "Modifies player OOC Color"
	set category = "Fun"
	normal_ooc_colour = sanitize_ooccolor(newColor)

/client/proc/reset_ooc()
	set name = "Reset Player OOC Color"
	set desc = "Returns player OOC Color to default"
	set category = "Fun"
	normal_ooc_colour = OOC_COLOR

/client/verb/colorooc()
	set name = "Set Your OOC Color"
	set category = "Preferences"

	if(!holder || check_rights_for(src, R_ADMIN))
		if(!is_content_unlocked())
			return

	var/new_ooccolor = input(src, "Please select your OOC color.", "OOC color", prefs.ooccolor) as color|null
	if(new_ooccolor)
		prefs.ooccolor = sanitize_ooccolor(new_ooccolor)
		prefs.save_preferences()
	feedback_add_details("admin_verb","OC") //If you are copy-pasting this, ensure the 2nd parameter is unique to the new proc!
	return

/client/verb/resetcolorooc()
	set name = "Reset Your OOC Color"
	set desc = "Returns your OOC Color to default"
	set category = "Preferences"

	if(!holder || check_rights_for(src, R_ADMIN))
		if(!is_content_unlocked())
			return

		prefs.ooccolor = initial(prefs.ooccolor)
		prefs.save_preferences()

//Checks admin notice
/client/verb/admin_notice()
	set name = "Adminnotice"
	set category = "Admin"
	set desc ="Check the admin notice if it has been set"

	if(admin_notice)
		src.text2tab("<span class='boldnotice'>Admin Notice:</span>\n \t [admin_notice]","ooc")
	else
		src.text2tab("<span class='notice'>There are no admin notices at the moment.</span>","ooc")

/client/verb/motd()
	set name = "MOTD"
	set category = "OOC"
	set desc ="Check the Message of the Day"

	if(join_motd)
		src.text2tab("<div class=\"motd\">[join_motd]</div>","ooc")
	else
		src.text2tab("<span class='notice'>The Message of the Day has not been set.</span>","ooc")

/client/proc/self_notes()
	set name = "View Admin Notes"
	set category = "OOC"
	set desc = "View the notes that admins have written about you"

	if(!config.see_own_notes)
		usr.text2tab("<span class='notice'>Sorry, that function is not enabled on this server.</span>","ooc")
		return

	show_note(usr, null, 1)

/client/proc/ignore_key(client)
	var/client/C = client
	if(C.key in prefs.ignoring)
		prefs.ignoring -= C.key
	else
		prefs.ignoring |= C.key
	src.text2tab("You are [(C.key in prefs.ignoring) ? "now" : "no longer"] ignoring [C.key] on the OOC channel.","ooc")
	prefs.save_preferences()

/client/verb/select_ignore()
	set name = "Ignore"
	set category = "OOC"
	set desc ="Ignore a player's messages on the OOC channel"

	var/selection = input("Please, select a player!", "Ignore", null, null) as null|anything in sortKey(clients)
	if(!selection)
		return
	if(selection == src)
		src.text2tab("You can't ignore yourself.","ooc")
		return
	ignore_key(selection)

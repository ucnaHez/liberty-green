/mob/living/carbon/alien/humanoid/drone
	name = "alien drone"
	caste = "d"
	maxHealth = 125
	health = 125
	icon_state = "aliend_s"


/mob/living/carbon/alien/humanoid/drone/New()
	internal_organs += new /obj/item/organ/alien/plasmavessel/large
	internal_organs += new /obj/item/organ/alien/resinspinner
	internal_organs += new /obj/item/organ/alien/acid

	AddAbility(new/obj/effect/proc_holder/alien/evolve(null))
	..()

/mob/living/carbon/alien/humanoid/drone/movement_delay()
	. = ..()

/obj/effect/proc_holder/alien/evolve
	name = "Evolve to Praetorian"
	desc = "Praetorian"
	plasma_cost = 500

	action_icon_state = "alien_evolve_drone"

/obj/effect/proc_holder/alien/evolve/fire(mob/living/carbon/alien/humanoid/user)
	var/obj/item/organ/alien/hivenode/node = user.getorgan(/obj/item/organ/alien/hivenode)
	if(!node) //Players are Murphy's Law. We may not expect there to ever be a living xeno with no hivenode, but they _WILL_ make it happen.
		user.text2tab("<span class='danger'>Without the hivemind, you can't possibly hold the responsibility of leadership!</span>")
		return 0
	if(node.recent_queen_death)
		user.text2tab("<span class='danger'>Your thoughts are still too scattered to take up the position of leadership.</span>")
		return 0

	if(!isturf(user.loc))
		user.text2tab("<span class='notice'>You can't evolve here!</span>")
		return 0
	if(!alien_type_present(/mob/living/carbon/alien/humanoid/royal))
		var/mob/living/carbon/alien/humanoid/royal/praetorian/new_xeno = new (user.loc)
		user.alien_evolve(new_xeno)
		return 1
	else
		user.text2tab("<span class='notice'>We already have a living royal!</span>")
		return 0

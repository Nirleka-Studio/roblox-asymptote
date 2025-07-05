1. The Plan - Guard.
 a. A Guard can detect a Player. Their suspicion level goes from 0.0 to 1.0.
    For simplicity, the distance between the Player and the Guard should not affect
    the speed of the suspicion raise.
    Since a Guard can only focus on one player to dictate their suspicion level
    rising, a Guard prioritises which player to focus one:
      i. The Player with the highest suspicious activity.
     ii. The Player who is the closest.
 b. If a Guard's suspicion level reaches its maximum value, which is 1.0, the Guard
    will act accordingly. Which includes, but not limited to:
      i. The Guard runs towards the suspected Player if they are trespassing.
         If the Player leaves the trespassing area, the Guard will return to its
         original goal.
     ii. If The Guard previously encountered a tespassing Player encounters them again,
         but this time wearing a disguise, the Guard will see through the disguise and
         the suspicioun meter will fill up. However, if the Guard never seen the Player before,
         that is its suspicion level never filled up on a suspected Player, they will ignore them.
 c. A Guard's default goals and activities are listed in the following order of priority:
      i. Investigating.
     ii. Patrolling.
 d. If a Guard's suspicion level reaches a specific threshold, the Guard can stop whatever its doing
    and face the suspecting Player, until the suspicion level reaches 1.0 or the Player is out of sight.
    Once a Player is out of sight, as expected, the suspicion level decays. And if reaches a threshold,
    the Guard returns to its original goal.
 e. Of course, a Guard can have a reaction time. For example, if a Guard caught a Player, waits for a
    period, and then chase them. 

2. Player Suspicious Statuses. These statuses together affects the speed on how a Guard's
suspicion level increases. A Player can have the following statuses, and they can be stacked:

  i. Minor trespassing;
 ii. Major trespassing;
iii. Minor suspicious;
 iv. Criminal suspicious;
  v. Disguised; and
 vi. Armed.

3. Conclusion. We are to create a lightweight and expandable system capable of performing
these exact behaviours for our Guards and NPC system in a stealth game.
extends Node
## Narrative database: dialogue lines for all cutscenes.
## Each function returns an Array[Dictionary] with {speaker, text}.

## Level 01 - Intro: Farm life, before the attack
func intro_farm() -> Array[Dictionary]:
	return [
		{"speaker": "Narrator", "text": "Einar, a simple farmer of the northern fjords, returns from the hunt."},
		{"speaker": "Einar", "text": "The air smells wrong... smoke from the village."},
		{"speaker": "Narrator", "text": "He runs. The longhouse is burning. His family is gone."},
		{"speaker": "Einar", "text": "No... NO! Who did this?!"},
		{"speaker": "Narrator", "text": "A survivor whispers one name: Jarl Halvard. Allied with the English king."},
		{"speaker": "Einar", "text": "Halvard... I will find you. I will burn your world to ash."},
		{"speaker": "Narrator", "text": "And so the farmer died that day. From the ashes, a bear arose."},
	]

## Level 02 - Exile: The burned forest
func exile_forest() -> Array[Dictionary]:
	return [
		{"speaker": "Narrator", "text": "Einar follows the trail of destruction eastward."},
		{"speaker": "Einar", "text": "Halvard's men... they went through these woods."},
		{"speaker": "Narrator", "text": "The forest is scarred. The ashes of the dead cling to everything."},
		{"speaker": "Einar", "text": "They took my wife. My children. For what? Silver?"},
		{"speaker": "Narrator", "text": "There is no answer. Only the path ahead."},
	]

## Level 05 - Pre-Boss: Facing Halvard
func before_halvard() -> Array[Dictionary]:
	return [
		{"speaker": "Narrator", "text": "Einar reaches the Jarl's hall. The doors are open, as if expecting him."},
		{"speaker": "Einar", "text": "Halvard! Show yourself, coward!"},
		{"speaker": "Jarl Halvard", "text": "The farmer who became a bear. I've heard of you."},
		{"speaker": "Jarl Halvard", "text": "Your family? Your wife was... useful. The boy has spirit."},
		{"speaker": "Einar", "text": "WHERE ARE THEY?!"},
		{"speaker": "Jarl Halvard", "text": "The boy went south. To England. The king likes young warriors."},
		{"speaker": "Einar", "text": "If he is hurt... I will make you suffer before you die."},
		{"speaker": "Narrator", "text": "The Jarl laughs. Steel meets steel. One of them will not leave this hall."},
	]

## Level 07 - Final Boss: The tragic reveal
func final_boss_intro() -> Array[Dictionary]:
	return [
		{"speaker": "Narrator", "text": "Einar crosses the ash-covered battlefield. In the distance, a figure waits."},
		{"speaker": "Narrator", "text": "The English king's champion. A young warrior in black armor."},
		{"speaker": "Young Warrior", "text": "You must be the one they call the Ash Bear."},
		{"speaker": "Einar", "text": "Stand aside, boy. I have no quarrel with you."},
		{"speaker": "Young Warrior", "text": "I have been told to kill you. I have no choice."},
		{"speaker": "Narrator", "text": "They fight. Steel on steel. Father against son, neither knowing."},
	]

func final_boss_defeat() -> Array[Dictionary]:
	return [
		{"speaker": "Narrator", "text": "The young warrior falls. Einar kneels beside him."},
		{"speaker": "Young Warrior", "text": "Father...?"},
		{"speaker": "Einar", "text": "No. No, no, no... it cannot be..."},
		{"speaker": "Narrator", "text": "Under the black armor, the face of a boy. His son."},
		{"speaker": "Einar", "text": "My son... my boy... what have I done?"},
		{"speaker": "Narrator", "text": "The Ash Bear holds his son as the ashes fall around them."},
		{"speaker": "Narrator", "text": "There is no victory. There is no justice. Only ashes."},
		{"speaker": "Narrator", "text": "The fire that forged the bear consumed everything he loved."},
	]

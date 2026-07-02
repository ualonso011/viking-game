extends Node
## Narrative database: dialogue lines for all cutscenes.
## Each function returns an Array[Dictionary] with {speaker, text, portrait?, background?}.

## Level 01 - Intro: Farm life, before the attack
func intro_farm() -> Array[Dictionary]:
	return [
		{"speaker": "Narrador", "text": "Einar, un simple granjero de los fiordos del norte, regresa de la caza."},
		{"speaker": "Einar", "text": "El aire huele mal... humo del pueblo."},
		{"speaker": "Narrador", "text": "Corre. El salón arde. Su familia ha desaparecido."},
		{"speaker": "Einar", "text": "No... ¡NO! ¿Quién hizo esto?"},
		{"speaker": "Narrador", "text": "Un superviviente susurra un nombre: el Jarl Halvard. Aliado del rey inglés."},
		{"speaker": "Einar", "text": "Halvard... te encontraré. Reduciré tu mundo a cenizas."},
		{"speaker": "Narrador", "text": "Así murió el granjero aquel día. De las cenizas surgió un oso."},
	]

## Level 02 - Exile: The burned forest
func exile_forest() -> Array[Dictionary]:
	return [
		{"speaker": "Narrador", "text": "Einar sigue el rastro de destrucción hacia el este."},
		{"speaker": "Einar", "text": "Los hombres de Halvard... cruzaron estos bosques."},
		{"speaker": "Narrador", "text": "El bosque está herido. Las cenizas de los muertos se adhieren a todo."},
		{"speaker": "Einar", "text": "Se llevaron a mi mujer. A mis hijos. ¿Por qué? ¿Por plata?"},
		{"speaker": "Narrador", "text": "No hay respuesta. Solo el camino adelante."},
	]

## Level 03 - Cinders: Entering the ruined village
func cinders_intro() -> Array[Dictionary]:
	return [
		{"speaker": "Narrador", "text": "Lo que fue granja es ahora ceniza.", "background": "cinders_village"},
		{"speaker": "Einar", "text": "Restos de hogares. Los de Halvard pasaron por aquí como langostas.", "portrait": "einar"},
		{"speaker": "Narrador", "text": "Cada paso que da, el oso que lleva dentro crece un poco más."},
		{"speaker": "Einar", "text": "El odio es combustible. No me quedará nada cuando esto termine."},
	]

## Level 04 - Warpath: Snowy mountains
func warpath_intro() -> Array[Dictionary]:
	return [
		{"speaker": "Narrador", "text": "Las montañas de nieve reciben a Einar con un silencio blanco.", "background": "snowy_mountains"},
		{"speaker": "Einar", "text": "El frío me recuerda a casa. Antes del fuego.", "portrait": "einar"},
		{"speaker": "Narrador", "text": "Una fortaleza se asoma entre la niebla. La morada del Jarl."},
		{"speaker": "Einar", "text": "Halvard. Por fin.", "portrait": "einar"},
	]

## Level 05 - Pre-Boss: Facing Halvard
func before_halvard() -> Array[Dictionary]:
	return [
		{"speaker": "Narrador", "text": "Einar llega al salón del Jarl. Las puertas están abiertas, como si lo esperaran."},
		{"speaker": "Einar", "text": "¡Halvard! ¡Muéstrate, cobarde!"},
		{"speaker": "Jarl Halvard", "text": "El granjero que se convirtió en oso. He oído hablar de ti."},
		{"speaker": "Jarl Halvard", "text": "¿Tu familia? Tu mujer fue... útil. El niño tiene temple."},
		{"speaker": "Einar", "text": "¡¿DÓNDE ESTÁN?!"},
		{"speaker": "Jarl Halvard", "text": "El niño fue al sur. A Inglaterra. Al rey le gustan los jóvenes guerreros."},
		{"speaker": "Einar", "text": "Si está herido... te haré sufrir antes de morir."},
		{"speaker": "Narrador", "text": "El Jarl ríe. El acero choca contra el acero. Uno de ellos no saldrá de este salón."},
	]

## Level 06 - England: Arriving on hostile shores
func england_intro() -> Array[Dictionary]:
	return [
		{"speaker": "Narrador", "text": "Inglaterra. La tierra que Halvard sirve.", "background": "english_coast"},
		{"speaker": "Einar", "text": "Si mi hijo está aquí, lo encontraré. Aunque tenga que cruzar este reino entero.", "portrait": "einar"},
		{"speaker": "Soldado inglés", "text": "¡Ahí! ¡Un vikingo! ¡A las armas!", "portrait": "english_soldier"},
	]

## Level 07 - Final Boss: The tragic reveal
func final_boss_intro() -> Array[Dictionary]:
	return [
		{"speaker": "Narrador", "text": "Einar atraviesa el campo de batalla cubierto de cenizas. A lo lejos, una figura espera."},
		{"speaker": "Narrador", "text": "El campeón del rey inglés. Un joven guerrero con armadura negra."},
		{"speaker": "Joven guerrero", "text": "Debes ser a quien llaman el Oso de Ceniza."},
		{"speaker": "Einar", "text": "Apártate, muchacho. No tengo contigo."},
		{"speaker": "Joven guerrero", "text": "Me ordenaron matarte. No tengo elección."},
		{"speaker": "Narrador", "text": "Luchan. Acero contra acero. Padre contra hijo, sin saberlo."},
	]

func final_boss_defeat() -> Array[Dictionary]:
	return [
		{"speaker": "Narrador", "text": "El joven guerrero cae. Einar se arrodilla a su lado."},
		{"speaker": "Joven guerrero", "text": "¿Padre...?"},
		{"speaker": "Einar", "text": "No. No, no, no... no puede ser..."},
		{"speaker": "Narrador", "text": "Bajo la armadura negra, el rostro de un niño. Su hijo."},
		{"speaker": "Einar", "text": "Mi hijo... mi niño... ¿qué he hecho?"},
		{"speaker": "Narrador", "text": "El Oso de Ceniza sostiene a su hijo mientras las cenizas caen a su alrededor."},
		{"speaker": "Narrador", "text": "No hay victoria. No hay justicia. Solo cenizas."},
		{"speaker": "Narrador", "text": "El fuego que forjó al oso consumió todo lo que amaba."},
	]

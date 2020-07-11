extends Node

const FIRST_LEVEL = 'Level1'
const LEVEL_SEQ = {
	'Level1': 'Level2',
	'Level2': 'GameWin',
}

func startScene(name: String):
	get_tree().change_scene('res://Scenes/' + name + '.tscn')
	get_tree().paused = false

func startFirstLevel():
	startScene(FIRST_LEVEL)

func startLevel(name: String):
	get_tree().paused = true
	var currentScene = get_tree().current_scene
	currentScene.fadeOut()
	var timer = currentScene.find_node("FadeTimer")
	timer.set_wait_time(0.5)
	timer.connect('timeout', self, 'startScene', [name])
	timer.start()

func startNextLevel():
	var currentLevelName = get_tree().current_scene.name
	var nextLevelName = LEVEL_SEQ[currentLevelName]
	startLevel(nextLevelName)

extends Node2D

@onready var QTEbar: Node2D = $QTEbar
@onready var Fire : AnimatedSprite2D = $Fire
@onready var Tosser: Node2D = $Tosser
@onready var wok : AnimatedSprite2D = $Wok
@onready var title : AnimatedSprite2D = $TitleScreen
@onready var saltCan : AnimatedSprite2D = $saltCan
@onready var shrimpHands : AnimatedSprite2D = $shrimpHands
@onready var controlIns : AnimatedSprite2D = $controlInstruct
@onready var AudioBGM : AudioStreamPlayer2D = $AudioBGM
@onready var AudioVictory : AudioStreamPlayer2D = $AudioVictory
@onready var AudioDefeat : AudioStreamPlayer2D = $AudioDefeat

signal startFireQTE
signal startTossing
signal playRiceStill

var isTossing = false

var hits = 0
var misses = 0

var gordon = false

var riceState = 0
# 0 = undercooked
# 1 = good
# 2 = bad

var tossNum = 0

var onTitle = true

func _ready():
	QTEbar.hide()
	Fire.hide()
	Tosser.hide()
	saltCan.hide()
	shrimpHands.hide()
	controlIns.hide()
	riceState = 0
	wok.riceStateLocal = 0
	playRiceStill.emit()
	AudioVictory.stop()
	AudioDefeat.stop()
	onTitle = true
	
	QTEbar.safeStartInit = QTEbar.safestart.position.y
	QTEbar.safeEndInit = QTEbar.safeend.position.y
	QTEbar.safezonesize = QTEbar.safestart.position.y - QTEbar.safeend.position.y
	
	title.play("default")
	title.show()


func _process(delta: float) -> void:
	if Input.is_action_just_pressed("tap") and onTitle:
		title.hide()
		title.pause()
		newGame()
		shrimpHands.play("default")
		shrimpHands.show()
		
		onTitle = false

func newGame():
	print("start")
	gordonStart()

func gordonStart():
	gordon = true
	Dialogic.timeline_ended.connect(gordonOver)
	Dialogic.start("timeline")
	
func gordonOver():
	Dialogic.timeline_ended.disconnect(gordonOver)
	QTEbar.show()
	startFireQTE.emit()
	
	Fire.play("inactive")
	controlIns.show()
	controlIns.play("QTEinstructions")
	Fire.show()
	
func _on_fireLit() -> void:
	QTEbar.hide()
	controlIns.play("tossingInstructions")
	startTossing.emit()

signal startSaltGame

func startSalt():
	controlIns.play("QTEinstructions")
	saltCan.show()
	QTEbar.show()
	playRiceStill.emit()
	QTEbar.gameNum = 2
	startSaltGame.emit()
	saltCan.play("pour")
	
	
# if toss is good, stays good. or if it was initially undercooked it becomes cooked
# if toss is slow, the rice heats unevenly, so the state increases by 1 (on the road to getting burnt)
# if the toss is fase, the rice doesnt cook, so the state doesnt change

func _on_goodToss() -> void:
	hits += 1
	if riceState == 0 or riceState == 1:
		riceState = 1
	else: 
		riceState += 1
	tossingDone()

func _on_tossSlow() -> void:
	misses += 1
	riceState += 1
	tossingDone()

func _on_tossFast() -> void:
	misses += 1
	tossingDone()
# salt success: plays the salt success animation

func _on_QTEsaltFailed() -> void:
	saltCan.play("fail")
	misses += 1
	saltDone()

func _on_QTEsaltSuccess() -> void:
	saltCan.play("success")
	hits += 1
	saltDone()
	
func saltDone() :
	controlIns.play("tossingInstructions")
	startTossing.emit()
	QTEbar.hide()
	
func tossingDone():
	wok.riceStateLocal = riceState
	tossNum += 1
	if tossNum == 1:
		startSalt()
	if tossNum == 2 and gordon:
		controlIns.hide()
		AudioBGM.stop()
		if misses == 0:
			AudioVictory.play()
			Dialogic.start("goodEnd")
		else:
			AudioDefeat.play()
			Dialogic.start("badEnd")
	


func _on_audio_victory_finished() -> void:
	AudioBGM.play()

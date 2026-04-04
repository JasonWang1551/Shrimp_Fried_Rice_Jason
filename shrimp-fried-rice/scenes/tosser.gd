extends Node2D

@onready var goodPic : Sprite2D = $goodIndicator
@onready var badPic : Sprite2D = $badIndicator
@onready var timerGame : Timer = $gameDuration
@onready var fastPic : Sprite2D = $fast
@onready var slowPic : Sprite2D = $slow
@onready var nicePic : Sprite2D = $nice

signal tossNormal
signal tossSlow
signal tossFast

signal tossingDone

var gameOn = false
var hitRate
var firstTap = true

var currTime
var lastClickTime = 0.0
var timeSinceLastClick
var lowBound = 0.7
var highBound = 0.9

var scoreList = Array()

var speedState
# 0 = slow
# 1 = good
# 2 = fast


func showGood():
	goodPic.show()
	badPic.hide()
	fastPic.hide()
	slowPic.hide()
	nicePic.show()
	
	
func showBad():
	badPic.show()
	goodPic.hide()

func showSlow():
	fastPic.hide()
	nicePic.hide()
	slowPic.show()
	

func showFast():
	slowPic.hide()
	nicePic.hide()
	fastPic.show()
	

func _on_startTossing() -> void:
	slowPic.hide()
	fastPic.hide()
	nicePic.hide()
	print("starting to toss")
	gameOn = true
	firstTap = true
	scoreList.clear()
	showBad()
	show()
	timerGame.start()

signal clackToss

func _process(delta: float) -> void:
	if gameOn:
		if Input.is_action_just_pressed("click"):
			clackToss.emit()
			currTime = Time.get_ticks_msec() / 1000.0
			if firstTap:
				lastClickTime = currTime
			else:
				timeSinceLastClick = currTime - lastClickTime
				lastClickTime = currTime
				if (timeSinceLastClick > lowBound) and (timeSinceLastClick < highBound):
					speedState = 1 # 1 means just right
				else : if timeSinceLastClick > highBound: # takes longer than it should
					speedState = 0 # 0 means slow
				else : 
					speedState = 2 # 2 means fast
				print(speedState)
				scoreList.append(speedState)
			toss()

func toss():
	if firstTap:
		tossNormal.emit()
		firstTap = false
	match speedState:
		0:
			showBad()
			showSlow()
			#tossSlow.emit()
			tossNormal.emit()
		1:
			showGood()
			tossNormal.emit()
		2:
			showBad()
			showFast()
			tossFast.emit()
		
signal goodToss
signal badTossSlow # too many 0s
signal badTossFast # too many 2s

func _on_timeUp() -> void:
	gameOn = false
	var sum = 0
	var length = scoreList.size()
	for i in range(0, length):
		sum += scoreList[i]
	var avg = float(sum) / float(length)
	print(avg)
	if(avg > 0.9 and avg < 1.3):
		goodToss.emit()
	else: if (avg <=0.9) :
		badTossSlow.emit()
	else:
		badTossFast.emit()
	tossingDone.emit()
	hide()

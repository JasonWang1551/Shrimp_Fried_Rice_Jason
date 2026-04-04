extends Node2D
@onready var meter: Sprite2D = $meter
@onready var pointer: Sprite2D = $pointer
@onready var start: Marker2D = $start
@onready var safestart: Marker2D = $safestart
@onready var safeend: Marker2D = $safeend
@onready var end: Marker2D = $end
@onready var safezone: Sprite2D = $safezone

signal fireLit
signal fireFailed
signal QTEfail

signal clackQTE

var gameOn = false;
var success = false;
var gameNum = 0;
# 1 = fire starting game. QTE meter will be maintained
# 2 = salt game

# variables for fire game
var dir = -5

# variables for safezone randomization
var safeStartInit
var safeEndInit
var safezonesize

func randomizeSafeZone() -> void:
	safestart.position.y = randi_range(safeStartInit, end.position.y + safezonesize)
	safeend.position.y = safestart.position.y - safezonesize
	safezone.position.y = safestart.position.y - (safezonesize / 2)

func _ready():
	pointer.position.y = start.position.y
	pointer.position.x = start.position.x
	
func _on_startFireQTE() -> void:
	pointer.position.y = start.position.y
	pointer.position.x = start.position.x
	dir = -5
	gameNum = 1

func _on_startSaltGame() -> void:
	pointer.position.y = start.position.y
	pointer.position.x = start.position.x
	dir = -5
	gameNum = 2

signal saltSuccess
signal saltFailed

func _process(delta: float) -> void:
	if gameNum == 0:
		pass
	match gameNum:
		1: #light the fire!
			pointer.position.y += dir
			if pointer.position.y <= end.position.y:
				randomizeSafeZone()
				dir = 5
			if pointer.position.y >= start.position.y:
				randomizeSafeZone()
				dir = -5
			if Input.is_action_just_pressed("tap"):
				clackQTE.emit()
				if 	pointer.position.y < safestart.position.y and pointer.position.y > safeend.position.y :
					gameNum = 0
					fireLit.emit()
					print("ignited")
				else:
					fireFailed.emit()
		2:
			pointer.position.y += dir
			if pointer.position.y <= end.position.y:
				randomizeSafeZone()
				dir = 5
			if pointer.position.y >= start.position.y:
				randomizeSafeZone()
				dir = -5
			if Input.is_action_just_pressed("tap"):
				clackQTE.emit()
				gameNum = 0
				if 	pointer.position.y < safestart.position.y and pointer.position.y > safeend.position.y :
					saltSuccess.emit()
					print("salted")
				else:
					saltFailed.emit()


	#if pointer.position.y >= end.position.y and gameOn:
		#pointer.position.y -= 5
		#
	#if Input.is_action_just_pressed("tap") and gameOn:
		#print("tapped")
		#if 	pointer.position.y < safestart.position.y and pointer.position.y > safeend.position.y :
			#gameOn = false
			#QTEsuccess.emit()
			#print("success")
		#else :
			#gameOn = false
			#QTEfail.emit()
			#print("fail")
			#
	#if pointer.position.y <= end.position.y:
		#gameOn = false
		#QTEfail.emit
		#print("fail")

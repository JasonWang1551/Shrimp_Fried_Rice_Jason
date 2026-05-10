extends Node2D

@onready var QTEbar: Node2D = $QTEbar
@onready var Fire : AnimatedSprite2D = $Fire
@onready var Tosser: Node2D = $Tosser
@onready var wok : AnimatedSprite2D = $Wok
@onready var title : AnimatedSprite2D = $TitleScreen
@onready var saltCan : AnimatedSprite2D = $saltCan
@onready var shrimpHands : AnimatedSprite2D = $shrimpHands
@onready var controlIns : AnimatedSprite2D = $controlInstruct
@onready var AudioVictory : FmodEventEmitter2D = $FmodBankLoader/VictoryDialogueMusic
@onready var AudioDefeat : FmodEventEmitter2D = $FmodBankLoader/DefeatDialogueMusic
@onready var TitleAudio : FmodEventEmitter2D = $FmodBankLoader/TitleMusic
@onready var DialogueMusic : FmodEventEmitter2D = $FmodBankLoader/StartDialogueMusic
@onready var MinigameMusic : FmodEventEmitter2D = $FmodBankLoader/MinigameMusic
@onready var GordonDialogueSfx : FmodEventEmitter2D = $FmodBankLoader/GordonDialogueSfx
@onready var BossDialogueSfx : FmodEventEmitter2D = $FmodBankLoader/BossDialogueSfx
@onready var ShrimpDialogueSfx : FmodEventEmitter2D = $FmodBankLoader/ShrimpDialogueSfx
@onready var ShrimpHappySfx : FmodEventEmitter2D = $FmodBankLoader/ShrimpHappySfx
@onready var ShrimpSadSfx : FmodEventEmitter2D = $FmodBankLoader/ShrimpSadSfx
@onready var SaltSfx : FmodEventEmitter2D = $FmodBankLoader/SaltSfx
@onready var StoveOnSfx : FmodEventEmitter2D = $FmodBankLoader/StoveOnSfx
@onready var StoveLightingSfx : FmodEventEmitter2D = $FmodBankLoader/StoveLightingSfx

const FMOD_PASSING_NOT_ENOUGH := "NotEnough"
const FMOD_PASSING_NO := "No"
const FMOD_PASSING_YES := "Yes"
const FMOD_VICTORY_EVENT := "No"
const FMOD_VICTORY_DIALOGUE := "Yes"
const FMOD_VICTORY_PARAMETER_NAME := "InDialogue"
const FMOD_DEFEAT_EVENT := "No"
const FMOD_DEFEAT_DIALOGUE := "Yes"
const FMOD_DEFEAT_PARAMETER_NAME := "InDialogue"
const SHRIMP_HAPPY_TOSS_CHANCE := 5
const SHRIMP_SAD_TOSS_CHANCE := 2
const FMOD_DIALOGUE_SPEAKER_SETTINGS := {
	"gordon": {"parameter": "NumberSyllablesGordon"},
	"boss": {"parameter": "NumberSyllablesBoss"},
	"shrimp": {"parameter": "NumberSyllablesShrimp"}
}

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
	Tosser.liveTossStateChanged.connect(_on_live_toss_state_changed)
	Dialogic.signal_event.connect(_on_dialogic_signal_event)
	Dialogic.timeline_started.connect(_on_dialogic_timeline_started)
	Dialogic.Text.text_started.connect(_on_dialogic_text_started)
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
	_set_minigame_passing_parameter(FMOD_PASSING_NOT_ENOUGH)
	TitleAudio.play()
	
	QTEbar.safeStartInit = QTEbar.safestart.position.y
	QTEbar.safeEndInit = QTEbar.safeend.position.y
	QTEbar.safezonesize = QTEbar.safestart.position.y - QTEbar.safeend.position.y
	
	title.play("default")
	title.show()

func _on_dialogic_timeline_started() -> void:
	call_deferred("_disable_dialogic_type_sounds")

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
	_set_minigame_passing_parameter(FMOD_PASSING_NOT_ENOUGH)
	TitleAudio.stop()
	
	gordonStart()

func gordonStart():
	gordon = true
	DialogueMusic.play()
	Dialogic.timeline_ended.connect(gordonOver)
	Dialogic.start("timeline")
	
func gordonOver():
	DialogueMusic.stop()
	MinigameMusic.play()
	Dialogic.timeline_ended.disconnect(gordonOver)
	QTEbar.show()
	startFireQTE.emit()
	StoveLightingSfx.play()
	Fire.play("inactive")
	controlIns.show()
	controlIns.play("QTEinstructions")
	Fire.show()
	
func _on_fireLit() -> void:
	StoveLightingSfx.stop()
	StoveOnSfx.play()
	_play_shrimp_happy_reaction()
	QTEbar.hide()
	controlIns.play("tossingInstructions")
	startTossing.emit()

func _on_fireFailed() -> void:
	_play_shrimp_sad_reaction()

signal startSaltGame

func startSalt():
	controlIns.play("QTEinstructions")
	SaltSfx.play()
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
	_play_shrimp_sad_reaction()
	misses += 1
	saltDone()

func _on_QTEsaltSuccess() -> void:
	saltCan.play("success")
	_play_shrimp_happy_reaction()
	hits += 1
	saltDone()
	
func saltDone() :
	SaltSfx.stop()
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
		MinigameMusic.stop()
		StoveOnSfx.stop()
		if misses == 0:
			_set_victory_music_mode(FMOD_VICTORY_EVENT)
			AudioVictory.play()
			Dialogic.start("goodEnd")
		else:
			AudioDefeat.play()
			Dialogic.start("badEnd")
	


func _on_audio_victory_finished() -> void:
	TitleAudio.play()

func _on_live_toss_state_changed(click_count: int, score_count: int, average: float) -> void:
	if tossNum == 0 and click_count < 4:
		_set_minigame_passing_parameter(FMOD_PASSING_NOT_ENOUGH)
		return

	if _is_current_toss_passing(score_count, average):
		_set_minigame_passing_parameter(FMOD_PASSING_YES)
	else:
		_set_minigame_passing_parameter(FMOD_PASSING_NO)

func _is_current_toss_passing(score_count: int, average: float) -> bool:
	if misses > 0:
		return false

	if score_count == 0:
		return tossNum >= 1

	return average > 0.9 and average < 1.3

func _set_minigame_passing_parameter(value: String) -> void:
	if MinigameMusic["fmod_parameters/CurrentlyPassing"] == value:
		return
	MinigameMusic["fmod_parameters/CurrentlyPassing"] = value

func _on_badToss() -> void:
	if _roll_chance(SHRIMP_SAD_TOSS_CHANCE):
		_play_shrimp_sad_reaction()

func _on_dialogic_text_started(info: Dictionary) -> void:
	var character := info.get("character") as DialogicCharacter
	if character == null:
		_reset_dialogue_syllable_parameters("")
		return

	var speaker_key := character.get_identifier().to_lower()
	if not FMOD_DIALOGUE_SPEAKER_SETTINGS.has(speaker_key):
		speaker_key = character.display_name.to_lower()
	if not FMOD_DIALOGUE_SPEAKER_SETTINGS.has(speaker_key):
		_reset_dialogue_syllable_parameters("")
		return

	_reset_dialogue_syllable_parameters(speaker_key)

	var text := str(info.get("text", ""))
	var normalized_text := _normalize_dialogue_text(text)
	if normalized_text == "..." or normalized_text == "…":
		return

	var word_count := _count_dialogue_words(text)
	if word_count <= 0:
		return

	var emitter := _get_dialogue_emitter(speaker_key)
	if emitter == null:
		return

	var parameter_name: String = str(FMOD_DIALOGUE_SPEAKER_SETTINGS[speaker_key]["parameter"])
	var syllable_value := clampi(word_count, 2, 30)
	_set_numeric_fmod_parameter(emitter, parameter_name, syllable_value)
	emitter.play()

func _on_dialogic_signal_event(argument: Variant) -> void:
	if argument == "restartTheMusic":
		_set_victory_music_mode(FMOD_VICTORY_EVENT)
		AudioVictory.stop()
		AudioVictory.play()
	elif argument == "victoryDialogueOn":
		_set_victory_music_mode(FMOD_VICTORY_DIALOGUE)
	elif argument == "victoryDialogueOff":
		_set_victory_music_mode(FMOD_VICTORY_EVENT)
	elif argument == "defeatDialogueOn":
		_set_defeat_music_mode(FMOD_DEFEAT_DIALOGUE)
	elif argument == "defeatDialogueOff":
		_set_defeat_music_mode(FMOD_DEFEAT_EVENT)

func _set_victory_music_mode(value: String) -> void:
	if not _ensure_victory_music_parameter():
		return
	if AudioVictory["fmod_parameters/%s" % FMOD_VICTORY_PARAMETER_NAME] == value:
		return
	AudioVictory["fmod_parameters/%s" % FMOD_VICTORY_PARAMETER_NAME] = value

func _ensure_victory_music_parameter() -> bool:
	var parameter_path := "fmod_parameters/%s" % FMOD_VICTORY_PARAMETER_NAME
	var parameter_id_path := "%s/id" % parameter_path
	if AudioVictory.get(parameter_id_path) != null:
		return true

	var event_description: FmodEventDescription = FmodServer.get_event_from_guid(AudioVictory.event_guid)
	if event_description == null:
		event_description = FmodServer.get_event(AudioVictory.event_name)
	if event_description == null:
		return false

	for parameter: FmodParameterDescription in event_description.get_parameters():
		if parameter.get_name() != FMOD_VICTORY_PARAMETER_NAME:
			continue
		var parameter_id = parameter.get_id()
		AudioVictory[parameter_id_path] = parameter_id
		AudioVictory[parameter_path] = event_description.get_parameter_label_by_id(parameter_id, parameter.get_default_value())
		AudioVictory["%s/variant_type" % parameter_path] = TYPE_STRING
		AudioVictory["%s/labels" % parameter_path] = event_description.get_parameter_labels_by_id(parameter_id)
		return true

	return false

func _set_defeat_music_mode(value: String) -> void:
	if not _ensure_defeat_music_parameter():
		return
	if AudioDefeat["fmod_parameters/%s" % FMOD_DEFEAT_PARAMETER_NAME] == value:
		return
	AudioDefeat["fmod_parameters/%s" % FMOD_DEFEAT_PARAMETER_NAME] = value

func _ensure_defeat_music_parameter() -> bool:
	var parameter_path := "fmod_parameters/%s" % FMOD_DEFEAT_PARAMETER_NAME
	var parameter_id_path := "%s/id" % parameter_path
	if AudioDefeat.get(parameter_id_path) != null:
		return true

	var event_description: FmodEventDescription = FmodServer.get_event_from_guid(AudioDefeat.event_guid)
	if event_description == null:
		event_description = FmodServer.get_event(AudioDefeat.event_name)
	if event_description == null:
		return false

	for parameter: FmodParameterDescription in event_description.get_parameters():
		if parameter.get_name() != FMOD_DEFEAT_PARAMETER_NAME:
			continue
		var parameter_id = parameter.get_id()
		AudioDefeat[parameter_id_path] = parameter_id
		AudioDefeat[parameter_path] = event_description.get_parameter_label_by_id(parameter_id, parameter.get_default_value())
		AudioDefeat["%s/variant_type" % parameter_path] = TYPE_STRING
		AudioDefeat["%s/labels" % parameter_path] = event_description.get_parameter_labels_by_id(parameter_id)
		return true

	return false

func _disable_dialogic_type_sounds() -> void:
	for typing_sound in get_tree().get_nodes_in_group("dialogic_type_sounds"):
		typing_sound.enabled = false

func _count_dialogue_words(text: String) -> int:
	var without_tags := _normalize_dialogue_text(text)
	return without_tags.split(" ", false).size()

func _normalize_dialogue_text(text: String) -> String:
	return RegEx.create_from_string("\\[[^\\]]*\\]").sub(text, " ", true).strip_edges()

func _get_dialogue_emitter(speaker_key: String) -> FmodEventEmitter2D:
	match speaker_key:
		"gordon":
			return GordonDialogueSfx
		"boss":
			return BossDialogueSfx
		"shrimp":
			return ShrimpDialogueSfx
		_:
			return null

func _reset_dialogue_syllable_parameters(active_speaker_key: String) -> void:
	for speaker_key in FMOD_DIALOGUE_SPEAKER_SETTINGS.keys():
		if speaker_key == active_speaker_key:
			continue
		var emitter := _get_dialogue_emitter(speaker_key)
		if emitter == null:
			continue
		var parameter_name: String = str(FMOD_DIALOGUE_SPEAKER_SETTINGS[speaker_key]["parameter"])
		_set_numeric_fmod_parameter(emitter, parameter_name, 0)

func _set_numeric_fmod_parameter(emitter: FmodEventEmitter2D, parameter_name: String, value: int) -> void:
	if not _ensure_numeric_fmod_parameter(emitter, parameter_name):
		return
	emitter["fmod_parameters/%s" % parameter_name] = value

func _play_shrimp_happy_reaction() -> void:
	if ShrimpHappySfx != null:
		ShrimpHappySfx.play_one_shot()

func _play_shrimp_sad_reaction() -> void:
	if ShrimpSadSfx != null:
		ShrimpSadSfx.play_one_shot()

func _roll_chance(one_in: int) -> bool:
	if one_in <= 1:
		return true
	return randi_range(1, one_in) == 1

func _ensure_numeric_fmod_parameter(emitter: FmodEventEmitter2D, parameter_name: String) -> bool:
	var parameter_path := "fmod_parameters/%s" % parameter_name
	var parameter_id_path := "%s/id" % parameter_path
	if emitter.get(parameter_id_path) != null:
		return true

	var event_description: FmodEventDescription = FmodServer.get_event_from_guid(emitter.event_guid)
	if event_description == null:
		event_description = FmodServer.get_event(emitter.event_name)
	if event_description == null:
		return false

	for parameter: FmodParameterDescription in event_description.get_parameters():
		if parameter.get_name() != parameter_name:
			continue
		emitter[parameter_id_path] = parameter.get_id()
		emitter[parameter_path] = int(parameter.get_default_value())
		emitter["%s/variant_type" % parameter_path] = TYPE_INT
		return true

	return false

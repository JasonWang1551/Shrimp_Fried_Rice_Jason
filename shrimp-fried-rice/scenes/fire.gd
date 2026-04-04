extends AnimatedSprite2D

@onready var timer: Timer = $fireAnimTimer




func _on_fireLit() -> void:
	play("active fire")
	
func _on_fireFailed() -> void:
	timer.start()
	play("babyframe")

func _on_fireTimerTimeout() -> void:
	play("inactive")

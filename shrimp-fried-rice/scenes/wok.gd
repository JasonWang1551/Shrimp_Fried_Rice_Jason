extends AnimatedSprite2D

var riceStateLocal = 0
# 0 = undercooked
# 1 = good
# 2 = bad

func _on_tossNormal() -> void:
	match riceStateLocal:
		0:
			play("underCycleIdeal")
		1:
			play("tossCycleIdeal")
		2:
			play("overCycleIdeal")


func _on_tossFast() -> void:
	match riceStateLocal:
		0:
			play("underCycleFast")
		1:
			play("tossCycleFast")
		2:
			play("overCycleFast")


func _on_playRiceStill() -> void:
	match riceStateLocal:
		0:
			play("underStill")
		1:
			play("still")
		2:
			play("overStill")

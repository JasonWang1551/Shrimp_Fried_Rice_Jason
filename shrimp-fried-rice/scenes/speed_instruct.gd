extends AnimatedSprite2D



func _on_tosser_toss_slow() -> void:
	play("tooSlow")

func _on_tosser_toss_fast() -> void:
	play("tooFast")


func _on_tosser_toss_normal() -> void:
	play("nice")

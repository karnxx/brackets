extends Control

@onready var knife = $KNIFE


func doit(role):
	show()
	var tween = create_tween()
	$CenterContainer/VBoxContainer/Title.text = role
	if role == "intruder":
		pass
	tween.set_loops()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(
		knife,
		"scale",
		Vector2(3.7, 3.7),
		0.8
	)
	tween.tween_property(
		knife,
		"scale",
		Vector2(3.5, 3.5),
		0.8
	)
	await get_tree().create_timer(5.0).timeout
	tween.kill()
	hide()
	return

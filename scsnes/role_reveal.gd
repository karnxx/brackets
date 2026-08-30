extends Control

@onready var knife = $KNIFE


func doit(role):
	show()
	var tween = create_tween()
	$CenterContainer/VBoxContainer/RoleName.text = role
	if role == "intruder":
		$CenterContainer/VBoxContainer/Description.text = "Eliminate the Residents without being discovered"
	if role == "medic":
		$CenterContainer/VBoxContainer/Description.text = "Protect the Residents when danger strikes"
	if role == "resident":
		$CenterContainer/VBoxContainer/Description.text = "Survive the Night, Find the Intruder"
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

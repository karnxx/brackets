extends Node2D

# 1 = lights on
# 0 = lights off
var state = 1

@onready var darkness = $CanvasModulate
@onready var timer_label = $CanvasLayer/BlackoutTimer


func _ready():
	light_cycle()


func light_cycle():
	while true:
		state = 1
		darkness.color = Color.WHITE

		for i in range(10, 0, -1):
			timer_label.text = "LIGHTS\n00:%02d" % i

			if i <= 3:
				pulse_timer(true)
			else:
				pulse_timer(false)

			await get_tree().create_timer(1.0).timeout

		state = 0
		darkness.color = Color(0.08, 0.08, 0.08)

		for i in range(5, 0, -1):
			timer_label.text = "BLACKOUT\n00:%02d" % i

			if i <= 3:
				pulse_timer(true)
			else:
				pulse_timer(false)

			await get_tree().create_timer(1.0).timeout


func pulse_timer(urgent):
	var tween = create_tween()

	if urgent:
		timer_label.scale = Vector2(1.3, 1.3)
	else:
		timer_label.scale = Vector2(1.15, 1.15)

	tween.tween_property(timer_label, "scale", Vector2.ONE, 0.2)

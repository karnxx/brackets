extends Area2D

@export var interact_distance := 10

var mouse_over := false

func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func _on_mouse_entered() -> void:
	mouse_over = true
	$Sprite2D.frame = 1

func _on_mouse_exited() -> void:
	mouse_over = false
	$Sprite2D.frame = 0

func request_interaction() -> void:
	print("Requested interaction")
	# later


func interact() -> void:
	print("ACTUALLY INTERACTED")

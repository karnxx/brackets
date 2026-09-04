extends CharacterBody2D

@onready var sprite = $AnimatedSprite2D

var room = 0

var role
var namnam
var is_using = false
var shield = false
var ded = false

var killused := false
var medround := -2
var shieldused := false

var anima = "0"

var lastvote := -1

var chattime = 0.0

var footsteps = "n"

func _ready() -> void:
	$Label.text = namnam
	if not is_multiplayer_authority():
		$Camera2D.enabled = false

	else:
		$Camera2D.enabled = true
		set_camera_to_room()

@rpc("any_peer", "call_local", "unreliable")
func sync_state(pos: Vector2, anim: StringName, facing_left: bool, dead: bool):
	if is_multiplayer_authority():
		return
	global_position = pos
	ded = dead
	sprite.play((anima if ded == false else "0") + anim + ("" if ded else "1"))
	sprite.flip_h = facing_left

func am_i_dead() -> bool:
	for i in get_tree().get_nodes_in_group("plr"):
		if i.is_multiplayer_authority():
			return i.ded
	return false

func _process(_delta: float) -> void:
	var deda := am_i_dead()
	if footsteps == "n" and $AudioStreamPlayer.stream != preload("res://scsnes/freesound_community-footsteps-on-tile-31653-[AudioTrimmer.com].mp3"):
		$AudioStreamPlayer.stream = preload("res://scsnes/freesound_community-footsteps-on-tile-31653-[AudioTrimmer.com].mp3")
	elif footsteps == "b" and $AudioStreamPlayer.stream != preload("res://scsnes/freesound_community-jumpintopuddle-96895-[AudioTrimmer.com].mp3") :
		print("whodou")
		$AudioStreamPlayer.stream = preload("res://scsnes/freesound_community-jumpintopuddle-96895-[AudioTrimmer.com].mp3")
	if chattime > 0:
		chattime -= _delta
		if chattime <= 0:
			$chatlvl.hide()
	visible = not ded or deda
	if get_parent() is not Control:
		if get_parent().state == 1:
			$CanvasLayer/ColorRect.visible = false
			$CanvasLayer/ColorRect.color = Color(0, 0, 0, 0)
		else:
			$CanvasLayer/ColorRect.visible = true
			$CanvasLayer/ColorRect.color = Color(0, 0, 0, 1)

func _unhandled_input(event):
	if not is_multiplayer_authority():
		return
	if $CanvasLayer/TextEdit.visible:
		if event.is_action_pressed("chat"):
			chat_input()
			get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("interact"):
		interact()
	if event.is_action_pressed("chat"):
		$CanvasLayer/TextEdit.show()
		$CanvasLayer/TextEdit.grab_focus()

func play():
	if not $AudioStreamPlayer.playing:
		$AudioStreamPlayer.pitch_scale = randf_range(0.9, 1.1)
		$AudioStreamPlayer.play()

func chat_input():
	var message = $CanvasLayer/TextEdit.text.strip_edges()
	if message == "":
		$CanvasLayer/TextEdit.hide()
		return
	if multiplayer.is_server():
		get_parent().chatmessage(message)
	else:
		get_parent().chatmessage.rpc_id(1, message)
	$CanvasLayer/TextEdit.clear()
	$CanvasLayer/TextEdit.hide()

func _on_text_edit_gui_input(event):
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_ENTER:
			chat_input()
			$CanvasLayer/TextEdit.accept_event()

@rpc("authority", "call_local", "reliable")
func chatreceive(message):
	chatshow(message)

@rpc("authority", "call_local", "reliable")
func set_anim(d):
	anima = d

func interact():
	var item = get_hovered_item()
	if item == null:
		return
	if global_position.distance_to(item.global_position) > item.interact_distance:
		return
	item.request_interaction()

func get_hovered_item():
	for item in get_tree().get_nodes_in_group("inter"):
		if item.mouse_over:
			return item
	return null

func set_camera_to_room():
	var cam = $Camera2D
	var room_height = cam.limit_bottom - cam.limit_top
	var zoom_amount = 648.0 / room_height
	cam.zoom = Vector2(zoom_amount, zoom_amount)
	cam.global_position.y = (cam.limit_top + cam.limit_bottom) / 2.0

func _physics_process(_delta: float) -> void:
	if not is_multiplayer_authority():
		return
	if $CanvasLayer/TextEdit.has_focus():
		velocity = Vector2.ZERO
		return
	var dir := Vector2.ZERO
	if Input.is_action_pressed("move_left"):
		dir.x -= 1
	if Input.is_action_pressed("move_right"):
		dir.x += 1
	var anim := "idle"
	if dir != Vector2.ZERO:
		dir = dir.normalized()
		anim = "walk"
		if dir.x < 0:
			sprite.flip_h = true
		elif dir.x > 0:
			sprite.flip_h = false
	if get_parent() is not Control:
		if get_parent().state == 1:
			velocity = dir * 60
			if dir != Vector2.ZERO:
				play()
		else:
			velocity = Vector2.ZERO
	else:
		velocity = dir * 60
	move_and_slide()
	sprite.play((anima if ded == false else "0") + anim + ("" if ded else "1"))
	sync_state.rpc(
		global_position,
		anim,
		sprite.flip_h,
		ded
	)

func cleachoiuca():
	is_using = false
	for child in $CanvasLayer/VBoxContainer.get_children():
		child.hide()
		if child.name != "skip":
			child.queue_free()

@rpc("any_peer", "call_local", "reliable")
func carry_role():
	if not is_multiplayer_authority():
		return
	if role == "intruder":
		if killused:
			return
		is_using = true
		for i in get_tree().get_nodes_in_group("plr"):
			if i != self and i.ded == false:
				var bitun: Button = preload("res://scsnes/chooseb.tscn").instantiate()
				bitun.text = i.namnam
				bitun.pressed.connect(use.bind(i))
				$CanvasLayer/VBoxContainer.add_child(bitun)
	elif role == "medic":
		if get_parent().rnd - medround < 2:
			return
		is_using = true
		for i in get_tree().get_nodes_in_group("plr"):
			if i != self:
				var bitun: Button = preload("res://scsnes/chooseb.tscn").instantiate()
				bitun.text = i.namnam
				bitun.pressed.connect(use.bind(i))
				$CanvasLayer/VBoxContainer.add_child(bitun)

@rpc("any_peer", "call_local", "reliable")
func die(voting := false):
	if shield and not voting:
		set_shield.rpc(false)
		return
	ded = true
	if get_parent() is not Control:
		get_parent().bloodpile(self)

@rpc("any_peer", "call_local", "reliable")
func revive():
	ded = false
	set_shield.rpc(false)

@rpc("any_peer", "call_local", "reliable")
func start_vote():
	vote()

@rpc("any_peer", "call_local", "reliable")
func set_role(new_role: String):
	role = new_role

func use(bitun):
	if not is_using:
		return
	if not is_multiplayer_authority():
		return
	if not is_instance_valid(bitun):
		return
	var tid: int = bitun.get_multiplayer_authority()
	if role == "intruder":
		if killused:
			return
		if bitun.ded:
			return
		killused = true
		cleachoiuca()
		get_parent().subaction.rpc_id(1,"intruder",tid)
	elif role == "medic":
		if get_parent().rnd - medround < 2:
			return
		if bitun == self:
			return
		medround = get_parent().rnd
		cleachoiuca()
		get_parent().subaction.rpc_id(1,"medic",tid)

func chatshow(message):
	$chatlvl.text = message
	$chatlvl.show()
	await get_tree().process_frame
	$chatlvl.size.y = $chatlvl.get_combined_minimum_size().y
	chattime = 4.0

func skip_vote():
	if lastvote != -1:
		return
	lastvote = -2
	$CanvasLayer/VBoxContainer/skip.visible = false
	cleachoiuca()
	get_parent().skip.rpc_id(1)

@rpc("any_peer", "call_local", "reliable")
func set_shield(value: bool):
	if value:
		if shieldused:
			return
		shieldused = true
	shield = value

@rpc("any_peer", "call_local", "reliable")
func reset_kill_flag():
	killused = false

@rpc("any_peer", "call_local", "reliable")
func vote():
	lastvote = -1
	for i in get_tree().get_nodes_in_group("plr"):
		if i != self and not i.ded:
			var bitun: Button = preload("res://scsnes/chooseb.tscn").instantiate()
			bitun.text = i.namnam
			var target_id: int = i.get_multiplayer_authority()
			bitun.pressed.connect(add_vote.bind(target_id))
			$CanvasLayer/VBoxContainer.add_child(bitun)
	$CanvasLayer/VBoxContainer/skip.visible = true

func add_vote(target_id: int):
	if lastvote != -1:
		return
	lastvote = target_id
	$CanvasLayer/VBoxContainer/skip.visible = false
	for child in $CanvasLayer/VBoxContainer.get_children():
		if child.name != "skip":
			child.queue_free()
	get_parent().vota.rpc_id(1, target_id)

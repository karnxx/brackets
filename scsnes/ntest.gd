extends Control

@onready var ip_input: LineEdit = $LineEdit
@onready var port_input: LineEdit = $LineEdit2

func _on_join_pressed() -> void:
	var ip = ip_input.text.strip_edges()
	if ip == "":
		ip = "127.0.0.1"
	var port = NetworkManager.PORT
	if port_input.text.strip_edges() != "":
		port = int(port_input.text.strip_edges())
	NetworkManager.join_game(ip, port)

func _on_host_pressed() -> void:
	$CenterContainer/VBoxContainer/host.disabled = true
	NetworkManager.host_game()

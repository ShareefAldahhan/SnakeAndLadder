extends Control

@onready var status_label: Label = $LobbyID
@onready var ip_input: LineEdit = $IpInput

func _ready():
	# Safe signal connection
	if MultiplayerManager.lobby_joined.is_connected(_on_join_success):
		MultiplayerManager.lobby_joined.disconnect(_on_join_success)
	MultiplayerManager.lobby_joined.connect(_on_join_success)
	
	if MultiplayerManager.connection_failed.is_connected(_on_join_failed):
		MultiplayerManager.connection_failed.disconnect(_on_join_failed)
	MultiplayerManager.connection_failed.connect(_on_join_failed)

func _on_host_button_pressed():
	print("Creating Steam lobby...")
	MultiplayerManager.host_game()
	
	# Connect to the lobby_ready signal
	MultiplayerManager.lobby_ready.connect(
		func():
			print("Lobby ready, transitioning to lobby scene")
			get_tree().change_scene_to_file("res://scenes/lobby.tscn"),
		CONNECT_ONE_SHOT
	)
	
	# Also handle potential failures
	MultiplayerManager.connection_failed.connect(
		func(reason):
			print("Failed to create lobby: ", reason)
			$StatusLabel.text = "Failed: " + reason,
		CONNECT_ONE_SHOT
	)

func _on_join_button_pressed():
	if ip_input.text.is_empty():
		status_label.text = "Enter Lobby ID or IP"
		return
	
	status_label.text = "Joining..."
	MultiplayerManager.join_game(ip_input.text)

func _on_offline_button_pressed():
	GameManager.start_offline_game(2)
	get_tree().change_scene_to_file("res://scenes/game_board.tscn")

# Successful join callback
func _on_join_success(lobby_id: int):
	status_label.text = "Joined lobby %d" % lobby_id
	get_tree().change_scene_to_file("res://scenes/lobby.tscn")

# Failed join callback
func _on_join_failed(reason: String):
	status_label.text = "Failed: %s" % reason
	# Optional: Show retry button
	$RetryButton.show()

func _on_retry_button_pressed():
	$RetryButton.hide()
	_on_join_button_pressed()  # Retry the join

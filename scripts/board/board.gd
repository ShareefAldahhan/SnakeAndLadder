extends Node2D
@onready var dice_result: Label = $UI/DiceResult
@onready var turn_label: Label = $UI/TurnLabel
@onready var player: Player = $Player
@onready var roll_button: Button = $UI/RollButton

func _ready():
	# Get player list from Steam lobby if online
	if MultiplayerManager.ONLINE:
		var player_ids = []
		for member in MultiplayerManager.LOBBY_MEMBERS:
			player_ids.append(member['steam_id'])
			GameManager.setup_game(player_ids)
	else:
		# Fallback to offline mode
		GameManager.start_offline_game(2)  # Default 2 players
	# Initialize player tokens

	for player_id in GameManager.players:
		var player_scene = preload("res://scenes/player/player.tscn").instantiate()
		player_scene.player_id = player_id
		player_scene.name = str(player_id)
		player.add_child(player_scene)
	
	# Rest of your existing initialization
	GameManager.dice_rolled.connect(_on_dice_rolled)
	GameManager.player_turn_started.connect(_on_turn_changed)
	roll_button.pressed.connect(_on_roll_button_pressed)
	_on_turn_changed(GameManager.players[0])

func _on_roll_button_pressed():
	if GameManager.players[GameManager.current_player_index] == multiplayer.get_unique_id():
		GameManager.request_dice_roll.rpc_id(1)  # Send to server
	else:
		$UI/TurnLabel.text = "Wait your turn!"

func _on_dice_rolled(value: int):
	# Immediate dice result display
	dice_result.text = "Rolled: %d" % value
	# Optional: Simple visual feedback without animation
	dice_result.modulate = Color.GREEN
	await get_tree().create_timer(0.3).timeout
	dice_result.modulate = Color.WHITE
	# Proceed immediately to movement
	GameManager.move_current_player(value)

func get_player_node(player_id: int) -> Node:
	 # More reliable path finding
	return get_tree().get_root().find_child(str(player_id), true, false)

func move_player_to_tile(grid_pos: Vector2i):
	var tile_data = $TileMap.get_cell_tile_data(0, grid_pos)  # 0 = Layer index
	var target_pos_pixels = get_tile_center(grid_pos)
	
	# Check for teleport (snake/ladder)
	if tile_data and tile_data.get_custom_data("target_tile") != Vector2i(-1, -1):
		var target_tile = tile_data.get_custom_data("target_tile")
		target_pos_pixels = get_tile_center(target_tile)
		print("Teleporting to: ", target_tile)
	
	# Animate movement
	var tween = create_tween()
	tween.tween_property($Player, "position", target_pos_pixels, 0.5)

func get_tile_center(grid_pos: Vector2i) -> Vector2:
	return Vector2(
		grid_pos.x * 20 + 10,  # 20x20 tiles, center at (10,10)
		grid_pos.y * 20 + 10
	)

func _on_turn_changed(player_id: int):
	var player_name = "Player %d" % player_id
	if player_id == multiplayer.get_unique_id():
		turn_label.text = "Your Turn (%s)" % player_name
	else:
		turn_label.text = "%s's Turn" % player_name
		

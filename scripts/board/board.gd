extends Node2D
@onready var dice_result: Label = $UI/DiceResult
@onready var turn_label: Label = $UI/TurnLabel

func _ready():
	# Connect signals
	GameManager.dice_rolled.connect(_on_dice_rolled)
	GameManager.player_turn_started.connect(_on_turn_changed)
	
	# Initialize
	_on_turn_changed(GameManager.players[0])
	
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

func _on_dice_rolled(value: int):
	dice_result.text = "Rolled: %d" % value
	
	# Optional: Play dice animation
	$DiceAnimation.play("roll")

func _on_turn_changed(player_id: int):
	var player_name = "Player %d" % player_id
	if player_id == multiplayer.get_unique_id():
		turn_label.text = "Your Turn (%s)" % player_name
	else:
		turn_label.text = "%s's Turn" % player_name
		

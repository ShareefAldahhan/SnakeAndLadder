class_name Player
extends CharacterBody2D

@export var player_id := 0
var current_tile := Vector2i(0, 0)  # Grid position
var is_moving := false
const TILE_SIZE := 20

# Move to a specific grid tile (with snake/ladder checks)
@rpc("call_local")
func move_to_tile(target_tile: Vector2i):
	var board = get_parent().get_node("Grid")
	var tile_data = board.get_cell_tile_data(0, target_tile)
	
	# Check for snakes/ladders
	if tile_data and tile_data.get_meta("is_snake", false):
		target_tile = tile_data.get_meta("target_tile")
	elif tile_data and tile_data.get_meta("is_ladder", false):
		target_tile = tile_data.get_meta("target_tile")
	
	# Calculate world position (center of tile)
	var target_pos = Vector2(
		target_tile.x * TILE_SIZE + TILE_SIZE / 2,
		target_tile.y * TILE_SIZE + TILE_SIZE / 2
	)
	
	# Animate movement
	is_moving = true
	var tween = create_tween()
	tween.tween_property(self, "position", target_pos, 0.3)
	tween.tween_callback(func(): is_moving = false)
	current_tile = target_tile

func _physics_process(delta):
	if is_moving:
		move_and_slide()  # Apply physics while moving

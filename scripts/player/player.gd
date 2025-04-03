class_name Player
extends CharacterBody2D

@export var player_id := 0
var current_tile := Vector2i(0, 0)  # Grid position
var is_moving := false
const TILE_SIZE := 20

# Move to a specific grid tile (with snake/ladder checks)
#@rpc("call_local")
#func move_to_tile(target_tile: Vector2i):
	#var board = get_parent().get_node("TileMap")
	#var tile_data = board.get_cell_tile_data(0, target_tile)
	#
	## Check for special tiles (snakes/ladders)
	#if tile_data:
		#var teleport_target = tile_data.get_custom_data("target_tile")
		#if teleport_target != Vector2i(-1, -1):
			## Found a snake or ladder - move to target immediately
			#target_tile = teleport_target
			#print("Teleporting to: ", target_tile)
	#
	## Calculate world position (center of tile)
	#var target_pos = board.map_to_local(target_tile) + board.tile_set.tile_size / 2
	#
	## Animate movement
	#is_moving = true
	#var tween = create_tween()
	#tween.tween_property(self, "position", target_pos, 0.3)
	#tween.tween_callback(func(): 
		#is_moving = false
		#current_tile = target_tile
	#)

@rpc("call_local", "reliable")
func move_to_tile(target_tile: Vector2i):
	var board = get_parent().get_node("TileMap")
	position = board.map_to_local(target_tile)
	current_tile = target_tile
	
func _physics_process(delta):
	if is_moving:
		move_and_slide()  # Apply physics while moving

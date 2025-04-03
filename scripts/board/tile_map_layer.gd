extends TileMapLayer


# In your Board.gd
func get_tile_position(grid_pos: Vector2i) -> Vector2:
	return Vector2(
		grid_pos.x * 20 + 10,  # Center of tile
		grid_pos.y * 20 + 10
	)

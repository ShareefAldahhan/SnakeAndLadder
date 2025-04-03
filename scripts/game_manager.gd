extends Node

# Signals
signal player_turn_started(player_id: int)
signal player_moved(player_id: int, new_tile: Vector2i)
#signal turn_changed(player_id: int)        # Emit when turn changes
signal game_winner(player_id: int)
signal dice_rolled(value: int)

# Game State
var players := []           # Array of player IDs (peer IDs in multiplayer)
var current_player_index := 0
var current_dice_roll := 0
var board_size := 100       # Total tiles on the board (adjust if needed)

# Called when the game starts
@rpc("any_peer", "call_local", "reliable")
func setup_game(player_ids: Array):
	players = player_ids
	current_player_index = 0
	player_turn_started.emit(players[current_player_index])

@rpc("any_peer", "call_local", "reliable")
func request_dice_roll():
	if multiplayer.is_server():
		var sender_id = multiplayer.get_remote_sender_id()
		if sender_id == players[current_player_index]:
			# Server rolls and broadcasts
			current_dice_roll = randi() % 6 + 1
			dice_rolled.emit(current_dice_roll)
			
			# Wait for animation
			await get_tree().create_timer(1.0).timeout
			move_current_player(current_dice_roll)
		else:
			print("Not your turn! Current player: ", players[current_player_index])

@rpc("any_peer", "call_local", "reliable")
func player_finished_move(player_id: int):
	if player_id != players[current_player_index]:
		return

	current_player_index = (current_player_index + 1) % players.size()
	player_turn_started.emit(players[current_player_index])
	print("New turn: Player ", players[current_player_index])


## Server-authoritative dice roll
#@rpc("any_peer", "call_local", "reliable")
#func request_dice_roll():
	#if multiplayer.is_server():
		## Only allow the current player to roll
		#if multiplayer.get_remote_sender_id() == players[current_player_index]:
			#current_dice_roll = randi() % 6 + 1
			#dice_rolled.emit(current_dice_roll)
			#
			## Move player after a short delay (for animation)
			#await get_tree().create_timer(0.5).timeout
			#move_current_player(current_dice_roll)

func move_current_player(steps: int):
	var player_id = players[current_player_index]
	var player_node = get_player_node(player_id)
	
	# Immediate movement without animation delay
	player_node.rpc("move_to_tile", player_node.current_tile + steps)
	player_moved.emit(player_id, player_node.current_tile)
	
	# Short delay before next turn
	await get_tree().create_timer(0.5).timeout
	current_player_index = (current_player_index + 1) % players.size()
	player_turn_started.emit(players[current_player_index])
	
	
## Move player and check for snakes/ladders
#func move_current_player(steps: int):
	#var player_id = players[current_player_index]
	#var player_node = get_player_node(player_id)
	#var current_tile = player_node.current_tile
	#var new_tile = current_tile + steps
	#
	## Clamp to board size
	#if new_tile >= board_size:
		#new_tile = board_size - 1
		#game_winner.emit(player_id)  # Win condition
	#
	## Move player (handles snakes/ladders internally)
	#player_node.rpc("move_to_tile", new_tile)
	#player_moved.emit(player_id, new_tile)
	#
	## Advance turn
	#current_player_index = (current_player_index + 1) % players.size()
	player_turn_started.emit(players[current_player_index])

# Helper to find player nodes (adjust path as needed)
func get_player_node(player_id: int) -> Node:
	return get_tree().get_root().get_node("GameBoard/Players/%d" % player_id)

# Offline mode support
func start_offline_game(num_players: int):
	players = []
	for i in range(1, num_players + 1):
		players.append(i)  # Creates [1, 2, 3, ...]
	setup_game(players)

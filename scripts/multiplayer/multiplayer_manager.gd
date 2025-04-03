extends Node

# Steam Variables
var OWNED = false
var ONLINE = false
var STEAM_ID = 0
var STEAM_NAME = ""

# Lobby Variables
var LOBBY_ID = 0
var LOBBY_MEMBERS = []
var LOBBY_INVITE_ARG = false

# Game State Sync
var current_game_state := {}

func _ready():
	var INIT = Steam.steamInit()
	if INIT['status'] != 1:
		printerr("Steam init failed: ", INIT['verbal'])
		get_tree().quit()

	ONLINE = Steam.loggedOn()
	STEAM_ID = Steam.getSteamID()
	STEAM_NAME = Steam.getPersonaName()
	OWNED = Steam.isSubscribed()
	
	# Connect game signals
	GameManager.dice_rolled.connect(_on_dice_rolled)
	GameManager.player_moved.connect(_on_player_moved)

func _process(_delta):
	Steam.run_callbacks()
# Add this RPC method

#region Lobby Management
func _host_enet():
	var peer = ENetMultiplayerPeer.new()
	if peer.create_server(12345) == OK:
		multiplayer.multiplayer_peer = peer
		
		# Steam-specific setup
		if Steam.isSteamRunning():
			# Instead of IP, mark this as a Steam-hosted game
			Steam.setLobbyData(LOBBY_ID, "steam_host", "1")
			Steam.setLobbyData(LOBBY_ID, "host_id", str(Steam.getSteamID()))
			
			# Enable P2P session with lobby members
			for member in Steam.getNumLobbyMembers(LOBBY_ID):
				Steam.acceptP2PSessionWithUser(member)
		
		# Initialize game state
		current_game_state = {
			"players": [],
			"current_player": 0,
			"dice_value": 0,
			"steam_p2p": Steam.isSteamRunning() # Track connection type
		}

func _join_enet(ip: String):
	var peer = ENetMultiplayerPeer.new()
	if peer.create_client(ip, 12345) == OK:
		multiplayer.multiplayer_peer = peer

@rpc("call_local", "reliable")
func start_game():
	if multiplayer.is_server():
		get_tree().change_scene_to_file("res://scenes/board/Board.tscn")
#endregion

#region Gameplay Sync
@rpc("any_peer", "call_local", "reliable")
func request_dice_roll():
	if multiplayer.is_server():
		# Validate it's the current player's turn
		var sender_id = multiplayer.get_remote_sender_id()
		if sender_id == GameManager.players[GameManager.current_player_index]:
			var dice_value = randi() % 6 + 1
			_sync_dice_roll.rpc(dice_value)
			
			# Process movement after animation delay
			await get_tree().create_timer(0.8).timeout
			GameManager.move_current_player(dice_value)

@rpc("reliable")
func _sync_dice_roll(value: int):
	GameManager.dice_rolled.emit(value)

@rpc("reliable")
func _sync_player_position(player_id: int, tile_pos: Vector2i):
	# Find player node and update position
	var player = get_tree().get_root().get_node_or_null("Board/Players/%d" % player_id)
	if player:
		player.move_to_tile(tile_pos)

func _on_dice_rolled(value: int):
	current_game_state["dice_value"] = value
	# Additional dice roll handling if needed

func _on_player_moved(player_id: int, new_tile: Vector2i):
	_sync_player_position.rpc(player_id, new_tile)
	current_game_state["players"][player_id] = {"position": new_tile}
#endregion

#region Helper Functions
func _get_public_ip() -> String:
	if Steam.isSteamRunning():
		# Steam P2P doesn't expose IP addresses directly
		# Instead, we can use Steam ID for connections
		return str(Steam.getSteamID())
	return "local"  # For local/offline play

@rpc("reliable")
func sync_game_state(state: Dictionary):
	current_game_state = state
	# Update local game to match state
#endregion

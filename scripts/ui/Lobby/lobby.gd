extends Node2D

enum lobby_status {Private, Friends, Public, Invisible}
enum search_distance {Close, Default, Far, Worldwide}

@onready var steam_name: Label = $SteamName
@onready var lobby_set_name: Label = $Create/LobbySetName
@onready var lobbyoutput: RichTextLabel = $Chat/Lobbyoutput
@onready var chat_name: Label = $Chat/ChatName
@onready var popup_panel: Panel = $PopupPanel
@onready var lobby_list: VScrollBar = $PopupPanel/Scroll/VBox
@onready var player_count: Label = $Players/PlayerCount
@onready var player_list: RichTextLabel = $Players/PlayerList
@onready var chat_input: TextEdit = $Message/ChatInput
@onready var lobby_text: TextEdit = $Create/LobbyText

func _ready():
	#Set steam name on screen
	steam_name.text = MultiplayerManager.STEAM_NAME
	# Steamwork Connections
	Steam.connect("lobby_created", _on_Lobby_Created)
	Steam.connect("lobby_match_list", _on_Lobby_Match_List)
	Steam.connect("lobby_joined", _on_Lobby_Joined)
	Steam.connect("lobby_chat_update", _on_Lobby_Chat_Update)
	Steam.connect("lobby_message", _on_Lobby_Message)
	Steam.connect("lobby_data_update", _on_Lobby_Data_Update)
	Steam.connect("join_requested", _on_Lobby_Join_Requested)
	#check for command line arguments
	check_Command_Line()


#Self made functions
func create_Lobby():
	#check no other Lobby is running
	if MultiplayerManager.LOBBY_ID == 0:
		Steam.createLobby(lobby_status.Public, 4)
	

func get_Lobby_Members():
	# Clear previouse lobby members lits
	MultiplayerManager.LOBBY_MEMBERS.clear()
	
	# Get number of members in lobby
	var MEMBERCOUNT = Steam.getNumLobbyMembers(MultiplayerManager.LOBBY_ID)
	# Update player list count
	player_count.set_text("Players (" + str(MEMBERCOUNT) + ")")
	
	# Get members data
	for MEMBER in range(0, MEMBERCOUNT):
		# Members Steam ID
		var MEMBER_STEAM_ID = Steam.getLobbyMemberByIndex(MultiplayerManager.LOBBY_ID, MEMBER)
		# Members Steam Name
		var MEMBER_STEAM_NAME = Steam.getFriendPersonaName(MEMBER_STEAM_ID)
		# Add members to list
		add_Player_list(MEMBER_STEAM_ID, MEMBER_STEAM_NAME)

func add_Player_list(steam_id, steam_name):
	# Add players to list
	MultiplayerManager.LOBBY_MEMBERS.append({"steam_id":steam_id, "steam_name":steam_name})
	# Ensure list is cleared
	player_list.clear()
	# Populate player list
	for MEMBER in MultiplayerManager.LOBBY_MEMBERS:
		player_list.add_text(str(MEMBER['steam_name']) + "\n")

func send_Chat_Massage():
	# Get chat input
	var MESSAGE = chat_input.text
	# Pass message to steam
	var SENT = Steam.sendLobbyChatMsg(MultiplayerManager.LOBBY_ID, MESSAGE)
	# Check message sent
	if not SENT:
		display_Message("ERROR: Chat message failed to send")
	# Clear chat input
	chat_input.text = ""

func leave_Lobby():
	# if in a lobbym leave it
	if MultiplayerManager.LOBBY_ID != 0:
		display_Message("Leaving lobby...")
		# Send Steam leave requestd
		Steam.leaveLobby(MultiplayerManager.LOBBY_ID)
		# Wipe LOBBY_ID
		MultiplayerManager.LOBBY_ID = 0
		
		chat_name.text = "Lobby Name"
		player_count.text = "Players (0)"
		player_list.clear()
		
		# Close session with all users
		for MEMBERS in MultiplayerManager.LOBBY_MEMBERS:
			Steam.closeP2PSessionWithUser(MEMBERS['steam_id'])
		
		# Clear lobby list
		MultiplayerManager.LOBBY_MEMBERS.clear()


func display_Message(message):
	lobbyoutput.add_text("\n" + str(message))

func join_Lobby(lobbyID):
	popup_panel.hide()
	var name = Steam.getLobbyData(lobbyID, "name")
	display_Message("Joining lobby " + str(name) + "...")
	
	# Clear previouse lobby members lists
	MultiplayerManager.LOBBY_MEMBERS.clear()
	
	# Steam join request
	Steam.joinLobby(lobbyID)
	


###############################
####### Steam Callbacks #######
###############################
func _on_Lobby_Created(connect, lobbyID):
	if connect == 1:
		#Set Lobby ID
		MultiplayerManager.LOBBY_ID = lobbyID
		display_Message("created lobby: " + lobby_text.text)
		
		# SEt Lobby Data
		Steam.setLobbyData(lobbyID, "name", lobby_text.text)
		var name = Steam.getLobbyData(lobbyID, "name")
		chat_name.text = str(name)


#you can use it in the future
func _on_Lobby_Joined(lobbyID, permissions, locked, response):
	# Set lobby ID
	MultiplayerManager.LOBBY_ID = lobbyID
	
	# Get the lobby name
	var name = Steam.getLobbyData(lobbyID, "name")
	chat_name.text = str(name)
	
	# Get lobby members
	get_Lobby_Members()


func _on_Lobby_Join_Requested(lobbyID, friendID):
	# Get lobby owners name
	var OWNER_NAME = Steam.getFriendPersonaName(friendID)
	display_Message("Joining " + str(OWNER_NAME) + " lobby...")
	
	# Join lobby
	join_Lobby(lobbyID)


# when lobby metadata has changed
func _on_Lobby_Data_Update(success, lobbyID, memberID, key):
	print("Success: " + str(success) + ", Lobby ID: " + str(lobbyID) + ", Member ID: " + str(memberID) + ", Key: " + str(key))


func _on_Lobby_Chat_Update(lobbyID, changedID, makingChangeID, chatState):
	# User who made lobby change
	var CHANGER = Steam.getFriendPersonaName(makingChangeID)
	
	# chatState change made
	if chatState == 1:
		display_Message(str(CHANGER) + " has joined the lobby.")
	elif chatState == 2: 
		display_Message(str(CHANGER) + " has left the lobby.")
	elif chatState == 8: 
		display_Message(str(CHANGER) + " has been kicked from the lobby.")
	elif chatState == 16: 
		display_Message(str(CHANGER) + " has been bannedfrom the lobby.")
	else:
		display_Message(str(CHANGER) + " did... something.")

	# Update lobby
	get_Lobby_Members()

func _on_Lobby_Match_List(lobbies):
	for LOBBY in lobbies:
		# Grab desired lobby data
		var LOBBY_NAME = Steam.getLobbyData(LOBBY, "name")
		
		# Get the current number of members
		var LOBBY_MEMBERS = Steam.getNumLobbyMembers(LOBBY)
		
		# Crate button for each lobby
		var LOBBY_BUTTON = Button.new()
		LOBBY_BUTTON.set_text("Lobby " + str(LOBBY) + ": " +str(LOBBY_NAME) + " - [" + str(LOBBY_MEMBERS) + "] Player(s)")
		LOBBY_BUTTON.set_size(Vector2(800,50))
		LOBBY_BUTTON.set_name("lobby_" + str(LOBBY))
		LOBBY_BUTTON.connect("pressed", Callable(self, "join_Lobby").bind(LOBBY))

		# Add lobby to the list
		lobby_list.add_child(LOBBY_BUTTON)

func _on_Lobby_Message(result, user, message, type):
	# Sender and their message
	var SENDER = Steam.getFriendPersonaName(user)
	display_Message(str(SENDER) + ": " + str(message))


###############################
### Button Signal Functions ###
###############################
func _on_create_pressed() -> void:
	create_Lobby()


func _on_join_pressed() -> void:
	popup_panel.show()
	# Set server search distance to worldwide
	Steam.addRequestLobbyListDistanceFilter(search_distance.Worldwide)
	display_Message("Searchign for lobbies...")
	
	Steam.requestLobbyList()


func _on_start_pressed() -> void:
	pass # Replace with function body.


func _on_leave_pressed() -> void:
	leave_Lobby()


func _on_message_pressed() -> void:
	send_Chat_Massage()


func _on_close_pressed() -> void:
	popup_panel.hide()
























# Command Line Arguments

func check_Command_Line():
	var ARGUMENTS = OS.get_cmdline_args()
	
	#check if deteced arguments
	if ARGUMENTS.size() > 0:
		for argument in ARGUMENTS:
			# Invite argument passed
			if MultiplayerManager.LOBBY_INVITE_ARG:
				join_Lobby(int(argument))
				
				# Steam connection argument
				if argument == "connect_lobby":
					MultiplayerManager.LOBBY_INVITE_ARG = true

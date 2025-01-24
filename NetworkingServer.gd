extends Node
var multiplayer_peer = ENetMultiplayerPeer.new()


const PORT = 9010
const maxPlayers = 100
var connected_peer_ids = []
var matches = {}
var numGames = 0;
var curGame = 0;


func _ready():
	get_tree().set_multiplayer(multiplayer_peer, ^"/root/main")
	multiplayer_peer.create_server(PORT, maxPlayers)
	multiplayer.multiplayer_peer = multiplayer_peer
	multiplayer_peer.peer_connected.connect(_on_peer_connected)
	multiplayer_peer.peer_disconnected.connect(_on_peer_disconnected)
	print("Server is up and running.")

	
@rpc("any_peer")
func serverIsLegal(oppID, square, pieceInfo):
	rpc_id(oppID, "sendOppMove", square, pieceInfo)
	

@rpc("any_peer")
func createNewGame(userID, username):
	#add to matches data structure a new game and add this user to it 
	print("making new game for %s" %userID)
	print(userID)
	print(username)
	
	var curGameCode = 0
	curGameCode = randomCodeGen()		
	rpc_id(userID, "getCode", curGameCode)

	if randomPieceColor() == 0: #make the player the white pieces
		matches[curGameCode] = {"white" : userID, "whiteName" : username,  "black" : -1, "blackName" : -1}
	else: #make the player the black pieces
		matches[curGameCode] = {"white" : -1, "whiteName" : -1,  "black" : userID, "blackName" : username}
		
	rpc_id(userID, "startGame")


#called from second user looking to join the game
#sets up matches gameID dictionary
#passes opponents ids to eachother
@rpc("any_peer")
func joinGame(userID, gameCode, username):
	if matches.has(gameCode): #if there game code is valid
		print(matches[gameCode]["white"])
		print(matches[gameCode])
		if matches[gameCode]["white"] == -1: #if other user is black pieces make this one white pieces
			matches[gameCode]["white"] = userID
			matches[gameCode]["whiteName"] = username
			rpc_id(userID, "connectToOpp", matches[gameCode]["black"], matches[gameCode]["blackName"]) #swap IDs
			rpc_id(matches[gameCode]["black"], "connectToOpp", userID, username) #swap IDs
			rpc_id(userID, "isMyTurn", true)
			rpc_id(matches[gameCode]["black"], "isMyTurn", false)
					
		else: 
			if matches[gameCode]["black"] == -1:
				matches[gameCode]["black"] = userID		
				matches[gameCode]["blackName"] = username		
				rpc_id(userID, "connectToOpp", matches[gameCode]["white"], matches[gameCode]["whiteName"]) #swap IDs
				rpc_id(matches[gameCode]["white"], "connectToOpp", userID, username) #swap IDs
				rpc_id(userID, "isMyTurn", false)
				rpc_id(matches[gameCode]["white"], "isMyTurn", true)
				
		
		rpc_id(userID, "startGame")

		
		print(matches)
		
	else: 
		#send error message
		print("error game has not been created, check if you have the correct code")

	
@rpc("any_peer")
func leftGame(myID, gameID):
	#leave game tell opp that this user left the game
	if matches[gameID]["white"] == myID:
		if matches[gameID]["black"] != -1:
			rpc_id(matches[gameID]["black"], "oppDisconnected") #change to a left game message

	if matches[gameID]["black"] == myID:
		if matches[gameID]["white"] != -1:
			rpc_id(matches[gameID]["white"], "oppDisconnected")
		
	matches.erase(gameID)

#delete opp from match and inform opponent they left
func _on_peer_disconnected(leaving_peer_id : int) -> void:
	for match in matches.values():
		if match["white"] == leaving_peer_id:
			if match["black"] != -1:
				rpc_id(match["black"], "oppDisconnected")
			matches.erase(match)
					
		if match["black"] == leaving_peer_id:		
			if match["white"] != -1:
				rpc_id(match["white"], "oppDisconnected")
			matches.erase(match)
				
	
	print(matches)
	
func _on_peer_connected(new_peer_id : int) -> void:
	connected_peer_ids.append(new_peer_id)
	
func randomCodeGen() -> String:	 
	var numbers = "0123456789"
	var rng = RandomNumberGenerator.new()
	var code = ""
	for i in range(4):
		var random_let = rng.randi_range(0, 8)
		code += numbers[random_let]	
	return code


func randomPieceColor() -> int:	 
	var rng = RandomNumberGenerator.new()
	var randomVal = rng.randi_range(0, 1)
	return randomVal

	
@rpc
func oppDisconnected():
	pass
@rpc
func isMyTurn(_x):
	pass
	
@rpc
func sync_player_list(_updated_connected_peer_ids):
	pass # only implemented in client (but still has to exist here)

@rpc
func connectToOpp(_opponentId, _oppName):
	pass
	
	

@rpc("any_peer")
func sendOppMove(_oppID, _square, _piece):
	pass
	

	
@rpc("any_peer")
func getCode(_code):
	pass
	

	
@rpc("any_peer")
func startGame():
	pass
	


	
	
	

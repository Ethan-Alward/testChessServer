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

	

func _on_peer_connected(new_peer_id : int) -> void:
	connected_peer_ids.append(new_peer_id)
	


#func add_player(new_peer_id : int) -> void:
	#
	#if matches[numGames]["player1"] == 0:
		#matches[numGames]["player1"] = new_peer_id
		#matches[numGames]["piecePositions"][new_peer_id] = matches[numGames]["piecePositions"][0]
		#matches[numGames]["piecePositions"].erase(0)
		#
		##rpc_id(new_peer_id, "connectToOpp", "helpppp") #send player1 id to player2 
	#
		#
	#else: if matches[numGames]["player2"] == 0:
		#matches[numGames]["player2"] = new_peer_id
		#matches[numGames]["piecePositions"][new_peer_id] = matches[numGames]["piecePositions"][1]
		#matches[numGames]["piecePositions"].erase(1)
		##tell players the id of the user they are playing against
		#print("about to send who they're playing")
		#rpc_id(matches[numGames]["player1"], "connectToOpp", new_peer_id, numGames) #send player2 id to player1 
		#rpc_id(new_peer_id, "connectToOpp", matches[numGames]["player1"], numGames) #send player1 id to player2 
		#
		#rpc_id(matches[numGames]["player1"], "isMyTurn", true)
		#rpc_id(matches[numGames]["player2"], "isMyTurn", false)
		##
		#print("should be sent")
		#numGames = numGames + 1
	#
	##print(matches)
	#print("Player " + str(new_peer_id) + " joined.")
	#print("Currently connected Players: " + str(connected_peer_ids))
	##rpc("sync_player_list", connected_peer_ids)
	

@rpc("any_peer")
func createNewGame(userID):
	#add to matches data structure a new game and add this user to it 
	print("making new game for %s" %userID)
	print(userID)
	
	var curGameCode = 0
	curGameCode = randomCodeGen()		
	rpc_id(userID, "getCode", curGameCode)

	if randomPieceColor() == 0: #make the player the white pieces
		matches[curGameCode] = {"white" : userID, "black" : -1}
	else: #make the player the black pieces
		matches[curGameCode] = {"white" : -1, "black" : userID}
		
	rpc_id(userID, "startGame")


#called from second user looking to join the game
#sets up matches gameID dictionary
#passes opponents ids to eachother
@rpc("any_peer")
func joinGame(userID, gameCode):
	if matches.has(gameCode): #if there game code is valid
		print(matches[gameCode]["white"])
		print(matches[gameCode])
		if matches[gameCode]["white"] == -1: #if other user is black pieces make this one white pieces
			matches[gameCode]["white"] = userID
			rpc_id(userID, "connectToOpp", matches[gameCode]["black"]) #swap IDs
			rpc_id(matches[gameCode]["black"], "connectToOpp", userID) #swap IDs
			rpc_id(userID, "isMyTurn", true)
			rpc_id(matches[gameCode]["black"], "isMyTurn", false)
					
		else: 
			if matches[gameCode]["black"] == -1:
				matches[gameCode]["black"] = userID				
				rpc_id(userID, "connectToOpp", matches[gameCode]["white"]) #swap IDs
				rpc_id(matches[gameCode]["white"], "connectToOpp", userID) #swap IDs
				rpc_id(userID, "isMyTurn", false)
				rpc_id(matches[gameCode]["white"], "isMyTurn", true)
				
		
		rpc_id(userID, "startGame")

		
		print(matches)
		
	else: 
		#send error message
		print("error game has not been created, check if you have the correct code")


func _on_peer_disconnected(leaving_peer_id : int) -> void:
	# The disconnect signal fires before the client is removed from the connected
	# clients in multiplayer.get_peers(), so we wiait for a moment.
	#await get_tree().create_timer(1).timeout 
	
	for match in matches.values():

		if match["white"] == leaving_peer_id:
			# delete match and send opponent error message
			rpc_id(match["black"], "oppDisconnected")
			matches.erase(match)
					
		if match["black"] == leaving_peer_id:
			rpc_id(match["white"], "oppDisconnected")
			matches.erase(match)
	
	#remove_player(leaving_peer_id)

	print(matches)
#find opponent, tell them we lost connection with other player
#make them go back to homescreen
#remove game from matches 
#func remove_player(leaving_peer_id : int) -> void:	
	#var unDisconnectedPlayer = 0
	#
	##remove userID from list of connected peers
	#var peer_idx_in_peer_list : int = connected_peer_ids.find(leaving_peer_id)
	#if peer_idx_in_peer_list != -1:
		#connected_peer_ids.remove_at(peer_idx_in_peer_list)
		##end the game and give the id that's left in the game he win
		#
		#
	#
	#for game in matches: 
		#if matches[game]["player1"] == leaving_peer_id:
			#unDisconnectedPlayer = matches[game]["player2"]
			#rpc_id(unDisconnectedPlayer, "disconnectToOpp",leaving_peer_id) #send player1 id to player2 			
			#connected_peer_ids.remove_at(unDisconnectedPlayer)
			#matches.erase(game) 
			#break;
		#else: if matches[game]["player2"] == leaving_peer_id:
			#unDisconnectedPlayer = matches[game]["player1"]
			#rpc_id(unDisconnectedPlayer, "disconnectToOpp", leaving_peer_id) #send player2 id to player1 
			##connected_peer_ids.remove_at(unDisconnectedPlayer)
			#matches.erase(game)
			#break;
#
	#print(matches)
	#print("Player " + str(leaving_peer_id) + " disconnected.")	
	#if unDisconnectedPlayer != 0:
		#print("Player " + str(unDisconnectedPlayer) + " also disconnected.")
	
	
	
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
func connectToOpp(_opponentId):
	pass
	
	
@rpc("any_peer")
func serverIsLegal(oppID, square, pieceInfo):
	rpc_id(oppID, "sendOppMove", square, pieceInfo)
	
@rpc("any_peer")
func sendOppMove(_oppID, _square, _piece):
	pass
	
	
@rpc("any_peer")
func getCode(_code):
	pass
	

	
@rpc("any_peer")
func startGame():
	pass
	
func randomCodeGen() -> String:	 
	var alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
	var rng = RandomNumberGenerator.new()
	var code = ""
	for i in range(4):
		var random_let = rng.randi_range(0, 25)
		code += alphabet[random_let]	
	return code


func randomPieceColor() -> int:	 
	var rng = RandomNumberGenerator.new()
	var randomVal = rng.randi_range(0, 1)
	return randomVal


	
	
	

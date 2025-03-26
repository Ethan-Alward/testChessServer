extends Node
var multiplayer_peer = ENetMultiplayerPeer.new()
#var multiplayer_peer = WebSocketMultiplayerPeer.new()



const PORT = 9010
var connected_peer_ids = []
var matches = {}
var numGames = 0;
var curGame = 0;
var curGameID

func _ready():
	get_tree().set_multiplayer(multiplayer_peer, ^"/root/main")
	multiplayer_peer.create_server(PORT)
	multiplayer.multiplayer_peer = multiplayer_peer
	multiplayer_peer.peer_connected.connect(_on_peer_connected)
	multiplayer_peer.peer_disconnected.connect(_on_peer_disconnected)
	print("Server is up and running.")


#-------------------------------------------------------
#making a game
@rpc("any_peer")
func createNewGame(userID, username, time, gameType):
	#add to matches data structure a new game and add this user to it 
	var curGameCode = 0
	curGameCode = randomCodeGen()
	rpc_id(userID, "getCode", curGameCode)

	if randomPieceColor() == 0: #make the player the white pieces
		matches[curGameCode] = {"white" : userID, "whiteName" : username,  "black" : -1, "blackName" : -1, "time": time, "gameType" : gameType}
	else: #make the player the black pieces
		matches[curGameCode] = {"white" : -1, "whiteName" : -1,  "black" : userID, "blackName" : username, "time": time, "gameType" : gameType}
	
	print("-----------------------------------------------")
	print("%s Started a New Game" %str(username))	
	print("Connected Players: %s" %str(connected_peer_ids.size()))
	print("-----------------------------------------------")
	rpc_id(userID, "loadingScreen")

@rpc("any_peer")
func joinGame(userID, gameCode, username, _wantsToWatch):
	if matches.has(gameCode): #if there game code is valid
		if matches[gameCode]["white"] != -1 and matches[gameCode]["black"] != -1: 
			rpc_id(userID, "invalidJoinGame", 1) #send 1 if the game is being played
			
		else:
			if matches[gameCode]["white"] == -1: #if other user is black pieces make this one white pieces
				matches[gameCode]["white"] = userID
				matches[gameCode]["whiteName"] = username
				
				print("-----------------------------------------------")
				print(str(username) + " is now playing against " + str(matches[gameCode]["blackName"]) + " in a " + str(matches[gameCode]["gameType"]) + " game")
				print("Active Games: %s" %str(matches.size()))
				print("Connected Players: %s" %str(connected_peer_ids.size()))
				print("-----------------------------------------------")
				
				rpc_id(userID, "connectToOpp", matches[gameCode]["black"], matches[gameCode]["blackName"]) #swap IDs
				rpc_id(matches[gameCode]["black"], "connectToOpp", userID, username) #swap IDs
				rpc_id(userID, "startGame", matches[gameCode]["gameType"])
				rpc_id(matches[gameCode]["black"], "startGame",  matches[gameCode]["gameType"])
				rpc_id(userID,"recieveTime", matches[gameCode]["time"])
				rpc_id(userID, "isMyTurn", true)
				rpc_id(matches[gameCode]["black"], "isMyTurn", false)

					
			else: 
				if matches[gameCode]["black"] == -1:
					matches[gameCode]["black"] = userID		
					matches[gameCode]["blackName"] = username
					
					print("-----------------------------------------------")
					print(str(username) + " is now playing against " + str(matches[gameCode]["whiteName"]) + " in a " + str(matches[gameCode]["gameType"]) + " game")
					print("Active Games: %s" %str(matches.size()))
					print("Connected Players: %s" %str(connected_peer_ids.size()))
					print("-----------------------------------------------")
											
					rpc_id(userID, "connectToOpp", matches[gameCode]["white"], matches[gameCode]["whiteName"]) #swap IDs
					rpc_id(matches[gameCode]["white"], "connectToOpp", userID, username) #swap IDs
					rpc_id(userID, "startGame",  matches[gameCode]["gameType"])		
					rpc_id(matches[gameCode]["white"], "startGame",  matches[gameCode]["gameType"])	
					rpc_id(userID,"recieveTime", matches[gameCode]["time"])							
					rpc_id(userID, "isMyTurn", false)
					rpc_id(matches[gameCode]["white"], "isMyTurn", true)		
		
	else: 
		#send error message
		rpc_id(userID, "invalidJoinGame", 0) #send a 0 if the game is not found

#----------------------------------------------------
#pass data between opps
@rpc("any_peer")
func serverIsLegal(oppID, square, pieceInfo):
	rpc_id(oppID, "sendOppMove", square, pieceInfo)

@rpc("any_peer")
func serverBoardMoveIsLegal(oppID, oldBoard, newBoard):
	rpc_id(oppID, "sendOppBoardMove", oldBoard, newBoard)

@rpc("any_peer")
func sendText(text, myID, gameID):	
	if matches[gameID]["white"] == myID:
		if matches[gameID]["black"] != -1:
			rpc_id(matches[gameID]["black"], "receiveText", text)

	if matches[gameID]["black"] == myID:
		if matches[gameID]["white"] != -1:
			rpc_id(matches[gameID]["white"], "receiveText", text)

@rpc("any_peer")
func sendOppStalemate(myID, gameID):
	if matches.has(gameID): 
		if matches[gameID]["white"] == myID:
			if matches[gameID]["black"] != -1:
				print("-----------------------------------------------")
				print(str(matches[gameID]["blackName"]) + " just stalemated " + str(matches[gameID]["whiteName"]) + " in a " + str(matches[gameID]["gameType"]) + " game")
				rpc_id(matches[gameID]["black"], "sendOppStalemate") #change to a left game message

		if matches[gameID]["black"] == myID:
			if matches[gameID]["white"] != -1:
				print("-----------------------------------------------")
				print(str(matches[gameID]["whiteName"]) + " just stalemated " + str(matches[gameID]["blackName"]) + " in a " + str(matches[gameID]["gameType"]) + " game")

				rpc_id(matches[gameID]["white"], "sendOppStalemate")	
		
		matches.erase(gameID)
		print("Active Games: %s" %str(matches.size()))
		print("Connected Players: %s" %str(connected_peer_ids.size()))
		print("-----------------------------------------------")
		

@rpc("any_peer")
func sendOppTheyWon(myID, gameID):
	if matches.has(gameID): 
		if matches[gameID]["white"] == myID:
			if matches[gameID]["black"] != -1:
				print("-----------------------------------------------")
				print(str(matches[gameID]["blackName"]) + " just beat " + str(matches[gameID]["whiteName"]) + " in a " + str(matches[gameID]["gameType"]) + " game")
				rpc_id(matches[gameID]["black"], "sendOppTheyWon") #change to a left game message

		if matches[gameID]["black"] == myID:
			if matches[gameID]["white"] != -1:
				print("-----------------------------------------------")
				print(str(matches[gameID]["whiteName"]) + " just beat " + str(matches[gameID]["blackName"]) + " in a " + str(matches[gameID]["gameType"]) + " game")

				rpc_id(matches[gameID]["white"], "sendOppTheyWon")	
		
		matches.erase(gameID)
		print("Active Games: %s" %str(matches.size()))
		print("Connected Players: %s" %str(connected_peer_ids.size()))
		print("-----------------------------------------------")
		

#-------------------------------------------------------------
#peer connection handling

func _on_peer_disconnected(leaving_peer_id : int) -> void:
	for match in matches.values():
		if match["white"] == leaving_peer_id:
			if match["black"] != -1:
				rpc_id(match["black"], "oppDisconnected")
				
			matches.erase(matches.find_key(match))

		if match["black"] == leaving_peer_id:		
			if match["white"] != -1:
				rpc_id(match["white"], "oppDisconnected")
				
			matches.erase(matches.find_key(match))

	connected_peer_ids.erase(leaving_peer_id)

func _on_peer_connected(new_peer_id : int) -> void:
	connected_peer_ids.append(new_peer_id)


@rpc("any_peer")
func leftGame(myID, gameID):	
	
	if matches.has(gameID): 
		if matches[gameID]["white"] == myID:
			if matches[gameID]["black"] != -1:
				print("-----------------------------------------------")
				print(str(matches[gameID]["whiteName"]) + " just left the game with " + str(matches[gameID]["blackName"]))				
				rpc_id(matches[gameID]["black"], "oppDisconnected") 

		if matches[gameID]["black"] == myID:
			if matches[gameID]["white"] != -1:
				print("-----------------------------------------------")
				print(str(matches[gameID]["blackName"]) + " just left the game with " + str(matches[gameID]["whiteName"]))
				rpc_id(matches[gameID]["white"], "oppDisconnected")
		matches.erase(gameID)
		print("Active Games: %s" %str(matches.size()))
		print("Connected Players: %s" %str(connected_peer_ids.size()))
		print("-----------------------------------------------")

#------------------------------------------------------------
#server value generators
func randomCodeGen():	 
	var rng = RandomNumberGenerator.new()		
	var intCode = rng.randi_range(1000,9999)
	return intCode

func randomPieceColor() -> int:	 
	var rng = RandomNumberGenerator.new()
	var randomVal = rng.randi_range(0, 1)
	return randomVal

#------------------------------------------------------------
# rpcs only needed clientSide
@rpc("any_peer")
func oppDisconnected():
	pass
@rpc("any_peer")
func isMyTurn(_x):
	pass
@rpc("any_peer")
func sync_player_list(_updated_connected_peer_ids):
	pass 
@rpc("any_peer")
func connectToOpp(_opponentId, _oppName):
	pass
@rpc("any_peer")
func sendOppMove(_oppID, _square, _piece):
	pass
@rpc("any_peer")
func sendOppBoardMove(_oldBoard, _newBoard):
	pass
@rpc("any_peer")
func invalidJoinGame():
	pass
@rpc("any_peer")
func getCode(_code):
	pass
@rpc("any_peer")
func loadingScreen():
	pass
@rpc("any_peer")
func receiveText(_text):
	pass
@rpc("any_peer")
func startGame(_gameType):
	pass
@rpc("any_peer")
func recieveTime(_time):
	pass

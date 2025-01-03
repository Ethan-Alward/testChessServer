extends Node
var multiplayer_peer = ENetMultiplayerPeer.new()



#var url : String = "your-prod.url"
const PORT = 9010

var connected_peer_ids = []
var matches = {}
var numGames = 0;
var curGame = 0;


func _ready():
	#var url = "192.168.2.27"
	get_tree().set_multiplayer(multiplayer_peer, ^"/root/main")
	multiplayer_peer.create_server(PORT)
	multiplayer.multiplayer_peer = multiplayer_peer
	multiplayer_peer.peer_connected.connect(_on_peer_connected)
	multiplayer_peer.peer_disconnected.connect(_on_peer_disconnected)
	#if OS.has_feature("dedicated_server"):
		#print("Ethan starting server")
		#multiplayer_peer.become_host()
		#print("test")
	print("Server is up and running.")


func _on_peer_connected(new_peer_id : int) -> void:
	print("Player " + str(new_peer_id) + " is joining...")
	# The connect signal fires before the client is added to the connected
	# clients in multiplayer.get_peers(), so we wait for a moment.
	await get_tree().create_timer(1).timeout
	add_player(new_peer_id)


func add_player(new_peer_id : int) -> void:
	connected_peer_ids.append(new_peer_id)	
	
	if !matches.has(numGames):
		matches[numGames] = {"player1": 0,
							 "player2": 0,
							 "game_state": {'is_white_turn': true,	'selected_piece': null}, #may not need is white
							 "piecePositions": {0:{'a2' : {'type': PIECE_TYPE.pawn,'square': { 'column':'a', 'row':2 },'is_white': true},
												   'b2' : {'type': PIECE_TYPE.pawn,'square': { 'column':'b', 'row':2 },'is_white': true},
												   'c2' : {'type': PIECE_TYPE.pawn,'square': { 'column':'c', 'row':2 },'is_white': true},
												   'd2' : {'type': PIECE_TYPE.pawn,'square': { 'column':'d', 'row':2 },'is_white': true},
												   'e2' : {'type': PIECE_TYPE.pawn,'square': { 'column':'e', 'row':2 },'is_white': true},
												   'f2' : {'type': PIECE_TYPE.pawn,'square': { 'column':'f', 'row':2 },'is_white': true},
												   'g2' : {'type': PIECE_TYPE.pawn,'square': { 'column':'g', 'row':2 },'is_white': true},
												   'h2' : {'type': PIECE_TYPE.pawn,'square': { 'column':'h', 'row':2 },'is_white': true},		
												   'b1' : {'type': PIECE_TYPE.knight,'square': { 'column':'b', 'row':1 },'is_white': true},
												   'g1' : {'type': PIECE_TYPE.knight,'square': { 'column':'g', 'row':1 },'is_white': true}
													},
												1:{'a7' : {'type': PIECE_TYPE.pawn,'square': { 'column':'a', 'row':7 },'is_white': false},
												   'b7' : {'type': PIECE_TYPE.pawn,'square': { 'column':'b', 'row':7 },'is_white': false},
												   'c7' : {'type': PIECE_TYPE.pawn,'square': { 'column':'c', 'row':7 },'is_white': false},
												   'd7' : {'type': PIECE_TYPE.pawn,'square': { 'column':'d', 'row':7 },'is_white': false},
												   'e7' : {'type': PIECE_TYPE.pawn,'square': { 'column':'e', 'row':7 },'is_white': false},
												   'f7' : {'type': PIECE_TYPE.pawn,'square': { 'column':'f', 'row':7 },'is_white': false},
												   'g7' : {'type': PIECE_TYPE.pawn,'square': { 'column':'g', 'row':7 },'is_white': false},
												   'h7' : {'type': PIECE_TYPE.pawn,'square': { 'column':'h', 'row':7 },'is_white': false},
												   'b8' : {'type': PIECE_TYPE.knight,'square': { 'column':'b', 'row':8 },'is_white': false},
												   'g8' : {'type': PIECE_TYPE.knight,'square': { 'column':'g', 'row':8 },'is_white': false}
												
												}},
							 "time": 0}
	
	if matches[numGames]["player1"] == 0:
		matches[numGames]["player1"] = new_peer_id
		matches[numGames]["piecePositions"][new_peer_id] = matches[numGames]["piecePositions"][0]
		matches[numGames]["piecePositions"].erase(0)
		
		#rpc_id(new_peer_id, "connectToOpp", "helpppp") #send player1 id to player2 
	
		
	else: if matches[numGames]["player2"] == 0:
		matches[numGames]["player2"] = new_peer_id
		matches[numGames]["piecePositions"][new_peer_id] = matches[numGames]["piecePositions"][1]
		matches[numGames]["piecePositions"].erase(1)
		#tell players the id of the user they are playing against
		print("about to send who they're playing")
		rpc_id(matches[numGames]["player1"], "connectToOpp", new_peer_id, numGames) #send player2 id to player1 
		rpc_id(new_peer_id, "connectToOpp", matches[numGames]["player1"], numGames) #send player1 id to player2 
		
		rpc_id(matches[numGames]["player1"], "isMyTurn", true)
		rpc_id(matches[numGames]["player2"], "isMyTurn", false)
		#
		print("should be sent")
		numGames = numGames + 1
	
	#print(matches)
	print("Player " + str(new_peer_id) + " joined.")
	print("Currently connected Players: " + str(connected_peer_ids))
	#rpc("sync_player_list", connected_peer_ids)
	
	
@rpc("any_peer")
func serverIsLegal(oppID, square, pieceInfo):
	print("testtt ", oppID, square, pieceInfo)
	rpc_id(oppID, "sendOppMove", square, pieceInfo)
	
@rpc("any_peer")
func sendOppMove(_oppID, _square, _piece):
	pass
	#
#@rpc("any_peer")
#func serverIsLegalMove(gameId, userId, oppId,  squareIWannaGo, pieceIWannaMove):
	#print(gameId, userId, "		", squareIWannaGo, "	", pieceIWannaMove)
	##check if move is legal 
	#print(pieceIWannaMove)
	#var pieceName = pieceIWannaMove["name"]
	#print(pieceName)
	#print(matches[gameId]["piecePositions"][userId])
	#print(matches[gameId]["piecePositions"][userId][pieceName])
	#var serverPieceInfo = matches[gameId]["piecePositions"][userId].get(pieceName)
	#print(serverPieceInfo)
	#print(pieceName)
	#print(serverPieceInfo)
	#if serverPieceInfo["type"] == 0: #it's a pawn
		#if pawnMoveIsLegal(squareIWannaGo, serverPieceInfo, gameId, userId, oppId, pieceName):
			#updatePiecePositions(squareIWannaGo, serverPieceInfo, gameId, userId, oppId, pieceName)
			#rpc_id(userId, "client_is_legal", true)
			##also end the move to the opposing player
			#var opponentID = 0
			#if matches[gameId]["player1"] == userId:
				#opponentID = matches[gameId]["player2"]
			#else: 
				#opponentID = matches[gameId]["player1"]
				#
			#rpc_id(opponentID, "updateOnOppMove", squareIWannaGo, pieceIWannaMove)
		#else: 
			#return false

func updatePiecePositions(squareIWannaGo, serverPieceInfo, gameId, userId, oppId, pieceName):
	print("update the pieces on the server dictionary")
	print(matches[gameId]['piecePositions'][userId][pieceName]["square"])
	matches[gameId]['piecePositions'][userId][pieceName]["square"] = squareIWannaGo
	print(matches[gameId]['piecePositions'][userId][pieceName]["square"])
	pass
			
			
func pawnMoveIsLegal(squareIWannaGo, serverPieceInfo, gameId, userId, oppId, pieceName): 
	#print(squareIWannaGo)
	#print(serverPieceInfo)
	#make a dictionary of squares that are legal moves for a pawn on e2 from serverPieceInfo

	var direction = 1
	if !serverPieceInfo["is_white"]:
		direction = -1
	var col = serverPieceInfo["square"]["column"]
	var r = serverPieceInfo["square"]["row"]
	var squares = []
	# the square in front of the pawn
	var notation = { 'column':col, 'row':r+direction }
		#check if there's a piece on that square
	var piece = check_square(notation,gameId, userId, oppId)
	if !piece:
		squares.push_front(notation)
		## the two squares where the pawn goes to capture things

	for i in range(2):
		notation = { 'column':col, 'row':r+direction }
		piece = check_square(notation,gameId, userId, oppId)
		if piece and piece.is_white != serverPieceInfo["is_white"]:
			squares.push_front(notation)

		
	# the first move can go up to another row
	#print(str(str(serverPieceInfo["square"]["column"]) + str(serverPieceInfo["square"]["row"])))
	#print(serverPieceInfo["name"])
	if pieceName == str(str(serverPieceInfo["square"]["column"]) + str(serverPieceInfo["square"]["row"])): #if pawn on starting square
		notation = { 'column':col, 'row':r+direction*2 }
		piece = check_square(notation,gameId, userId, oppId)
		if !piece:
			squares.push_front(notation)
	
	
	
	print(squares)
	var isLegal = false
	for square in squares:
		#print(square)
		#print(squareIWannaGo)
		if square == squareIWannaGo:
			isLegal = true
			
	return isLegal
	
	
func check_square(notation,gameId, userId, oppId):
	#print("square notty: " + str(notation))
	var curPiece
	
	for oppPiece in matches[gameId]["piecePositions"][oppId]:
		curPiece = matches[gameId]["piecePositions"][oppId].get(oppPiece)
		#print(oppPiece)
		#print(curPiece)
		#print(get(oppPiece))
		if curPiece["square"] == notation: 
			return oppPiece 
	for myPiece in matches[gameId]["piecePositions"][userId]:
		#print(myPiece)
		curPiece = matches[gameId]["piecePositions"][userId].get(myPiece)
		#print(myPiece)
		#print(curPiece)
		if curPiece["square"] == notation: 
			return myPiece 
	return null
	

	
func knightMoveIsLegal(): 
	pass

func _on_peer_disconnected(leaving_peer_id : int) -> void:
	# The disconnect signal fires before the client is removed from the connected
	# clients in multiplayer.get_peers(), so we wait for a moment.
	await get_tree().create_timer(1).timeout 
	remove_player(leaving_peer_id)


func remove_player(leaving_peer_id : int) -> void:
	
	var unDisconnectedPlayer = 0
	var peer_idx_in_peer_list : int = connected_peer_ids.find(leaving_peer_id)
	if peer_idx_in_peer_list != -1:
		connected_peer_ids.remove_at(peer_idx_in_peer_list)
		#end the game and give the id that's left in the game he win
		
	for game in matches: 
		print(game)
		if matches[game]["player1"] == leaving_peer_id:
			unDisconnectedPlayer = matches[game]["player2"]
			rpc_id(unDisconnectedPlayer, "disconnectToOpp",leaving_peer_id) #send player1 id to player2 			
			#connected_peer_ids.remove_at(unDisconnectedPlayer)
			matches.erase(game) 
			break;
		else: if matches[game]["player2"] == leaving_peer_id:
			unDisconnectedPlayer = matches[game]["player1"]
			rpc_id(unDisconnectedPlayer, "disconnectToOpp", leaving_peer_id) #send player2 id to player1 
			#connected_peer_ids.remove_at(unDisconnectedPlayer)
			matches.erase(game)
			break;

	print(matches)
	print("Player " + str(leaving_peer_id) + " disconnected.")	
	if unDisconnectedPlayer != 0:
		print("Player " + str(unDisconnectedPlayer) + " also disconnected.")
	
	
	#rpc("sync_player_list", connected_peer_ids)

@rpc
func isMyTurn(_x):
	pass
	
@rpc
func sync_player_list(_updated_connected_peer_ids):
	pass # only implemented in client (but still has to exist here)

@rpc
func connectToOpp(_opponentId):
	pass
	
#@rpc
#func disconnectToOpp(_opponentId):
	#pass	
	#
#@rpc
#func client_is_legal(_booleanVal): 
	#pass

#@rpc
#func updateOnOppMove(_squareToMoveTo, _pieceToMove):
	#pass
	
func translate(column, row):
	var x = -('a'.unicode_at(0)-column.unicode_at(0)+4) + 0.5
	var z = -(row-4) + 0.5
	return [x,z]
	
enum PIECE_TYPE {
	pawn,
	knight
}


	
	
	
#
	#
#func setUpPieces():
	#
	#player1 = {}
	#player2 = {}
	#for i in range(8):
		#player1 = {'type': PIECE_TYPE.pawn,'square': { 'column':char('a'.unicode_at(0)+i), 'row':2 },'is_white': true}
		#player2 = {'type': PIECE_TYPE.pawn,'square': { 'column':char('a'.unicode_at(0)+i), 'row':7 },'is_white': false}
	#var pieces = []
	#for i in range(8):
		#pieces.append_array([{'type': PIECE_TYPE.pawn,'square': { 'column':char('a'.unicode_at(0)+i), 'row':2 },'is_white': true},	{'type': PIECE_TYPE.pawn,'square': { 'column':char('a'.unicode_at(0)+i), 'row':7 },'is_white': false}])
	## white knights
	#pieces.append_array([{'type': PIECE_TYPE.knight,'square': { 'column':'b', 'row':1 },'is_white': true},{'type': PIECE_TYPE.knight,'square': { 'column':'g', 'row':1 },'is_white': true}])
	## black knights
	#pieces.append_array([{'type': PIECE_TYPE.knight,	'square': { 'column':'b', 'row':8 },'is_white': false},	{'type': PIECE_TYPE.knight,'square': { 'column':'g', 'row':8 },'is_white': false}])
	#
	#matches[curGame]["piecePositions"] = pieces
	
	



#func pawn(is_white, curr_notation, num_moves):
	#var direction = 1
	#if !is_white:
		#direction = -1
	#var col = curr_notation.column.unicode_at(0)
	#var r = curr_notation.row
	#var squares = []
	## the square in front of the pawn
	#var notation = { 'column':String.chr(col), 'row':r+direction*1 }
	#var piece = check_square(notation)
	#if !piece:
		#squares.push_front(notation)
		## the two squares where the pawn goes to capture things
	#var a = 1
	#for i in range(2):
		#notation = { 'column':String.chr(col+a), 'row':r+direction*1 }
		#piece = check_square(notation)
		#if piece and piece.is_white != is_white:
			#squares.push_front(notation)
		#a = -1
	## the first move can go up to another row
	#if num_moves==0:
		#notation = { 'column':String.chr(col), 'row':r+direction*2 }
		#piece = check_square(notation)
		#if !piece:
			#squares.push_front(notation)
	#return squares

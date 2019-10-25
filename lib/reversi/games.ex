defmodule Reversi.Game do 
  def new() do 
    %{
      present: initTiles(),
      timeCount: 0,
      turn: "black",
      text: "",
      player1: nil, 
      player2: nil, 
      players: [],
      gameStatus: "waiting",
      undoStack1: initTiles(),
      undoStack2: initTiles(),
      undo1: 1, 
      undo2: 1, 
      valid_moves: [] 
    }
  end
  
  def initTiles() do 
   present = List.duplicate(nil, 8)|>List.duplicate(8)
   row3 = Enum.at(present, 3)|>List.replace_at(4, "white")|>List.replace_at(3, "black")
   row4 = Enum.at(present, 4)|>List.replace_at(3, "white")|>List.replace_at(4, "black")
   List.replace_at(present, 3, row3)|>List.replace_at(4, row4)
  end 

  def client_view(game) do 
      pre = game[:present]
     tc = game[:timeCount]
     txt = game[:text]
     tn = game[:turn]
     ps= game[:players]
     p1 = game[:player1]
     p2 = game[:player2]
     gs = game[:gameStatus]
     us1 = game[:undoStack1]
     us2 = game[:undoStack2]
     ud1 = game[:undo1]
     ud2 = game[:undo2]
client_view =%{
      present: pre,
      timeCount: tc,
      turn: tn,
      text: txt,
      player1: p1,
      player2: p2,
      players: ps,
      gameStatus: gs,
      undoStack1: us1,
      undoStack2: us2, 
      undo1: ud1,
      undo2: ud2

}
     valid_moves = validMoveLst(client_view.present,client_view.turn)

     Map.put(client_view, :valid_moves, valid_moves)


  end 
  
 
  def click(game, user, row, col) do
    present = game[:present]
    if (user == game[:player1] && game[:gameStatus] != "waiting" && checkEmpty(present,row,col) && game.turn == "black") do
      flips = getFlips(present,row,col,"black")
      npresent = flipTiles(flips,present,"black") 
      newRow = Enum.at(npresent, row) |> List.replace_at(col, "black")
      newTurn = "white"
      npresent = List.replace_at(npresent, row, newRow)
      game = Map.put(game, :undoStack1, present)      
      game
      checkGameStatus(game,npresent,newTurn)  
    else
      if (user == game[:player2] && checkEmpty(present,row,col) && game.turn == "white") do
        flips = getFlips(present,row,col,"white")
        npresent = flipTiles(flips,present,"white")         
        newRow = Enum.at(npresent, row) |> List.replace_at(col, "white")
        newTurn = "black"
        npresent = List.replace_at(npresent, row, newRow)
        game = Map.put(game, :undoStack2, present)
        game
        checkGameStatus(game,npresent,newTurn)
      else 
        game
      end
    end
  end 

  def checkEmpty(present,row,col) do
    Enum.at(present,row) |> Enum.at(col) == nil
  end
  
  def user_join(game, user) do
    if (!Enum.any?(game.players,fn x-> x== user end))do  
      newplayers = [user|game.players] 
      newGame = Map.put(game,:players, newplayers) |> Map.put(:text, game.text<>"[" <>user<>" entered the room o(^▽^)o]\n")
      newGame
    else 
      game
    end
  end

  def user_exit(game, user) do 
    if (Enum.any?(game.players, fn x-> x == user end)) do 
	newplayers = List.delete(game.players, user)
        newGame = Map.put(game, :players, newplayers) |> Map.put(:text, game.text<>"[" <>user<>" left the game]\n")
        newGame
    else
        game =  Map.put(game, :text, game.text<>"["<>user<>" left the game]\n")
	if (user == game.player1) do 
   	  game = Map.put(game, :gameStatus, "over") |> Map.put(:text, game.text<>"\n["<>game.player2<>" wins!!!]\n")
		|>Map.put(:player1, nil)|> Map.put(:players, [game.player2|game.players])
		|> Map.put(:player2, nil)
	 # IO.inspect(game)
        else 
	  game = Map.put(game, :gameStatus, "over")|> Map.put(:text, game.text<>"\n["<>game.player1<>" wins!!!]\n")
		|>Map.put(:player2, nil)|> Map.put(:players, [game.player1|game.players])
		|> Map.put(:player1, nil)
	  
  	end
   end

  end

  def resignation(game, loser) do
	players = [game.player1|game.players]
        nplayers = [game.player2|players]
    cond do
      loser == game.player1 ->
	game=Map.put(game, :gameStatus, "over") 
	|> Map.put(:text, game.text<>"\n["<>game.player2<>" wins!!!]\n")
	|> Map.put(:players, nplayers)
	|> Map.put(:player1, nil)|> Map.put(:player2, nil)
        game
      loser == game.player2 ->
      	game =  Map.put(game, :gameStatus, "over")
 	|> Map.put(:text, game.text<>"\n["<>game.player1<>" wins!!!]\n")
    	|> Map.put(:players, nplayers)
	|> Map.put(:player1, nil) |> Map.put(:player2, nil)
        game
	IO.inspect(game)
      true ->
        game
    end
  end

  def reset(game, user) do 
    game |> Map.put(:present, initTiles()) |> Map.put(:gameStatus, "waiting")
         |> Map.put(:turn, "black")
         |> Map.put(:undo1, 1)
         |> Map.put(:undo2, 2)
         |> Map.put(:player1, nil) 
         |> Map.put(:player2, nil)		
  end

  def undo(game, user) do
    undoStack1 = game.undoStack1
    undoStack2 = game.undoStack2
     
    cond do 
      user == game.player1  && game.turn == "black" && game.undo1 == 1 -> 
            valid_moves = validMoveLst(undoStack1, game.turn)
            game = Map.put(game, :present, undoStack1)
                   |> Map.put(:valid_moves, valid_moves)
                   |> Map.put(:undo1, 0)
            game
      user == game.player2  && game.turn == "white" && game.undo2 == 1 ->
            valid_moves = validMoveLst(undoStack2, game.turn)
            game = Map.put(game, :present, undoStack2)
                   |> Map.put(:valid_moves, valid_moves)
                   |> Map.put(:undo2, 0)
            game
                   
      true ->
        IO.inspect("no undo")
	game
    end
    #IO.inspect(game)
    #IO.inspect("end of undo")
    #game 
  end

  def joinP(game, user) do
    players = List.delete(game.players, user)

    if (game[:player1] == nil) do
      game = Map.put(game, :player1, user)|> Map.put(:players, players)|> Map.put(:text, game.text<>"[" <>user<>" joined the game! (๑•̀ㅂ•́)و✧]\n")
      game
    else 
      if (game[:player2] == nil && game[:player1] != user) do 
        game = Map.put(game,:player2, user)|>Map.put(:gameStatus, "on") 
               |> Map.put(:players, players)|> Map.put(:text, game.text<>"[" <>user<>" joined the game! (๑•̀ㅂ•́)و✧]\n")
        game
      else
       game
      end
    end
  end  
 
  def send(game, user, txt) do
    text = game[:text]
    text = text<> user <>": " <> txt <> "\n"
    IO.inspect(text)
    game = Map.put(game, :text, text)
    game
  end 

  def validMove(present,row,col,color) do
    length(getFlips(present,row,col,color)) > 0
  end

  def validMoveLst(present,color) do
    size = Enum.count(present)
    Enum.reduce(Enum.to_list(0..(size * size - 1)), [], fn i, valid_moves ->
      row = div(i,size)
      col = rem(i,size)
      if checkEmpty(present,row,col) && validMove(present,row,col,color) do
        List.insert_at(valid_moves, -1, i)
      else
        valid_moves
      end
    end)
  end

  def flipTiles([head | tail],present,color) do
    newRow = Enum.at(present, head.row) |> List.replace_at(head.col, color)
    npresent = List.replace_at(present, head.row, newRow)
    flipTiles(tail,npresent,color)    
  end

  def flipTiles([],present,color) do
    present   
  end

  def getFlips(present,row,col,color) do
    posn = %{row: row, col: col}
    lst = []
    
    Enum.concat(lst, flipHelper(present,[],%{row: -1, col: 0},posn,color))
    |> Enum.concat(flipHelper(present,[],%{row: 1, col: 0},posn,color))
    |> Enum.concat(flipHelper(present,[],%{row: 0, col: 1},posn,color))
    |> Enum.concat(flipHelper(present,[],%{row: 0, col: -1},posn,color))
    |> Enum.concat(flipHelper(present,[],%{row: 1, col: 1},posn,color))
    |> Enum.concat(flipHelper(present,[],%{row: -1, col: -1},posn,color))
    |> Enum.concat(flipHelper(present,[],%{row: 1, col: -1},posn,color))
    |> Enum.concat(flipHelper(present,[],%{row: -1, col: 1},posn,color))
  end

  def flipHelper(present,acc,dirction,posn,color) do
    posn = %{row: posn.row + dirction.row, col: posn.col + dirction.col}
    if not checkInBoard(posn) do
      []
    else
      cond do
        Enum.at(present,posn.row)|> Enum.at(posn.col) == color ->
          acc

        Enum.at(present,posn.row)|> Enum.at(posn.col) == nil ->
          []
       
        true ->
          flipHelper(present,acc++[posn],dirction,posn,color)
      end
    end    
  end

  def checkInBoard(posn) do
    posn.row >= 0 and posn.row < 8 and posn.col >= 0 and posn.col < 8
  end

  def checkWinner(present) do
    size = Enum.count(present)
    Enum.reduce(Enum.to_list(0..(size * size - 1)), 0, fn i, acc ->
      row = div(i,size)
      col = rem(i,size)
      cond do
        Enum.at(present,row)|> Enum.at(col) == "black" ->
          acc + 1
        
        Enum.at(present,row)|> Enum.at(col) == "white" ->
          acc - 1
        
        true ->
          acc
      end
    end)
  end


  def checkGameStatus(game,present,color) do
    valid_moves = validMoveLst(present,color)
    if valid_moves != [] do
      game = Map.put(game, :present, present)
      |> Map.put(:turn, color)
      |> Map.put(:valid_moves, valid_moves)
      IO.inspect(game)
      game
    else
      newTurn = turnColor(color)
      valid_moves = validMoveLst(present,newTurn)
      if valid_moves == [] do
        count = checkWinner(present)
        winner = getWinner(game,count)            
        game = Map.put(game, :present, present)
        |> Map.put(:turn, "black")
        |> Map.put(:valid_moves, valid_moves)
        |> Map.put(:gameStatus, "over")
        |> Map.put(:text,game.text<>"\n["<>winner<>" wins !!!]\n")      
        IO.inspect(game)
        game
      else
        nTurn = turnColor(color)
        game = Map.put(game, :present, present)
        |> Map.put(:turn, nTurn)
        |> Map.put(:valid_moves, valid_moves)
        IO.inspect(game)
        game
      end
    end
  end

  def getWinner(game,count) do
    cond do
          count > 0 ->
            game.player1
          count < 0 ->
            game.player2
          true -> 
            "Tie, no"
    end
  end
    
  def turnColor(color) do
    cond do
      color == "black" ->
        "white"
      true ->
        "black"
    end
  end

end
   
        



# Project Concept -- Reversi

Chihao Sun, Rouni Yin

## Reversi Introduction

Reversi is a strategy board game for two players, played on an 8×8 uncheckered 
board. There are sixty-four identical game pieces called disks (often spelled 
"discs"), which are light on one side and dark on the other. Players take turns
placing disks on the board with their assigned color facing up. During a play, 
any disks of the opponent's color that are in a straight line and bounded by 
the disk just placed and another disk of the current player's color are turned 
over to the current player's color.The object of the game is to have the 
majority of disks turned to display your color when the last playable empty 
square is filled.

## Game Description

#### Start of the game
All the users enter the room as visitors until they join the game to be a 
player.
Before starting players decide which color will use each of them.
Next 4 pieces have to be placed in the central squares of the board, so that 
each pair of pieces of the same color form a diagonal between them.
The player with black pieces moves first; one only move is made every turn.
#### Moves
A move consists in placing from outside one piece on the board. Placed pieces 
can never be moved to another square later in the game.
The incorporation of the pieces must be made according to the following rules:

- The incorporated piece must outflank one or more of the opponent placed pieces
- To outflank means that a single piece or one straight row (vertical, 
horizontal or diagonal) of pieces of the opponent is in both sides next to own 
pieces, with no empty squares between all 
those pieces
- The player who makes the move turns the outflanked pieces over, becoming all 
of them in own pieces
- If there is more than one outflanked row, all the involved pieces in those 
rows have to be flipped
- If it´s not possible to make this kind of move, turn is forfeited and the 
opponent repeats another move
#### Rules
Besides the existed rules in Reversi, we have added undo and resignation 
operation. 

If a player claims resignation, the opponent will be the winner, 
game ends and both of them will be visitors again. The "Exit" plays the same 
as resignation for players, along with disconnection. 

Each player have only one chance for undo. It only works when there is at 
most one move has been made. It will not have an effect if there's no move to
undo or no chance to do so. 
A player can only call undo in his turn,
calling undo before the making a movement in the turn. It will 
bring the state of the game back to the one before the last movement the 
player has made, as well as withdrawing the last movement of the opponent.
   
Note: If the players call undo consecutively, the 2 undos will counteract 
   and the players run out of their chances.
#### Final
The game is over when all the squares of the board are taken or none of the 
players can move. In any case the winner is the player who has more pieces on
the board.
The game ends in a draw when both players have the same number of pieces on the 
board.
There's no player in game then, the previous players become visitors if they 
continue staying in the room. Any user can start a new game, waiting for 2 
players to join in.

## UI Design

#### Index

The index.html works as an entrance. It allows users to start a new game room or
an existed one, and identify themselves using username. After users input 
both room and user names, click button "Join the game", the game page will be 
loaded. And the user will enter the game as a visitor.

#### Game

Besides the information about the game room and user names, the game page 
basically consists of 2 parts.
##### Game board

The game is initialized in a 8X8 squares, along with 2 tiles in the center, 
black and white respectively. When players do a valid click, the 
corresponding move will be made on the board. 
Information about the game lies around the board:
- left-top: the current players of the game, including their names and tiles 
colors. If it's a player's turn in the game, the tile representing him will 
pop up with a red boundary.
- bottom: there are series of buttons for the game, i.e. "Join the Game", 
"Undo", "Resignation", "New Game".
    - "Join the game": Since users are regarded as visitors in the initial 
    entry.
    There is an option for them to be a visitor or a player when there is no 
    game on in this room. Otherwise, they will remain as a visitor in this 
    room.
    - "Undo" & "Resignation": the two function buttons are designed for 
    players in the game, although they are visible to all the users in the room.
    They will show up once the game starts, replacing the button "Join the Game"
    - "New Game": When the game ends, picking up a winner or turning out a 
    tie, it's time to start a new game by click "New Game". It will show up 
    automatically when the game ends. Any of the users clicks, a new game 
    begins, waiting for players to join. Before the "New game" clicked at the
     end of the game, the board will remain the result for evidence. "New 
     game" means a initialized board will be loaded.

##### Chat Zone
All the users in the game room can ba a part of the chatting interaction. 
Users simply input the message and send, broadcasting it to the entire room. 
And the system message will also be broadcast in the chat zone in the format 
[...], when a user enters / leaves the room and end of the game. There is 
info about the watches of the game, which does't include the players in the 
game.

At the right top of chatting dialog, there is an "exit" button. To nicely 
quit the game, all the users have to press it to disconnect. Typically, if 
a player in the game exits, it means his resignation brings the end of the 
game, along with his disconnection.

Note: To send a message, users have to click the "send" button, instead of 
press "return" on the keyboard.

## UI to Server Protocol

The client side logic must communicate game actions and game state with the 
server using Phoenix Channels. The server-side logic is be built 
using Elixir and Phoenix.

When users interact with the application, including all the button clicks and
 movements on the board, the events will send to a channel and be processed.
A game room works as a channel in the application. On the index page, when 
the user input a new room, just simply start a channel named "game:(room 
name)" and user connects to it; or connect to the existed channel.
In this application, we don't care about the verification of user. But in 
each game room, we assume users have unique names.

After entering a game room, all the users share a common game state. But 
every one of them has the access to communicate game using sockets within 
the game room channel. In order to detect the entrance of a user, the user name 
has also been passed to the channel through socket, which would be added to 
the arrays of visitors in the state as a result in the game process.

In fact, players and visitors have different accesses. The user names will be
 passed into the React component as an attribute, and be identified as 
 visitors or players depending on the click of the button "Join the Game" or 
 not. The visitors and players will be treated differently in server logic. 
 All the event users make in the UI will be pushed to the channel processes, 
 along with their corresponding user name. To handle all kinds of events, 
 the channel processes send event messages to a game process. The game 
 process handles all the events and broadcasts updated state to the channel 
 taking advantages of GenServer and server logic in Elixir. It will keep 
 backup agent as well. The channel will broadcast the change of the game 
 state to the sockets connected. And the updates will be rendered and loaded 
 on the game page.

## Data Structures on Server
The server maintains all the logic of the game (including chat) by updating 
the state of the game according to the event. So the state of game holds all 
the features. The game represented as a map, has all features as its keys and
 the current state of each feature as the corresponding values.
 
- present: It represents the current state of the board. It is a 8X8 nested 
array, in which every element represents a column on the board. Each element 
in the column array turns out to be a single square on the board. If it has 
be clicked, the value will be the color of the tile. Otherwise, it stays nil.

- players: It contains all the visitors in the game room, and 2 players of 
the game are excluded here. The 2 players are represented in the player1 and 
player2.

- undoStack1, undoStack2: Arrays of array[8][8]. They are used to trace the 
previous states of the board after player1 and player2's movement accordingly
. Actually they works as stacks to support undo. Since each player has only 1
 chance to undo, the undoStack doesn't have to trace all the board states, 
 and their lengths can be constrained in 2 to save the space. They are both 
 initialized in arrays having the initial state of the board as the only 1 
 element.
- undo1, undo2: They are used to count the number of available undo for 
 players. They are initialized as -1, which means no operation can be 
 withdrawn. After the first click of players, they turn to 1.
- turn: It's used to trace which player should move at this turn in the game.
- gameStatus: It's used to keep the status of the game, "waiting", "on" or 
"over".
- text: It holds all the text chat records in the game room as a string.

## Implementation of Game Rules
##### Join
At first user has to  enter a room name and username to enter a game room.
The first user who click "join the Game" button is assigned as the black 
player, the second user who click "join the Game" button is assigned as the 
white player. These actions are performed by the function joinP(). The 
watcher are distinguished from players by using the function user_join().
##### Start
The board is constructed by the function initTiles(), the function 
client_view initializes the board first, which is used by the client to 
render it to the user. After two players joined the game, the game will 
be start, the black assigned player moves first.
##### Click
The main function for handling the player's click is click(), which takes
the game instance, user, row, and col as input. and function validMove() 
and validMoveLst() will help click() to make sure if the player's move 
is valid or not. If a move is valid the function getFlips() will get
the list of tile which need to flip and the function flipTiles will
iterate the list the flips the tile by change tiles' color. and the 
function checkGameStatus() will update the game status and check the 
winner if game is over.

##### Undo
Since the undoStack1, 2 stores the states of the game after the responsive 
player's click, it requires operations on the stack of opponent to complete 
the undo.
A player calls undo before his click in his turn. It will 
retrieve element of the opponent stack. It forces the opponent to 
withdraw the last movement as well. By calling undo, the top of the opponent 
head will be popped out, and current state of the board (the result of undo) 
will be pushed into his own stack. But here, each player has only one undo 
chance, so to save space, the own stack becomes an array of the current 
state, used for the support of the opponent's undo.
##### Resignation
When a player calls resignation, he will lose the game by default without 
counting the tiles on the board. To implement it, just announce that the 
opponent to be the winner , and bring the game to the end, i.e. turn the 2 
players into visitors and wait for someone to start a new game.

##### Exit
The user will disconnect by calling it. This is accessible all the users in 
the game room. For game players, it works the same as resignation in addition. 

## Challenges and Solutions
- Challenge 1
     - The application requires multiple players.They get their own, separate,
     channel process.
     - Add a process to manage the game state. Channel processes sends event 
     messages to game process. Game process broadcasts updated state to the 
     channel. The channel has to broadcast the change of the state to all the
      connected sockets, so that the game page of the users will update 
      automatically without refreshing.

- Challenge 2
  
     - When connecting to the channel, there is no way to detect visitors and
      players. But in server logic function, players and visitors are treated
       differently.
     - When connecting socket to the channel, pass the user name from index 
     page to the channel. Keep it as an attribute in the React component tag.
     Send the message of the event along with the user name to channel 
     process and game process when there is event happens. 
     Initially, all the  users join the room as visitors.  For 
     classification, there is a button "Join Game". If the a user clicks it, 
     he will be a player rather than visitor. Record all the users' names in 
     the game state as players or visitors. In this way, it can easily deal 
     with functions for players and visitors by comparing the name of the 
     event caller and the names of players and visitors. 
 - Challenge 3
 
   -  When a user intends to exit the game by closing the tab, we have no 
   idea to detecting if the tab is closed. As a result, if he is a player, the 
   game may stuck.
  
    - To deal with the exit nicely especially for players, we introduced a 
    button "Exit".The user will disconnect by calling it. This is accessible all
    the users in the game room. For game players, it works the same as 
    resignation in addition. For visitors, the watches of the game decrease 
    as a result.

import React from "react";
import ReactDOM from "react-dom";
import Konva from 'konva';
import _ from "lodash";
import { Stage, Layer, Circle, Rect } from 'react-konva';
import { ToastContainer, toast } from "react-toastify";
import 'react-toastify/dist/ReactToastify.css'

export default function game_init(root, channel, user) {
	ReactDOM.render(<Reversi channel={channel} user={user} />, root);
}


let OFFSET=60;
let RADIUS=26;
let SIZE=60;

function Tile(props){
  var x = (props.column + 0.5)*SIZE + OFFSET;
  var y = (props.row + 0.5)*SIZE +OFFSET;
  return <Circle radius={RADIUS} x={x} y={y} fill = {props.color} stroke = "black" strokeWidth={1} />;
}


function Square(props){
  return <Rect x={OFFSET + SIZE * props.column} y={OFFSET + SIZE * props.row} 
	width = {SIZE} height={SIZE} fill="green" stroke="black" strokeWidth={1} 
	onClick={()=>props.onClick(props.row, props.column)} />; 
}

function Turn(props){
  var turn = props.turn
  if (turn == "black"){
    return [<Circle radius={RADIUS/3} x={0.5 * SIZE + OFFSET} y={-0.7*SIZE+OFFSET} fill="black" stroke= "red" strokeWidth={2} key="k1"/>,
		  <Circle radius={RADIUS/3} x={0.5 * SIZE + OFFSET} y={-0.25 * SIZE + OFFSET} fill="white" stroke="black" strokeWidth={1} key="k2" />];
  }
  else if (turn == "white"){
    return [<Circle radius={RADIUS/3} x={0.5 * SIZE + OFFSET} y={-0.7*SIZE+OFFSET} fill="black" stroke="black" strokeWidth={1} key="k3"/>,
	  <Circle radius={RADIUS/3} x={0.5*SIZE+OFFSET} y={-0.25 *SIZE+OFFSET} 
	    fill="white" stroke="red" strokeWidth={2} key="k4"/>]
  }
}

function Chat(props){
  return <div id ="chat">
		<div id="text">{props.text}</div>
		<br />
		<form>
  		<input type="text" name="chatText" id="input" action="return false;" method="GET"/>

 		 <input type="button" value="Send" onClick={()=>{
			 props.onClick(document.getElementById("input").value);
		 document.getElementById("input").value = '' ;}}/>
		</form>
		</div>;
}

function StatusButtons(props){
  if (props.gameStatus == "waiting"){
// Add onclick handler
    return <button id="join" onClick={()=>props.onClick("joinP")}> Join the Game </button>;
  }
  else if (props.gameStatus == "on"){
	  return <div>
		  <button id='resignation' onClick={()=>props.onClick("resignation")}>Resignation</button>
		  <button id='undo' onClick={()=>props.onClick("undo")}>Undo</button>
		</div>;
  }else {
  	return <button id="join" onClick={()=>props.onClick("reset")}>New Game</button>
  }
}

class Reversi extends React.Component {
  constructor(props){
    super(props);
    this.channel = props.channel;
    this.user = props.user; 
    this.state = {
	    present: this.initTiles(),
	    timeCount: 0,
	    turn: "black",
	    text: "",
	    player1: null, 
	    player2: null, 
	    players:[],
	    gameStatus:"waiting",
	    undoStack:[],
            valid_moves: [],

    };
	  
	  this.channel.on("update", (game) => {
    this.setState(game);
    console.log("update");
    });
	  this.channel
	      .join()
	      .receive("ok", this.got_view.bind(this))
	      .receive("error", resp => {console.log("Unable to join", resp);});
  }
  
  initTiles(){
    var ret = [];
    for (var i = 0; i < 8; i++){
      var row = [];
      for (var j = 0; j < 8; j++){
        row.push(null);
      }
      ret.push(row);
    }
    

    return ret;
  }

  initialize(){
    var board =[];
    var colors = this.state.present;
    console.log(colors);
    console.log(this.state.gameStatus);
    for (var i = 0; i < 8; i ++){
      for (var j = 0; j < 8; j++){
      	board.push(<Square row={i} column={j} key={i*8+j} onClick={(i, j)=>this.handleClick(i,j)}/>);
	//board.push(<Tile color={colors[j][i]} row={i} column={j} key={m*8+n+64} />);	
	      if (colors[i][j] != null){
	  board.push(<Tile color={colors[i][j]} row={i} column={j} key={i*8+j+64} />);
	}
      }
    }
       return board;
  }
  handleClick(i, j){
    let size = 8;
    let index = i* size + j;
    let user;
    if (this.state.turn == "black") {
      if(this.user != this.state.player1){
        this.notifyTurn();
	return;
      }
    }else{
      if(this.user != this.state.player2){
        this.notifyTurn();
	return;
      }
    }
    if (!this.state.valid_moves.includes(index)) {
      this.notify();
      return;
    }else{
      this.channel.push("click", {user: this.user, row: i, col: j})
	.receive("ok", this.got_view.bind(this));
        console.log("click"+i+"/"+j);
    }
  }
    clickButton(mes){
	  this.channel.push(mes, {user: this.user})
	  		.receive("ok", this.got_view.bind(this));
	  } 
  sendButton(txt){
    this.channel.push("send", {user: this.user, txt: txt})
	  .receive("ok", this.got_view.bind(this));
    console.log("send " + txt);
  }


  handleExit(){
    this.channel.push("exit", {user: this.user})
	  .receive("ok", this.got_view.bind(this));
    console.log(this.user + " exit");
  }

  got_view(view) {
    console.log("new view", view);
    this.setState(view.game);
    console.log(this.state.text);
  }

  notify() {
    toast("Invalid MOVE!", {
      position: toast.POSITION.BOTTOM_RIGHT
    });
  }

   notifyTurn() {
    toast("It's not your turn!", {
      position: toast.POSITION.BOTTOM_RIGHT
    });
  } 
  showTurn() {
    return <Turn turn={this.state.turn} />
  
  }
  render(){
    return <div id="overall">
      <Stage width={600} height={600}>	
        <Layer>
	  {this.showTurn()}
          {this.initialize()}
	</Layer>
      </Stage>
      <StatusButtons gameStatus={this.state.gameStatus} onClick={(mes)=>this.clickButton(mes)}/>
      <p id="player1">{this.state.player1}</p>
      <p id="player2">{this.state.player2}</p>
      <p id="watch">watches: {this.state.players.length}</p>
      <button id="exit" onClick={()=> this.handleExit()}>Exit</button>
      <Chat text={this.state.text} onClick={(txt)=>this.sendButton(txt)}/>
      <ToastContainer className="title1" />
    </div>;
  }
}

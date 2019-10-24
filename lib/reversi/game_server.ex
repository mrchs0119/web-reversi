defmodule Reversi.GameServer do
  use GenServer
    alias Reversi.BackupAgent
  alias Reversi.Game

  def reg(name) do
    {:via, Registry, {Reversi.GameReg, name}}
  end

  def start(name) do
    spec = %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [name]},
      restart: :permanent,
      type: :worker,
    }
    Reversi.GameSup.start_child(spec)
  end
  def start_link(name) do
    game = Reversi.BackupAgent.get(name) || Reversi.Game.new()
    GenServer.start_link(__MODULE__, game, name: reg(name))
  end

  def init(game) do
    {:ok, game}
  end
  def get_state(room_name) do
    GenServer.call(reg(room_name), {:get_state, room_name})
  end
 
  def click(name, user, row, col) do 
    GenServer.call(reg(name), {:click, name, user, row, col})
  end
  
  def joinP(name, user) do 
    GenServer.call(reg(name), {:joinP, name, user})
  end
 
  def user_join(name, user) do 
    GenServer.call(reg(name), {:user_join, name, user})
  end 

  def reset(name, user) do 
    GenServer.call(reg(name), {:reset, name, user})
  end
  def resignation(name, user) do 
    GenServer.call(reg(name), {:resignation, name, user})
  end

  def undo(name, user) do 
    GenServer.call(reg(name), {:undo, name, user})
  end

  def send(name, user, txt) do 
    GenServer.call(reg(name), {:send, name, user, txt})
  end 

  def user_exit(name, user) do 
    GenServer.call(reg(name), {:user_exit, name, user})
  end  
  
  
  def handle_call({:user_join, name, user}, _from, game) do 
    game = Reversi.Game.user_join(game, user)
    Reversi.BackupAgent.put(name, game)
    {:reply, game, game}
  end  

  def handle_call({:send, name, user, txt}, _from, game) do
    game = Reversi.Game.send(game, user, txt)
    Reversi.BackupAgent.put(name, game)
    {:reply, game, game}
  end
  def handle_call({:click, name, user, row, col}, _from, game) do 
    game = Reversi.Game.click(game, user, row, col)
    Reversi.BackupAgent.put(name, game)
    {:reply, game, game}
  end
  def handle_call({:get_state, room_name}, _from, game) do
    game = Reversi.Game.client_view(game)
    {:reply, game, game}
  end

  def handle_call({:joinP,name, user}, _from, game) do 
    game = Reversi.Game.joinP(game, user)
    Reversi.BackupAgent.put(name, game)
    {:reply, game, game}
  end

  def handle_call({:user_exit, name, user}, _from, game) do 
    game = Reversi.Game.user_exit(game, user)
    Reversi.BackupAgent.put(name, game)
    {:reply, game, game}
  end  

  def handle_call({:reset, name, user}, _from, game) do 
    game = Reversi.Game.reset(game, user)
    Reversi.BackupAgent.put(name, game)
    {:reply, game, game}
  end 
  def handle_call({:resignation, name, user}, _from, game) do 
    game = Reversi.Game.resignation(game, user)
    Reversi.BackupAgent.put(name, game)
    {:reply, game, game}
  end   


  def handle_call({:undo, name, user}, _from, game) do 
    game = Reversi.Game.undo(game, user)
    Reversi.BackupAgent.put(name, game)
    {:reply, game, game}
  end  

end

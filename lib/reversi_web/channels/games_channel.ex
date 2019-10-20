defmodule ReversiWeb.GamesChannel do
  use ReversiWeb, :channel
	alias Reversi.Game
	alias Reversi.BackupAgent
	alias Reversi.GameServer

 def join("games:" <> name, payload, socket) do
    if authorized?(payload) do
        Reversi.GameServer.start(name)
	game = GameServer.get_state(name)
			socket = socket
			|> assign(:name, name)
                        |> assign(:game, game)
			{:ok, %{"join" => name, "game"=>game}, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end
  def handle_in("click", %{"user"=> user, "row"=> row, "col"=>col}, socket) do
	name = socket.assigns[:name]
	game = GameServer.click(name, user, row, col)
	socket = assign(socket, :game, game)
    {:reply, {:ok, %{ "game" => Game.client_view(game)}}, socket}
  end
def handle_in("joinP", %{"user"=>user}, socket) do 
	name = socket.assigns[:name]
	game = GameServer.joinP(name,user)
	socket = assign(socket, :game, game)
    {:reply, {:ok, %{ "game" => Game.client_view(game)}}, socket}
  end
def handle_in("send", %{"user"=>user, "txt"=> txt}, socket) do 
	name = socket.assigns[:name]
	game = GameServer.send(name,user, txt)
	socket = assign(socket, :game, game)
    {:reply, {:ok, %{ "game" => Game.client_view(game)}}, socket}
  end

  # Channels can be used in a request/response fashion
  # by sending replies to requests from the client
  def handle_in("ping", payload, socket) do
    {:reply, {:ok, payload}, socket}
  end

  # It is also common to receive messages from the client and
  # broadcast to everyone in the current topic (games:lobby).
  def handle_in("shout", payload, socket) do
    broadcast socket, "shout", payload
    {:noreply, socket}
  end

  # Add authorization logic here as required.
  defp authorized?(_payload) do
    true
  end
end
defmodule FakeArtistWeb.PlayGameLive.Complete do
  use FakeArtistWeb, :live_component
  alias FakeArtist.Game

  def handle_event("restart", _params, socket) do
    {:noreply, assign(socket, game: socket.assigns.game |> Game.restart())}
  end

  def render(assigns) do
    ~H"""
    <div>
      <div>Complete</div>
      <%= for vote <- Map.values(@game.votes) do %>
      <%= vote %>
      <% end %>
      <button phx-click="restart" phx-target={@myself}>Start a new game</button>
    </div>
    """
  end
end

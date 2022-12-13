defmodule FakeArtistWeb.PlayGameLive.NotStarted do
  use FakeArtistWeb, :live_component
  alias FakeArtist.Game

  def handle_event("start", _params, socket) do
    case socket.assigns.game |> Game.start() do
      {:ok, game} -> {:noreply, assign(socket, game: game)}
      {:error, _reason} -> {:noreply, socket}
    end
  end

  def handle_event("leave", _params, socket) do
    {:noreply,
     assign(socket,
       game: socket.assigns.game |> Game.leave(%{user_id: socket.assigns.session_id})
     )}
  end

  def render(assigns) do
    ~H"""
    <div>
      <%= if @game.users |> Enum.find(fn user -> user.id == @session_id end) do %>
      <button phx-click="leave" phx-target={@myself}>Leave</button>
      <% end %>
      <button phx-click="start" phx-target={@myself}>Start</button>
    </div>
    """
  end
end

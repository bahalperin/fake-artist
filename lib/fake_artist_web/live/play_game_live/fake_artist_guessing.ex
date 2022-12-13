defmodule FakeArtistWeb.PlayGameLive.FakeArtistGuessing do
  use FakeArtistWeb, :live_component
  alias FakeArtist.Game

  def handle_event("done", _params, socket) do
    {:noreply, assign(socket, game: socket.assigns.game |> Game.done_guessing_word())}
  end

  def render(assigns) do
    ~H"""
    <div>
      <button phx-click="done" phx-target={@myself}>Done</button>
    </div>
    """
  end
end

defmodule FakeArtistWeb.PlayGameLive.Voting do
  use FakeArtistWeb, :live_component
  alias FakeArtist.Game

  def mount(socket) do
    {:ok,
     assign(
       socket,
       vote: ""
     )}
  end

  def handle_event("select_vote", %{"user-id" => user_id}, socket) do
    {:noreply, assign(socket, vote: user_id)}
  end

  def handle_event("submit_vote", _params, socket) do
    {:noreply,
     assign(socket,
       game:
         socket.assigns.game
         |> Game.submit_vote(%{
           user_id: socket.assigns.session_id,
           vote: socket.assigns.vote
         })
     )}
  end

  def render(assigns) do
    ~H"""
    <div>
      <%= if @game.votes |> Map.get(@session_id) do %>
        <div>Waiting for others to vote</div>
      <% else %>
      <h3>Vote for:</h3>
      <%= for artist <- @game |> Game.artists do %>
      <div>
        <button
          phx-click="select_vote"
          phx-value-user-id={artist.id}
          phx-target={@myself}
          disabled={@vote == artist.id}
        >
          <%= artist.name %>
        </button>
        </div>
      <% end %>
      <button
        disabled={!@vote}
        phx-click="submit_vote"
          phx-target={@myself}
        >
        Submit
        </button>
      <% end %>
    </div>
    """
  end
end

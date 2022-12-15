defmodule FakeArtistWeb.PlayGameLive do
  use FakeArtistWeb, :live_view
  alias FakeArtist.Game

  def mount(%{"code" => code}, session, socket) do
    game = Game.find(%{code: code})

    _mount(game, assign(socket, session_id: session["session_id"]))
  end

  defp _mount(nil, socket) do
    {:ok,
     socket
     |> put_flash(:error, "No game found")
     |> redirect(to: "/")}
  end

  defp _mount(game, socket) do
    if connected?(socket), do: Game.subscribe(game)

    {
      :ok,
      assign(
        socket,
        game: game
      )
    }
  end

  def handle_info(_msg, socket) do
    game = Game.find(%{code: socket.assigns.game.code})
    {:noreply, assign(socket, game: game)}
  end

  def render(assigns) do
    ~H"""
    <%= if @game.status == :not_started do %>
      <.live_component
        module={FakeArtistWeb.PlayGameLive.NotStarted}
        id="not-started"
        game={@game}
        session_id={@session_id}
      />
    <% end %>
    <%= if @game.status == :selecting_word do %>
      <.live_component
        module={FakeArtistWeb.PlayGameLive.SelectingWord}
        id="selecting-word"
        game={@game}
        session_id={@session_id}
      />
    <% end %>
    <%= if @game.status == :drawing do %>
      <.live_component
        module={FakeArtistWeb.PlayGameLive.Drawing}
        id="drawing"
        game={@game}
        session_id={@session_id}
      />
    <% end %>
    <%= if @game.status == :voting do %>
      <.live_component
        module={FakeArtistWeb.PlayGameLive.Voting}
        id="voting"
        game={@game}
        session_id={@session_id}
      />
    <% end %>
    <%= if @game.status == :fake_artist_guessing do %>
      <.live_component
        module={FakeArtistWeb.PlayGameLive.FakeArtistGuessing}
        id="guessing"
        game={@game}
        session_id={@session_id}
      />
    <% end %>
    <%= if @game.status == :complete do %>
      <.live_component
        module={FakeArtistWeb.PlayGameLive.Complete}
        id="complete"
        game={@game}
        session_id={@session_id}
      />
    <% end %>
    """
  end
end

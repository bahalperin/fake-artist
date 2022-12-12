defmodule FakeArtistWeb.PlayGameLive do
  use FakeArtistWeb, :live_view
  alias FakeArtist.Game

  def mount(%{ "code" => code }, _session, socket) do
    game = Game.find(%{ code: code })

    _mount(game, socket)
  end

  defp _mount(nil, socket) do
    {:ok,
      socket
        |> put_flash(:error, "No game found")
        |> redirect(to: "/")
    }
  end
  defp _mount(game, socket) do
    if connected?(socket), do: Game.subscribe(game)

    {:ok, assign(socket, game: game)}
  end

  def handle_info({ :user_joined, _user }, socket) do
    game = Game.find(%{ code: socket.assigns.game.code })
    {:noreply, assign(socket, game: game)}
  end

  def render(assigns) do
    ~H"""
    code: <%= @game.code %>
    <%= for user <- @game.users do %>
    <div>
      <%= user %>
      </div>
    <% end %>

    """
  end

end

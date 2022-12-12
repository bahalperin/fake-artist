defmodule FakeArtistWeb.PlayGameLive do
  use FakeArtistWeb, :live_view
  alias FakeArtist.Game

  def mount(%{ "code" => code }, _session, socket) do
    game = Game.find(%{ code: code })

    {:ok, assign(socket, game: game)}
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

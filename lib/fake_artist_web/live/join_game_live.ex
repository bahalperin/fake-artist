defmodule FakeArtistWeb.JoinGameLive do
  # In Phoenix v1.6+ apps, the line below should be: use MyAppWeb, :live_view
  use FakeArtistWeb, :live_view
  alias FakeArtist.Game
  alias FakeArtist.JoinGameForm

  def mount(_params, _session, socket) do
    {:ok, assign(socket, changeset: %JoinGameForm{} |> JoinGameForm.changeset(%{ code: "", username: ""}))}
  end

  def handle_event("validate", %{"join_game_form" => data}, socket) do
    socket =
      assign(socket,
        changeset:
          %JoinGameForm{}
          |> JoinGameForm.changeset(data)
          |> Map.put(:action, :insert)
      )

    {:noreply, socket}
  end

  def handle_event("save", _payload, socket)
      when not socket.assigns.changeset.valid? do
    {:noreply, socket}
  end

  def handle_event("save", %{"join_game_form" => data}, socket) do
    game = Game.find(%{ code: data["code"] })

    case game do
      nil ->
        {:noreply, put_flash(socket, :error, "Could not find game with that code")}

      _ ->
        game
          |> Game.join(%{ username: data["username"] })

        {:noreply, redirect(socket, to: "/game/#{game.code}")}
    end
  end
end

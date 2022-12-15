defmodule FakeArtistWeb.NewGameLive do
  # In Phoenix v1.6+ apps, the line below should be: use MyAppWeb, :live_view
  use FakeArtistWeb, :live_view
  alias FakeArtist.Game
  alias FakeArtist.NewGameForm

  def mount(_params, session, socket) do
    {:ok,
     assign(socket,
       session_id: session["session_id"],
       changeset: %NewGameForm{} |> NewGameForm.changeset(%{username: ""})
     )}
  end

  def handle_event("validate", %{"new_game_form" => data}, socket) do
    socket =
      assign(socket,
        changeset:
          %NewGameForm{}
          |> NewGameForm.changeset(data)
          |> Map.put(:action, :insert)
      )

    {:noreply, socket}
  end

  def handle_event("save", _payload, socket)
      when not socket.assigns.changeset.valid? do
    {:noreply, put_flash(socket, :error, "Name is invalid")}
  end

  def handle_event("save", %{"new_game_form" => data}, socket) do
    {:ok, game} =
      Game.new()
      |> Game.join(%{
        id: socket.assigns.session_id,
        name: data["username"]
      })

    {:noreply, redirect(socket, to: "/game/#{game.code}")}
  end
end

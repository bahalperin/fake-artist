defmodule FakeArtistWeb.PlayGameLive.Drawing do
  use FakeArtistWeb, :live_component
  alias FakeArtist.Game

  def mount(socket) do
    {:ok,
     assign(
       socket,
       line: %{ points: [] }
     )}
  end
  def handle_event("submit_drawing", _params, socket) do
    {:noreply,
     assign(socket,
       game:
         socket.assigns.game
         |> Game.submit_drawing(%{
           user_id: socket.assigns.session_id,
           drawing: %{
             user_id: socket.assigns.session_id,
             points: socket.assigns.line.points
           }
         }),
       line: %{}
     )}
  end

  def handle_event("undo_drawing", _params, socket) do
    {:noreply, assign(socket, line: %{points: []})}
  end

  def handle_event("line_complete", params, socket) do
    {:noreply, assign(socket, line: %{points: params["points"]})}
  end

  defp user_colors(game) do
    colors = [
      "#ff0000",
      "#4f8f25",
      "#00eaff",
      "#aa00ff",
      "#ff7f00",
      "#0095ff",
      "#edb9b9",
      "#23628f",
      "#8f6a23",
      "#000000"
    ]

    game
    |> Game.artists()
    |> Enum.map(fn user -> user.id end)
    |> Enum.zip(colors)
    |> Map.new()
  end

  defp drawing(game) do
    id_to_colors = game |> user_colors

    game.drawing_state
    |> Enum.map(fn line -> %{color: id_to_colors[line["user_id"]], points: line["points"]} end)
  end

  def render(assigns) do
    ~H"""
    <div>
      <div>current_user: <%= Enum.find(@game.users, fn user -> user.id === @game.current_user_id end) |> Map.get(:name) %></div>
      <div>turns_taken: <%= @game.turns_taken %></div>
      <div>category: <%= @game.drawing_category %></div>
      <div>word: <%= Game.word(@game, %{ user_id: @session_id }) %></div>
      <%= if @game.current_user_id == @session_id do %>
        <button phx-click="undo_drawing" phx-target={@myself}>Undo Drawing</button>
        <button phx-click="submit_drawing" phx-target={@myself}>Submit Drawing</button>
      <% end %>
      <div
        id="canvas-container"
        phx-hook="drawing"
        data-live-component-id={@myself}
        data-your-color={user_colors(@game) |> Map.get(@session_id)}
        data-your-turn={@game.current_user_id == @session_id}
        data-line={Jason.encode!(@line)}
        data-drawing={Jason.encode!(drawing(@game))}
      >
        <canvas id="canvas" phx-update="ignore">
          Canvas is not supported!
        </canvas>
      </div>
    </div>
    """
  end
end

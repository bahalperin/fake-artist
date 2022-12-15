defmodule FakeArtistWeb.PlayGameLive.Drawing do
  use FakeArtistWeb, :live_component
  alias FakeArtist.Game

  def mount(socket) do
    {:ok,
     assign(
       socket,
       line: %{points: []}
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
    <div class="flex flex-row flex-1 w-full">
      <div class="w-64 h-full p-8">
        <ul class="text-sm font-medium text-gray-900 bg-white rounded-lg border border-gray-200">
          <li class="py-2 px-4 w-full rounded-t-lg border-b border-gray-200 font-bold text-base">
            Players
          </li>
          <%= for user <- @game.users do %>
            <li class="py-2 px-4 w-full rounded-t-lg border-b border-gray-200 flex flex-row gap-2 items-center">
              <%= user.name %>
              <%= if user.id == @game.question_master_id do %>
                (QM)
              <% else %>
                <div
                  class="h-2 w-2 rounded"
                  style={"background: #{user_colors(@game) |> Map.get(user.id)}"}
                />
              <% end %>
            </li>
          <% end %>
        </ul>
      </div>
      <div class="flex flex-col items-center w-full gap-4 p-4">
        <div class="flex flex-col justify-between items-start w-full max-w-[780px] p-2 gap-2 text-sm font-medium text-gray-900 bg-white rounded-lg border border-gray-200">
          <h2 class="font-serif text-lg">
            <span class="font-bold">
              <%= Enum.find(@game.users, fn user -> user.id === @game.current_user_id end)
              |> Map.get(:name) %>
            </span>
            is drawing
          </h2>
          <div>
            <div class="flex flex-row gap-6">
              <div>
                <span class="font-bold">Category:</span>
                <%= @game.drawing_category %>
              </div>
              <div>
                <span class="font-bold">Word:</span>
                <%= Game.word(@game, %{user_id: @session_id}) %>
              </div>
            </div>
          </div>
        </div>
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
        <%= if @game.current_user_id == @session_id do %>
          <div class="flex flex-row justify-between w-full max-w-[780px] py-4">
            <button
              phx-click="undo_drawing"
              phx-target={@myself}
              disabled={length(@line.points) == 0}
              class="text-gray-900 bg-white border border-gray-300 focus:outline-none enabled:hover:bg-gray-100 disabled:bg-gray-200 disabled:text-gray-500 focus:ring-4 focus:ring-gray-200 font-medium rounded-lg text-sm px-5 py-2.5 mr-2 mb-2"
            >
              Undo Drawing
            </button>
            <button
              phx-click="submit_drawing"
              phx-target={@myself}
              disabled={length(@line.points) == 0}
              class="bg-indigo-600 border border-transparent text-white focus:outline-none enabled:hover:bg-indigo-700 disabled:opacity-50 focus:ring-4 focus:ring-gray-200 font-medium rounded-lg text-sm px-5 py-2.5 mr-2 mb-2"
            >
              Submit Drawing
            </button>
          </div>
        <% end %>
      </div>
    </div>
    """
  end
end

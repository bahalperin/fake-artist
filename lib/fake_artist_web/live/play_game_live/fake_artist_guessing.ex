defmodule FakeArtistWeb.PlayGameLive.FakeArtistGuessing do
  use FakeArtistWeb, :live_component
  alias FakeArtist.Game
  alias FakeArtistWeb.Components

  def handle_event("done", _params, socket) do
    {:noreply, assign(socket, game: socket.assigns.game |> Game.done_guessing_word())}
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
      <div class="w-96 h-full p-8 flex flex-col gap-4">
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
                <span class="text-xl">
                  <%= if @game.fake_artist_id == user.id do %>
                    🕵️‍♂️
                  <% else %>
                    👨‍🎨
                  <% end %>
                </span>
                voted for <%= Game.voted_for(@game, %{user_id: user.id}) %>
                <span class="bg-blue-100 text-blue-800 text-xs font-semibold mr-2 px-2.5 py-0.5 rounded dark:bg-blue-200 dark:text-blue-800">
                  <%= Game.total_votes(@game, %{user_id: user.id}) %>
                </span>
              <% end %>
            </li>
          <% end %>
        </ul>
        <%= if @session_id == @game.fake_artist_id do %>
          <Components.button phx-click="done" phx-target={@myself} variant={:primary}>
            Done Guessing Word
          </Components.button>
        <% end %>
      </div>
      <div class="flex flex-col items-center w-full gap-4 p-4">
        <div class="flex flex-col justify-between items-start w-full max-w-[780px] p-2 gap-2 text-sm font-medium text-gray-900 bg-white rounded-lg border border-gray-200">
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
          data-line={Jason.encode!(%{points: []})}
          data-drawing={Jason.encode!(drawing(@game))}
        >
          <canvas id="canvas" phx-update="ignore">
            Canvas is not supported!
          </canvas>
        </div>
      </div>
    </div>
    """
  end
end

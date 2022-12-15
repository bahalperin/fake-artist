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
        <div class="text-sm font-medium text-gray-900 bg-white rounded-lg border border-gray-200">
          <div class="py-2 px-4 w-full rounded-t-lg border-b border-gray-200 font-bold text-base">
            Vote for Fake Artist
          </div>
          <%= for user <- @game.users do %>
            <button
              phx-click="select_vote"
              phx-value-user-id={user.id}
              phx-target={@myself}
              disabled={
                user.id == @session_id || user.id == @vote ||
                  !Game.artist?(@game, %{user_id: user.id}) ||
                  Game.voted?(@game, %{user_id: @session_id})
              }
              data-selected={user.id == @vote}
              class="flex flex-row items-center gap-4 py-2 px-4 w-full font-medium text-left border-b border-gray-200 enabled:cursor-pointer enabled:hover:text-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-700 focus:text-blue-700 enabled:hover:bg-gray-100 data-[selected]:bg-gray-300"
            >
              <%= user.name %>
              <%= if user.id == @game.question_master_id do %>
                (QM)
              <% else %>
                <div
                  class="h-2 w-2 rounded"
                  style={"background: #{user_colors(@game) |> Map.get(user.id)}"}
                />
              <% end %>
            </button>
          <% end %>
        </div>
        <div class="flex flex-col gap-2">
          <%= if Game.artist?(@game, %{ user_id: @session_id}) do %>
            <button
              phx-click="submit_vote"
              phx-target={@myself}
              disabled={@vote == ""}
              class="bg-indigo-600 w-full border border-transparent text-white focus:outline-none enabled:hover:bg-indigo-700 disabled:opacity-50 focus:ring-4 focus:ring-gray-200 font-medium rounded-lg text-sm px-5 py-2.5"
            >
              <%= if Game.voted?(@game, %{ user_id: @session_id }) do %>
                Submitted Vote for <%= @game.users
                |> Enum.find(fn user -> user.id == @game.votes[@session_id] end)
                |> Map.get(:name) %>
              <% else %>
                <%= if @game.users |> Enum.find(fn user -> user.id == @vote end) do %>
                  Submit Vote for <%= @game.users
                  |> Enum.find(fn user -> user.id == @vote end)
                  |> Map.get(:name) %>
                <% else %>
                  Submit
                <% end %>
              <% end %>
            </button>
          <% end %>
          <div class="text-gray-600 text-sm">
            <%= if @game.votes |> Map.get(@session_id) || @session_id == @game.question_master_id do %>
              Waiting for everyone to vote...
            <% end %>
          </div>
        </div>
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

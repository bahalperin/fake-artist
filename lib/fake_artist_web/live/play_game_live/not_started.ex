defmodule FakeArtistWeb.PlayGameLive.NotStarted do
  use FakeArtistWeb, :live_component
  alias FakeArtist.Game

  def handle_event("start", _params, socket) do
    case socket.assigns.game |> Game.start() do
      {:ok, game} -> {:noreply, assign(socket, game: game)}
      {:error, _reason} -> {:noreply, socket}
    end
  end

  def handle_event("leave", _params, socket) do
    {:noreply,
     assign(socket,
       game: socket.assigns.game |> Game.leave(%{user_id: socket.assigns.session_id})
     )}
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
            <li class="py-2 px-4 w-full rounded-t-lg border-b border-gray-200">
              <%= user.name %>
            </li>
          <% end %>
        </ul>
      </div>
      <div class="flex flex-col flex-1">
        <div class="flex flex-col flex-1 justify-center items-center">
          <button
            phx-click="start"
            phx-target={@myself}
            class="group relative w-full max-w-lg justify-center items-center rounded-md border border-transparent bg-indigo-600 py-4 px-8 text-sm font-medium text-white hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2"
          >
            Start
          </button>
        </div>
        <div class="flex flex-row justify-end w-full p-4">
          <%= if @game.users |> Enum.find(fn user -> user.id == @session_id end) do %>
            <button
              phx-click="leave"
              phx-target={@myself}
              class="text-gray-900 bg-white border border-gray-300 focus:outline-none hover:bg-gray-100 focus:ring-4 focus:ring-gray-200 font-medium rounded-lg text-sm px-5 py-2.5 mr-2 mb-2"
            >
              Leave
            </button>
          <% else %>
            <a
              href={"/game/join?code=#{@game.code}"}
              class="text-gray-900 bg-white border border-gray-300 focus:outline-none hover:bg-gray-100 focus:ring-4 focus:ring-gray-200 font-medium rounded-lg text-sm px-5 py-2.5 mr-2 mb-2"
            >
              Join
            </a>
          <% end %>
        </div>
      </div>
    </div>
    """
  end
end

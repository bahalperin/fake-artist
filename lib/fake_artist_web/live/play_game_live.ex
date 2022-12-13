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
        game: game,
        line: %{}
      )
    }
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

  def handle_event("start", _params, socket) do
    case socket.assigns.game |> Game.start() do
      {:ok, game} -> {:noreply, assign(socket, game: game)}
      {:error, _reason} -> {:noreply, socket}
    end
  end

  def handle_event("select_word", _params, socket) do
    {:noreply,
     assign(socket,
       game:
         socket.assigns.game
         |> Game.choose_category_and_word(%{
           word: "apple",
           category: "food",
           user_id: socket.assigns.session_id
         })
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

  def handle_event("vote", _params, socket) do
    {:noreply,
     assign(socket,
       game:
         socket.assigns.game
         |> Game.submit_vote(%{
           user_id: socket.assigns.session_id,
           vote: socket.assigns.game |> Game.artists() |> Enum.random() |> Map.get(:id)
         })
     )}
  end

  def handle_event("done", _params, socket) do
    {:noreply, assign(socket, game: socket.assigns.game |> Game.done_guessing_word())}
  end

  def handle_info(_msg, socket) do
    game = Game.find(%{code: socket.assigns.game.code})
    {:noreply, assign(socket, game: game)}
  end

  def render(assigns) do
    ~H"""
    code: <%= @game.code %>
    status: <%= Atom.to_string(@game.status) %>
    <%= for user <- @game.users do %>
    <div>
      <%= user.name %>
      <%= if user.id == @session_id do %>
      (You)
      <% end %>
      <%= if user.id == @game.question_master_id do %>
      QM
      <% end %>
      <%= if user.id == @game.fake_artist_id do %>
      Fake Artist
      <% end %>
    </div>
    <% end %>
    <%= if @game.status == :not_started do %>
      <button phx-click="start">Start</button>
    <% end %>
    <%= if @game.status == :selecting_word do %>
      <%= if @game.question_master_id == @session_id do %>
        <button phx-click="select_word">Select Word</button>
      <% end %>
    <% end %>
    <%= if @game.status == :drawing do %>
    <div>
      <div>current_user: <%= Enum.find(@game.users, fn user -> user.id === @game.current_user_id end) |> Map.get(:name) %></div>
      <div>turns_taken: <%= @game.turns_taken %></div>
      <%= if @game.current_user_id == @session_id do %>
        <button phx-click="undo_drawing">Undo Drawing</button>
        <button phx-click="submit_drawing">Submit Drawing</button>
      <% end %>
      <div
        id="canvas-container"
        phx-hook="drawing"
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
    <% end %>
    <%= if @game.status == :voting do %>
      <%= for vote <- Map.values(@game.votes) do %>
      <%= vote %>
      <% end %>
      <button phx-click="vote">Vote</button>
    <% end %>
    <%= if @game.status == :fake_artist_guessing do %>
      <button phx-click="done">Done</button>
    <% end %>
    <%= if @game.status == :complete do %>
    <div>
      <div>Complete</div>
      <%= for vote <- Map.values(@game.votes) do %>
      <%= vote %>
      <% end %>
    </div>
    <% end %>
    """
  end
end

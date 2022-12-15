defmodule FakeArtistWeb.PlayGameLive.SelectingWord do
  use FakeArtistWeb, :live_component
  alias FakeArtist.Game
  alias FakeArtist.QuestionMasterForm

  def mount(socket) do
    {:ok,
     assign(
       socket,
       changeset:
         %QuestionMasterForm{}
         |> QuestionMasterForm.changeset(%{})
     )}
  end

  def handle_event("validate_word", %{"question_master_form" => data}, socket) do
    {
      :noreply,
      assign(
        socket,
        changeset:
          %FakeArtist.QuestionMasterForm{}
          |> FakeArtist.QuestionMasterForm.changeset(data)
          |> Map.put(:action, :insert)
      )
    }
  end

  def handle_event("submit_word", _payload, socket)
      when not socket.assigns.changeset.valid? do
    {:noreply, socket}
  end

  def handle_event("submit_word", %{"question_master_form" => data}, socket) do
    {:noreply,
     assign(socket,
       game:
         socket.assigns.game
         |> Game.choose_category_and_word(%{
           word: data["word"],
           category: data["category"],
           user_id: socket.assigns.session_id
         })
     )}
  end

  def render(assigns) do
    ~H"""
    <div class="flex flex-1 flex-col items-center justify-center w-full">
      <div class="bg-white shadow-lg rounded px-8 pt-6 pb-8 mb-4 flex flex-col w-full max-w-lg">
        <%= if @game.question_master_id == @session_id do %>
          <.form
            class="flex flex-col gap-8"
            let={f}
            for={@changeset}
            phx-change="validate_word"
            phx-submit="submit_word"
            phx-target={@myself}
          >
            <div class="flex flex-col gap-2">
              <div>
                <%= label(f, :category, class: "text-gray-700") %>
                <%= text_input(f, :category,
                  class:
                    "mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-300 focus:ring focus:ring-indigo-200 focus:ring-opacity-50"
                ) %>
                <%= error_tag(f, :category) %>
              </div>

              <div>
                <%= label(f, :word, class: "text-gray-700") %>
                <%= text_input(f, :word,
                  class:
                    "mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-300 focus:ring focus:ring-indigo-200 focus:ring-opacity-50"
                ) %>
                <%= error_tag(f, :word) %>
              </div>
            </div>

            <%= submit("Save",
              class:
                "group relative flex w-full justify-center rounded-md border border-transparent bg-indigo-600 py-2 px-4 text-sm font-medium text-white hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2"
            ) %>
          </.form>
        <% else %>
          <div class="text-xl font-bold">
            Waiting for Question Master to Select Word
          </div>
        <% end %>
      </div>
    </div>
    """
  end
end

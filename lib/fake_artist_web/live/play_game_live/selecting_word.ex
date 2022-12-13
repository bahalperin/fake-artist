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
    <div>
      <%= if @game.question_master_id == @session_id do %>
        <.form let={f} for={@changeset} phx-change="validate_word" phx-submit="submit_word" phx-target={@myself}>
            <%= label f, :category %>
            <%= text_input f, :category %>
            <%= error_tag f, :category %>

            <%= label f, :word %>
            <%= text_input f, :word %>
            <%= error_tag f, :word %>

            <%= submit "Save" %>
        </.form>
      <% else %>
        <div>Waiting for Question Master</div>
      <% end %>
    </div>
    """
  end
end

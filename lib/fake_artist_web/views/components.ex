defmodule FakeArtistWeb.Components do
  use Phoenix.Component

  def button(assigns) do
    extra = assigns_to_attributes(assigns, [:variant, :inner_block, :class])

    assigns =
      assigns
      |> assign(:extra, extra)

    class =
      [
        button_class(assigns),
        if(Map.has_key?(assigns, :class), do: assigns.class, else: "")
      ]
      |> Enum.filter(fn class -> !!class end)
      |> Enum.join(" ")

    ~H"""
    <button class={class} {@extra}>
      <%= render_slot(@inner_block) %>
    </button>
    """
  end

  defp button_class(%{variant: :primary}) do
    "bg-indigo-600 border border-transparent text-white focus:outline-none enabled:hover:bg-indigo-700 disabled:opacity-50 focus:ring-4 focus:ring-gray-200 font-medium rounded-lg text-sm px-5 py-2.5"
  end

  defp button_class(%{variant: :secondary}) do
    "text-gray-900 bg-white border border-gray-300 focus:outline-none hover:bg-gray-100 focus:ring-4 focus:ring-gray-200 font-medium rounded-lg text-sm px-5 py-2.5"
  end
end

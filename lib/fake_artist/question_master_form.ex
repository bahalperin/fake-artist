defmodule FakeArtist.QuestionMasterForm do
  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field :category, :string
    field :word, :string
  end

  def changeset(form, attrs) do
    form
    |> cast(attrs, [:word, :category])
    |> validate_required([:word, :category])
    |> validate_format(:word, ~r/^[A-Za-z]+$/)
  end

end

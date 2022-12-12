defmodule FakeArtist.User do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field :id, :string
    field :name, :string
  end

  def changeset(form, attrs) do
    form
    |> cast(attrs, [:id, :name])
    |> validate_required([:id, :name])
    |> validate_length(:name, min: 1, max: 30)
  end

end

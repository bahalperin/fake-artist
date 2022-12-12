defmodule FakeArtist.NewGameForm do
  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field :username, :string
  end

  def changeset(form, attrs) do
    form
    |> cast(attrs, [:username])
    |> validate_required([:username])
    |> validate_length(:username, min: 1, max: 30)
  end

end

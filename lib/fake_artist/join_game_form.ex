defmodule FakeArtist.JoinGameForm do
  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field :code, :string
    field :username, :string
  end

  def changeset(form, attrs) do
    form
    |> cast(attrs, [:code, :username])
    |> validate_required([:code, :username])
    |> validate_length(:code, min: 6, max: 6)
    |> validate_length(:username, min: 1, max: 30)
  end

end

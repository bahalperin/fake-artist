defmodule FakeArtist.Game do
  use Ecto.Schema
  import Ecto.Changeset
  alias FakeArtist.Repo
  alias __MODULE__

  schema "games" do
    field :code, :string
    field :status, Ecto.Enum, values: [:not_started, :in_progress, :complete]
    field :users, {:array, :string}

    timestamps()
  end

  @doc false
  def changeset(game, attrs) do
    game
    |> cast(attrs, [:code, :users, :status])
    |> validate_required([:code, :users, :status])
  end

  def new() do
    %Game{}
      |> changeset(%{
        code: generate_game_code(),
        users: [],
        status: :not_started
      })
      |> Repo.insert!
  end

  def join(%Game{ status: :not_started } = game, %{ username: name }) do
    updated_game = game
      |> changeset(%{
        users: [name | game.users]
      })
      |> Repo.update!

    {:ok, updated_game}
  end

  def join(_game, _args) do
    {:error, :game_already_started}
  end


  def start(%Game{ status: :in_progress }) do
    {:error, :game_already_started}
  end
  def start(%Game{ status: :completed }) do
    {:error, :game_already_started}
  end
  def start(%Game{ users: [] }) do
    {:error, :not_enough_users}
  end
  def start(%Game{ users: [_user1] }) do
    {:error, :not_enough_users}
  end
  def start(%Game{ status: :not_started } = game) do
    updated_game = game
      |> changeset(%{
        status: :in_progress
      })
      |> Repo.update!

    {:ok, updated_game}
  end
  def start(_game) do
    {:error, :not_enough_users}
  end

  defp generate_game_code() do
    1..6
      |> Enum.map(fn _ -> Enum.random(?a..?z) end)
      |> to_string
  end

end

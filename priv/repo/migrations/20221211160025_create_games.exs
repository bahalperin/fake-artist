defmodule FakeArtist.Repo.Migrations.CreateGames do
  use Ecto.Migration

  def change do
    create table(:games) do
      add :code, :string
      add :users, {:array, :string}
      add :status, :string

      unique_index(:games, :code)

      timestamps()
    end
  end
end

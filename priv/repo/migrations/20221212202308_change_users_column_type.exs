defmodule FakeArtist.Repo.Migrations.ChangeUsersColumnType do
  use Ecto.Migration

  def change do
    alter table(:games) do
      remove :users
      add_if_not_exists :users, :map
    end
  end
end

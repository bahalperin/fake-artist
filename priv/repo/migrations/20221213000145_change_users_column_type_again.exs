defmodule FakeArtist.Repo.Migrations.ChangeUsersColumnTypeAgain do
  use Ecto.Migration

  def change do
    alter table(:games) do
      remove :users
      add_if_not_exists :users, {:array, :map}
    end
  end
end

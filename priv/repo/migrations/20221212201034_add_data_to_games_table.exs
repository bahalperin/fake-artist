defmodule FakeArtist.Repo.Migrations.AddDataToGamesTable do
  use Ecto.Migration

  def change do
    alter table(:games) do
      add_if_not_exists :current_user_id, :string
      add_if_not_exists :fake_artist_id, :string
      add_if_not_exists :question_master_id, :string
      add_if_not_exists :drawing_category, :string
      add_if_not_exists :drawing_word, :string
      add_if_not_exists :drawing_state, :map
      add_if_not_exists :turns_taken, :integer
      add_if_not_exists :votes, :map
    end
  end
end

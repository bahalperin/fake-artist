defmodule FakeArtist.Game do
  use Ecto.Schema
  import Ecto.Changeset
  alias FakeArtist.Repo
  alias __MODULE__

  schema "games" do
    field :code, :string

    field :status, Ecto.Enum,
      values: [
        :not_started,
        :selecting_word,
        :drawing,
        :voting,
        :fake_artist_guessing,
        :complete
      ]

    field :current_user_id, :string
    field :fake_artist_id, :string
    field :question_master_id, :string
    field :drawing_category, :string
    field :drawing_word, :string
    field :drawing_state, {:array, :map}, on_replace: :delete
    field :turns_taken, :integer
    field :votes, :map

    embeds_many :users, FakeArtist.User, on_replace: :delete

    timestamps()
  end

  @doc false
  def changeset(game, attrs) do
    game
    |> cast(attrs, [
      :code,
      :status,
      :current_user_id,
      :fake_artist_id,
      :question_master_id,
      :drawing_category,
      :drawing_word,
      :drawing_state,
      :turns_taken,
      :votes
    ])
    |> cast_embed(:users)
    |> validate_required([:code, :status])
  end

  def new() do
    %Game{}
    |> changeset(%{
      code: generate_game_code(),
      users: [],
      status: :not_started,
      drawing_state: [],
      turns_taken: 0,
      votes: %{}
    })
    |> Repo.insert!()
  end

  def join(%Game{status: :not_started} = game, user) do
    game_users =
      game.users
      |> Enum.map(&Map.from_struct/1)

    updated_game =
      game
      |> changeset(%{
        users: [%{id: user.id, name: user.name} | game_users]
      })
      |> Repo.update!()

    game
    |> broadcast({:user_joined, user})

    {:ok, updated_game}
  end

  def join(_game, _args) do
    {:error, :game_already_started}
  end

  def leave(%Game{status: :not_started} = game, %{user_id: id}) do
    game_users =
      game.users
      |> Enum.filter(fn user -> user.id != id end)
      |> Enum.map(&Map.from_struct/1)

    updated_game =
      game
      |> changeset(%{
        users: game_users
      })
      |> Repo.update!()

    updated_game
    |> broadcast({:user_left, %{user_id: id}})

    updated_game
  end

  def leave(game, _user), do: game

  def find(%{code: code}) do
    Repo.get_by(Game, code: code)
  end

  def start(game) when length(game.users) < 3 do
    {:error, :not_enough_users}
  end

  def start(game) when length(game.users) > 10 do
    {:error, :too_many_users}
  end

  def start(%Game{status: :not_started} = game) do
    [question_master, fake_artist] =
      Enum.take_random(
        game.users,
        2
      )

    updated_game =
      game
      |> changeset(%{
        status: :selecting_word,
        question_master_id: question_master.id,
        fake_artist_id: fake_artist.id
      })
      |> Repo.update!()

    updated_game
    |> broadcast({:game_started})

    {:ok, updated_game}
  end

  def start(_game) do
    {:error, :game_already_started}
  end

  def choose_category_and_word(%Game{status: :selecting_word} = game, payload)
      when payload.user_id == game.question_master_id do
    first_player =
      game
      |> artists
      |> Enum.random()

    game =
      game
      |> changeset(%{
        drawing_category: payload.category,
        drawing_word: payload.word,
        status: :drawing,
        current_user_id: first_player.id
      })
      |> Repo.update!()

    game
    |> broadcast({:word_chosen})

    game
  end

  def choose_category_and_word(game, _payload), do: game

  def submit_drawing(%Game{status: :drawing} = game, payload)
      when payload.user_id == game.current_user_id do
    turns_taken = game.turns_taken + 1
    status = if turns_taken >= max_turns(game), do: :voting, else: game.status

    game =
      game
      |> changeset(%{
        drawing_state: [payload.drawing | game.drawing_state],
        current_user_id: game |> next_artist |> Map.get(:id),
        turns_taken: turns_taken,
        status: status
      })
      |> Repo.update!()

    game
    |> broadcast({:drawing_submitted})

    game
  end

  def submit_drawing(game, _payload), do: game

  def submit_vote(%Game{status: :voting} = game, payload) do
    updated_votes = game.votes |> Map.put(payload.user_id, payload.vote)
    vote_count = updated_votes |> map_size
    artist_count = game |> artists |> length

    game =
      game
      |> changeset(%{
        votes: updated_votes,
        status: if(vote_count == artist_count, do: :fake_artist_guessing, else: game.status)
      })
      |> Repo.update!()

    game
    |> broadcast({:vote_submitted})

    game
  end

  def submit_vote(game, _payload), do: game

  def done_guessing_word(%Game{status: :fake_artist_guessing} = game) do
    game =
      game
      |> changeset(%{
        status: :complete
      })
      |> Repo.update!()

    game
    |> broadcast({:guessing_done})

    game
  end

  def done_guessing_word(game), do: game

  def restart(%Game{status: :complete} = game) do
    game =
      game
      |> changeset(%{
        votes: %{},
        drawing_state: [],
        drawing_word: "",
        drawing_category: "",
        status: :not_started,
        current_user_id: nil,
        fake_artist_id: nil,
        question_master_id: nil,
        turns_taken: 0
      })
      |> Repo.update!()

    game
    |> broadcast({:restarted})

    game
  end

  def restart(game), do: game

  def word(game, %{user_id: id}) when game.fake_artist_id == id, do: "X"
  def word(game, _user), do: game.drawing_word

  def artist?(game, %{user_id: id}) do
    artist =
      game
      |> artists
      |> Enum.find(fn user -> user.id == id end)

    !!artist
  end

  def voted?(game, %{user_id: id}) do
    vote = game.votes |> Map.get(id)
    !!vote
  end

  def voted_for(game, %{user_id: id}) do
    artist =
      game
      |> artists
      |> Enum.find(fn artist -> artist.id == game.votes[id] end)

    if artist, do: artist.name, else: ""
  end

  def total_votes(game, %{user_id: id}) do
    game.votes
    |> Map.values()
    |> Enum.frequencies()
    |> Map.get(id)
  end

  def subscribe(game) do
    Phoenix.PubSub.subscribe(FakeArtist.PubSub, "game:#{game.code}")
  end

  defp broadcast(game, message) do
    Phoenix.PubSub.broadcast(FakeArtist.PubSub, "game:#{game.code}", message)
  end

  def artists(game) do
    game.users
    |> Enum.filter(fn user -> user.id != game.question_master_id end)
  end

  defp next_artist(game) do
    game_artists = game |> artists

    current_index =
      game_artists
      |> Enum.find_index(fn artist -> artist.id == game.current_user_id end)

    next_index = rem(current_index + 1, length(game_artists))

    Enum.at(game_artists, next_index)
  end

  defp max_turns(game) do
    game
    |> artists
    |> length
    |> Kernel.*(2)
  end

  defp generate_game_code() do
    1..6
    |> Enum.map(fn _ -> Enum.random(?a..?z) end)
    |> to_string
  end
end

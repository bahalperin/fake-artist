defmodule FakeArtist.GameTest do
  use FakeArtist.DataCase

  alias FakeArtist.Game

  describe "new" do
    test "generates a game code" do
      game = Game.new()
      assert String.length(game.code) == 6
      assert String.match?(game.code, ~r/^[[:alpha:]]+$/)
    end

    test "begins in 'not started' state" do
      game = Game.new()
      assert game.status == :not_started
    end

    test "begins without any users" do
      game = Game.new()
      assert length(game.users) == 0
    end
  end

  describe "start" do
    test "successfully starts game with enough players" do
      with {:ok, game} <- Game.new(),
           {:ok, game} <-
             game
             |> Game.join(%{username: "Ben"}),
           {:ok, game} <-
             game
             |> Game.join(%{username: "Steve"}),
           {:ok, game} =
             game
             |> Game.start() do
        assert game.status == :selecting_word
        assert game.question_master_id
        assert game.fake_artist_id
      end
    end

    test "fails to start game without enough players" do
      {:error, err} =
        Game.new()
        |> Game.start()

      assert err == :not_enough_users
    end

    test "fails to start game in invalid states" do
      {:error, err} =
        %Game{status: :in_progress}
        |> Game.start()

      assert err == :game_already_started
    end
  end

  describe "join" do
    test "successful when game has not started" do
      test_user = %{
        id: "an_id",
        name: "Ben"
      }

      {:ok, game} =
        Game.new()
        |> Game.join(test_user)

      assert length(game.users) == 1
      assert test_user.id == game.users |> Enum.at(0) |> Map.get(:id)
    end

    test "unsuccessful when game is in progress" do
      test_user = "Ben"

      {:error, :game_already_started} =
        Game.new()
        |> Game.start()
        |> Game.join(%{username: test_user})
    end
  end

  describe "choose_category_and_word" do
    test "successful when game is in correct state and selection comes from QM" do
      game =
        example_game(%{
          status: :selecting_word
        })
        |> Game.choose_category_and_word(%{
          user_id: "qm_id",
          word: "apple",
          category: "food"
        })

      assert game.status == :drawing
      assert game.drawing_word == "apple"
      assert game.drawing_category == "food"
    end

    test "does nothing if selection comes from another user" do
      game =
        example_game(%{
          status: :selecting_word
        })
        |> Game.choose_category_and_word(%{
          user_id: "artist_1",
          word: "apple",
          category: "food"
        })

      assert game.status == :selecting_word
      assert is_nil(game.drawing_word)
      assert is_nil(game.drawing_category)
    end

    test "does nothing if game is in incorrect state" do
      game =
        example_game()
        |> Game.choose_category_and_word(%{
          user_id: "qm_id",
          word: "apple",
          category: "food"
        })

      assert game.status == :not_started
      assert is_nil(game.drawing_word)
      assert is_nil(game.drawing_category)
    end
  end

  describe "submit_drawing" do
    test "updates drawing state, increments turns taken, and changes current user" do
      game =
        example_game(%{
          status: :drawing,
          current_user_id: "artist_1"
        })
        |> Game.submit_drawing(%{
          user_id: "artist_1",
          drawing: %{ "artist_1" => "done"}
        })

      assert game.turns_taken == 1
      assert game.drawing_state["artist_1"] == "done"
      assert game.current_user_id == "artist_2"
    end

    test "does nothing if not in drawing state" do
      game =
        example_game(%{
          current_user_id: "artist_1"
        })
        |> Game.submit_drawing(%{
          user_id: "artist_1",
          drawing: %{ "artist_1" => "done"}
        })

      assert game.turns_taken == 0
      assert is_nil(game.drawing_state)
    end

    test "does nothing if player plays out of turn" do
      game =
        example_game(%{
          status: :drawing,
          current_user_id: "artist_1"
        })
        |> Game.submit_drawing(%{
          user_id: "artist_2",
          drawing: %{ "artist_2" => "done"}
        })

      assert game.turns_taken == 0
      assert is_nil(game.drawing_state)
    end

    test "when every artist has gone twice, moves to voting" do
      game =
        example_game(%{
          status: :drawing,
          turns_taken: 7,
          current_user_id: "artist_3"
        })
        |> Game.submit_drawing(%{
          user_id: "artist_3",
          drawing: %{ "artist_3" => "done"}
        })

      assert game.status == :voting
      assert game.turns_taken == 8
      assert game.drawing_state["artist_3"] == "done"
    end
  end

  describe "submit_vote" do
    test "updates player's vote" do
      game =
        example_game(%{
          status: :voting,
        })
        |> Game.submit_vote(%{
          user_id: "artist_1",
          vote: "artist_3"
        })

      assert game.votes["artist_1"] == "artist_3"
      assert game.status == :voting
    end

    test "moves to fake_artist_guessing when all votes are in" do
      game =
        example_game(%{
          status: :voting,
          votes: %{
            "artist_2" => "artist_3",
            "artist_3" => "fa_id",
            "fa_id" => "artist_3"
          }
        })
        |> Game.submit_vote(%{
          user_id: "artist_1",
          vote: "artist_3"
        })

      assert game.status === :fake_artist_guessing
      assert game.votes["artist_1"] == "artist_3"
    end

    test "does nothing if not in voting state" do
      game =
        example_game(%{
          status: :drawing,
          current_user_id: "artist_1"
        })
        |> Game.submit_vote(%{
          user_id: "artist_1",
          vote: "artist_3"
        })

      assert map_size(game.votes) == 0
    end
  end

  describe "done_guessing_word" do
    test "moves to complete state" do
      game =
        example_game(%{
          status: :fake_artist_guessing,
        })
        |> Game.done_guessing_word()

      assert game.status == :complete
    end

    test "does nothing if not in guessing state" do
      game =
        example_game(%{
          status: :drawing,
        })
        |> Game.done_guessing_word()

      assert game.status == :drawing
    end
  end

  defp example_game(attrs \\ %{}) do
    %Game{}
    |> Game.changeset(
      Map.merge(
        %{
          code: "abcdef",
          status: :not_started,
          question_master_id: "qm_id",
          fake_artist_id: "fa_id",
          turns_taken: 0,
          votes: %{},
          users: [
            %{
              id: "qm_id",
              name: "Question Master"
            },
            %{
              id: "fa_id",
              name: "Fake Artist"
            },
            %{
              id: "artist_1",
              name: "Artist 1"
            },
            %{
              id: "artist_2",
              name: "Artist 2"
            },
            %{
              id: "artist_3",
              name: "Artist 3"
            }
          ]
        },
        attrs
      )
    )
    |> Repo.insert!()
  end
end

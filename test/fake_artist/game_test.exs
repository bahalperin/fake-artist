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

        assert game.status == :in_progress
      end
    end

    test "fails to start game without enough players" do
      {:error, err} = Game.new()
        |> Game.start()

      assert err == :not_enough_users
    end

    test "fails to start game in invalid states" do
      {:error, err} = %Game{ status: :in_progress}
        |> Game.start()

      assert err == :game_already_started
    end
  end

  describe "join" do
    test "successful when game has not started" do
      test_user = "Ben"

      {:ok, game} =
        Game.new()
        |> Game.join(%{username: test_user})

      assert game.users |> Enum.member?(test_user)
    end

    test "unsuccessful when game is in progress" do
      test_user = "Ben"

      {:error, :game_already_started} =
        Game.new()
        |> Game.start()
        |> Game.join(%{username: test_user})
    end
  end
end

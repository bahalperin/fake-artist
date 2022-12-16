defmodule FakeArtist.Jobs.CleanUpOldGames do
  use GenServer
  alias FakeArtist.Game

  @interval_ms 6 * 60 * 60 * 1000

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{})
  end

  def init(state) do
    schedule_work()
    {:ok, state}
  end

  def handle_info(:work, state) do
    Game.delete_expired()

    schedule_work()
    {:noreply, state}
  end

  defp schedule_work() do
    Process.send_after(self(), :work, @interval_ms)
  end
end

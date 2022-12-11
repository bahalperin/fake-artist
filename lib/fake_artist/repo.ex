defmodule FakeArtist.Repo do
  use Ecto.Repo,
    otp_app: :fake_artist,
    adapter: Ecto.Adapters.Postgres
end

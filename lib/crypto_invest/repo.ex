defmodule CryptoInvest.Repo do
  use Ecto.Repo,
    otp_app: :crypto_invest,
    adapter: Ecto.Adapters.Postgres
end

defmodule CryptoInvest.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      CryptoInvestWeb.Telemetry,
      CryptoInvest.Repo,
      {DNSCluster, query: Application.get_env(:crypto_invest, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: CryptoInvest.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: CryptoInvest.Finch},
      # Start a worker by calling: CryptoInvest.Worker.start_link(arg)
      # {CryptoInvest.Worker, arg},
      # Start to serve requests, typically the last entry
      CryptoInvestWeb.Endpoint
    ]
    :ets.new(:user_states, [:named_table, :public, :set])

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: CryptoInvest.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    CryptoInvestWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end

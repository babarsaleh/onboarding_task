import Config

# Configure your database
config :crypto_invest, CryptoInvest.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "crypto_invest_dev",
  stacktrace: true,
  show_sensitive_data_on_connection_error: true,
  pool_size: 10

# For development, we disable any cache and enable
# debugging and code reloading.
config :crypto_invest, CryptoInvestWeb.Endpoint,
  # Binding to loopback ipv4 address prevents access from other machines.
  # Change to `ip: {0, 0, 0, 0}` to allow access from other machines.
  http: [ip: {127, 0, 0, 1}, port: 4000],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  secret_key_base: "VmCcAeYn+XD55jf+8Dy3/pm581m7oXZqwZvQWY/gvIffq7zSUmByt64+CVd+giAi",
  watchers: [
    esbuild: {Esbuild, :install_and_run, [:crypto_invest, ~w(--sourcemap=inline --watch)]},
    tailwind: {Tailwind, :install_and_run, [:crypto_invest, ~w(--watch)]}
  ],
  https: [
    port: 4001,
    cipher_suite: :strong,
    keyfile: "priv/cert/selfsigned_key.pem",
    certfile: "priv/cert/selfsigned.pem"
  ]

# Watch static and templates for browser reloading.
config :crypto_invest, CryptoInvestWeb.Endpoint,
  live_reload: [
    patterns: [
      ~r"priv/static/(?!uploads/).*(js|css|png|jpeg|jpg|gif|svg)$",
      ~r"priv/gettext/.*(po)$",
      ~r"lib/crypto_invest_web/(controllers|live|components)/.*(ex|heex)$"
    ]
  ]

# Enable dev routes for dashboard and mailbox
config :crypto_invest, dev_routes: true

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n"

# Set a higher stacktrace during development. Avoid configuring such
# in production as building large stacktraces may be expensive.
config :phoenix, :stacktrace_depth, 20

# Initialize plugs at runtime for faster development compilation
config :phoenix, :plug_init_mode, :runtime

config :phoenix_live_view,
  # Include HEEx debug annotations as HTML comments in rendered markup
  debug_heex_annotations: true,
  # Enable helpful, but potentially expensive runtime checks
  enable_expensive_runtime_checks: true

# Disable swoosh API client as it is only required for production adapters.
config :swoosh, :api_client, false

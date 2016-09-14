use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :resolutionizer, Resolutionizer.Endpoint,
  http: [port: 4001],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

# Configure your database
config :resolutionizer, Resolutionizer.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "resolutionizer",
  password: "resolutionizer_pass",
  database: "resolutionizer_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox

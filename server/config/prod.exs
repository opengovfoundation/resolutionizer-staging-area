use Mix.Config

# For production, we configure the host to read the PORT
# from the system environment. Therefore, you will need
# to set PORT=80 before running your server.
#
# You should also configure the url host to something
# meaningful, we use this information when generating URLs.
config :resolutionizer, Resolutionizer.Endpoint,
  http: [port: {:system, "PORT"}],
  url: [host: "example.com", port: 80],
  server: true,
  root: ".",
  version: Mix.Project.config[:version]

# Do not print debug messages in production
config :logger, level: :info

config :resolutionizer, Resolutionizer.Repo,
  adapter: Ecto.Adapters.Postgres,
  url: {:system, "DBURL"}

config :arc,
  bucket: {:system, "S3_BUCKET"}

import_config "prod.secret.exs"

import Config

config :logger, :console, metadata: [:request_id]

import_config("#{config_env()}.exs")

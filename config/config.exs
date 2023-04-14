import Config

config :logger, level: :debug
config :logger, :console,
       format: "[$level] [$metadata] $message \n",
       metadata: [:error_code, :channel]
import Config

config :logger, level: :debug
config :logger, :console,
       format: {LogFormat, :format},
       metadata: [:error_code, :mfa, :channel, :bot_name]
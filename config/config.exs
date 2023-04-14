import Config

config :chat_bot,
       ecto_repos: [KueaListeBot.Repo]

config :logger, level: :debug
config :logger, :console,
       format: "[$level] [$metadata] $message \n",
       metadata: [:error_code, :channel]

if Mix.env == :test do
  config :chat_bot, KueaListeBot.Repo,
         database: "elixirdb_test",
         username: "elixir",
         password: "elixir",
         hostname: "localhost",
         port: "5432",
         pool: Ecto.Adapters.SQL.Sandbox
else
  config :chat_bot, KueaListeBot.Repo,
         database: "elixirdb",
         username: "elixir",
         password: "elixir",
         hostname: "localhost",
         port: "5432"
end

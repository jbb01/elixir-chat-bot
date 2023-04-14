defmodule ChatBot do
  use Application

  def start(_, _args) do
    config = File.read!("config.json")
    |> JSON.decode!()

    channels = Map.get(config, "channels")
    bots = Map.get(config, "bots")
    |> Enum.map(&parse_bot_config/1)

    children = [
      # Bots
      ChatBot.BotState,
      {Registry, keys: :unique, name: ChatBot.Bot.ViaName},
      ChatBot.BotSupervisor,
      {ChatBot.BotManager, bots: bots},

      # Sockets
      {Registry, keys: :unique, name: ChatBot.Socket.ViaChannel},
      ChatBot.SocketSupervisor,
      {ChatBot.SocketManager, channels: channels}
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end

  defp parse_bot_config(bot_config) when is_map(bot_config) do
    module = case Map.get(bot_config, "module") do
      module when is_atom(module) ->
        module
      module_name when is_binary(module_name) ->
        String.to_existing_atom("Elixir." <> module_name)
    end

    name = Map.get(bot_config, "name", module)
    channels = case Map.get(bot_config, "channels") do
      channel when is_binary(channel) ->
        [channel]
      channels when is_list(channels) ->
        channels
      _ ->
        nil
    end

    {module, name, nil, channels: channels}
  end
end

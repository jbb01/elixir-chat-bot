defmodule ChatBot do
  use Application

  @bots [
    {EchoBot, EchoBot, nil, channels: ["test"]},
    {PingBot, EchoBot, nil, channels: ["test"]},
    {PizzaBot, PizzaBot, nil, channels: ["marek"]}
  ]
  @channels ["marek", "test"]

  def start(_, _args) do
    children = [
      # Bots
      ChatBot.BotState,
      {Registry, keys: :unique, name: ChatBot.Bot.ViaName},
      ChatBot.BotSupervisor,
      {ChatBot.BotManager, bots: @bots},

      # Sockets
      {Registry, keys: :unique, name: ChatBot.Socket.ViaChannel},
      ChatBot.SocketSupervisor,
      {ChatBot.SocketManager, channels: @channels}
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end

defmodule ChatBot.BotManager do
  use GenServer

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl true
  def init(bots: bots) do
    bots
    |> Enum.each(fn bot ->
      case bot do
        module when is_atom(module) ->
          ChatBot.BotSupervisor.start_bot(module)
        {module, name} when is_atom(module) ->
          ChatBot.BotSupervisor.start_bot(module, name)
        {module, name, args} when is_atom(module) ->
          ChatBot.BotSupervisor.start_bot(module, name, args)
        {module, name, args, opts} when is_atom(module) and is_list(opts) ->
          channels = Keyword.get(opts, :channels)
          ChatBot.BotSupervisor.start_bot(module, name, args)
          ChatBot.BotState.set_channel_whitelist(name, channels)
      end
    end)
    {:ok, nil}
  end


  @impl true
  def handle_call({:start, module}, _from, state) when is_atom(module) do
    result = ChatBot.BotSupervisor.start_bot(module)
    {:reply, result, state}
  end

  @impl true
  def handle_call({:start, module, name}, _from, state) when is_atom(module) do
    result = ChatBot.BotSupervisor.start_bot(module, name)
    {:reply, result, state}
  end

  @impl true
  def handle_call({:stop, name}, _from, state) do
    result = ChatBot.BotSupervisor.stop_bot(name)
    {:reply, result, state}
  end

  @impl true
  def handle_call({:restrict, name, channels}, _from, state) when is_list(channels) or is_nil(channels) do
    case Registry.lookup(ChatBot.Bot.ViaName, name) do
      [] ->
        {:reply, {:error, :not_found}, state}
      [{_pid, _}] ->
        ChatBot.BotState.set_channel_whitelist(name, channels)
        {:reply, :ok, state}
    end
  end

  @impl true
  def handle_call({:restrict, name, channel}, from, state) when is_binary(channel) do
    handle_call({:restrict, name, [channel]}, from, state)
  end

  @impl true
  def handle_call(:list, _from, state) do
    result = ChatBot.BotSupervisor.list_bots()
    {:reply, result, state}
  end
end
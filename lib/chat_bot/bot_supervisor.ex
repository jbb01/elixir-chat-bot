defmodule ChatBot.BotSupervisor do
  use DynamicSupervisor

  @spec start_link(any) :: any
  def start_link(_) do
    DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @impl true
  @spec init(_init_arg :: :ok) :: any
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  @spec start_bot(module :: module) :: DynamicSupervisor.on_start_child()
  def start_bot(module) when is_atom(module) do
    start_bot(module, module)
  end

  @spec start_bot(module :: module, name :: term) :: DynamicSupervisor.on_start_child()
  @spec start_bot(module :: module, name :: term, args :: term) :: DynamicSupervisor.on_start_child()
  def start_bot(module, name, args \\ nil) when is_atom(module) do
    DynamicSupervisor.start_child(__MODULE__, bot_spec(module, name, args))
  end

  @spec stop_bot(name :: term) :: :ok | {:error, :not_found}
  def stop_bot(name) do
    processes = Registry.lookup(ChatBot.Bot.ViaName, name)
    if [] == processes do
      {:error, :not_found}
    else
      processes
      |> Enum.each(fn {pid, _} -> DynamicSupervisor.terminate_child(__MODULE__, pid) end)
    end
  end

  @spec list_bots() :: [{pid :: pid, module :: module, name :: term, channels :: [String.t()] | nil}]
  def list_bots() do
    Supervisor.which_children(ChatBot.BotSupervisor)
    |> Enum.map(fn {_, pid, _, [module | _]} ->
      name = Registry.keys(ChatBot.Bot.ViaName, pid) |> List.first
      channels = ChatBot.BotState.get_channel_whitelist(name)
      {pid, module, name, channels}
    end)
  end

  defp bot_spec(module, name, args) when is_atom(module) do
    module
    |> Supervisor.child_spec(
         id: name,
         restart: :transient,
         start: {module, :start_link, [bot_name(name), args]}
       )
  end

  def bot_name(name) do
    {:via, Registry, {ChatBot.Bot.ViaName, name}}
  end
end

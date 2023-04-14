defmodule ChatBot.SocketManager do
  use GenServer

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl true
  def init(channels: channels) do
    channels |> Enum.each(&ChatBot.SocketSupervisor.start_socket/1)
    {:ok, nil}
  end

  @impl true
  @spec handle_call({:start, channels :: [String.t()]}, from :: any, state :: nil) :: {:reply, [DynamicSupervisor.on_start_child()], nil}
  def handle_call({:start, channels}, _from, state) when is_list(channels) do
    result = channels
    |> Enum.each(&ChatBot.SocketSupervisor.start_socket/1)
    {:reply, result, state}
  end

  @impl true
  @spec handle_call({:start, channel :: String.t()}, from :: any, state :: nil) :: {:reply, DynamicSupervisor.on_start_child(), nil}
  def handle_call({:start, channel}, _from, state) when is_binary(channel) do
    result = ChatBot.SocketSupervisor.start_socket(channel)
    {:reply, result, state}
  end

  @impl true
  @spec handle_call({:stop, channel :: String.t()}, from :: any, state :: nil) :: {:reply, :ok | {:error, :not_found}, nil}
  def handle_call({:stop, channel}, _from, state) when is_binary(channel) do
    result = ChatBot.SocketSupervisor.stop_socket(channel)
    {:reply, result, state}
  end

  @impl true
  def handle_call(:list, _from, state) do
    result = ChatBot.SocketSupervisor.list_sockets()
    {:reply, result, state}
  end
end

defmodule ChatBot.SocketManager do
  @moduledoc """
  Provides a GenServer-based API to manage chat sockets.

  ## Examples

      iex> GenServer.call(ChatBot.SocketManager, :list)
      [{#PID<0.267.0>, "test"}, {#PID<0.272.0>, "elixir"}]

      iex> GenServer.call(ChatBot.SocketManager, {:start, "foo"})
      {:ok, #PID<0.292.0>}

      iex> GenServer.call(ChatBot.SocketManager, {:stop, "foo"})
      :ok

      iex> GenServer.call(ChatBot.SocketManager, {:stop, "bar"})
      {:error, :not_found}
  """

  use GenServer
  require Logger

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl true
  def init(channels: channels) do
    {:ok, nil, {:continue, channels}}
  end

  @impl true
  def handle_continue(channels, state) do
    channels |> Enum.each(&do_start/1)
    {:noreply, state}
  end

  @impl true
  @spec handle_call({:start, channels :: [String.t()]}, from :: any, state :: nil) :: {:reply, [DynamicSupervisor.on_start_child()], nil}
  def handle_call({:start, channels}, _from, state) when is_list(channels) do
    result = channels
    |> Enum.each(&do_start/1)
    {:reply, result, state}
  end

  @impl true
  @spec handle_call({:start, channel :: String.t()}, from :: any, state :: nil) :: {:reply, DynamicSupervisor.on_start_child(), nil}
  def handle_call({:start, channel}, _from, state) when is_binary(channel) do
    result = do_start(channel)
    {:reply, result, state}
  end

  @impl true
  @spec handle_call({:stop, channel :: String.t()}, from :: any, state :: nil) :: {:reply, :ok | {:error, :not_found}, nil}
  def handle_call({:stop, channel}, _from, state) when is_binary(channel) do
    result = ChatBot.SocketSupervisor.stop_socket(channel)
    {:reply, result, state}
  end

  @impl true
  @spec handle_call(:list, from :: any, state :: nil) :: {:reply, [{pid :: pid, channel :: String.t()}], nil}
  def handle_call(:list, _from, state) do
    result = ChatBot.SocketSupervisor.list_sockets()
    {:reply, result, state}
  end

  @spec do_start(channel :: String.t()) :: DynamicSupervisor.on_start_child()
  defp do_start(channel) do
    case ChatBot.SocketSupervisor.start_socket(channel) do
      {:error, cause} = result ->
        Logger.error("Failed to start socket for channel " <> JSON.encode!(channel) <> ": " <> inspect(cause))
        result
      result ->
        result
    end
  end
end

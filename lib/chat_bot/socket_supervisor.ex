defmodule ChatBot.SocketSupervisor do
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

  @spec start_socket(channel :: String.t()) :: DynamicSupervisor.on_start_child()
  def start_socket(channel) when is_binary(channel) do
    DynamicSupervisor.start_child(__MODULE__, socket_spec(channel))
  end

  @spec stop_socket(channel :: String.t()) :: :ok | {:error, :not_found}
  def stop_socket(channel) when is_binary(channel) do
    processes = Registry.lookup(ChatBot.Socket.ViaChannel, channel)
    if [] == processes do
      {:error, :not_found}
    else
      processes
      |> Enum.each(fn {pid, _} -> DynamicSupervisor.terminate_child(__MODULE__, pid) end)
    end
  end

  @spec restart_socket(channel :: String.t()) :: DynamicSupervisor.on_start_child()
  def restart_socket(channel) when is_binary(channel) do
    stop_socket(channel)
    start_socket(channel)
  end

  @spec list_sockets() :: [{pid :: pid, channel :: String.t()}]
  def list_sockets() do
    Supervisor.which_children(ChatBot.SocketSupervisor)
    |> Enum.map(fn {_, pid, _, _} ->
      channel = Registry.keys(ChatBot.Socket.ViaChannel, pid) |> List.first
      {pid, channel}
    end)
  end

  @spec socket_spec(channel :: String.t()) :: any
  defp socket_spec(channel) when is_binary(channel) do
    {ChatBot.Socket, channel: channel}
    |> Supervisor.child_spec(id: socket_id(channel), restart: :transient)
  end

  @spec socket_id(channel :: String.t()) :: {atom, String.t()}
  def socket_id(channel) when is_binary(channel) do
    {ChatBot.Socket, channel}
  end

  def socket_name(channel) when is_binary(channel) do
    {:via, Registry, {ChatBot.Socket.ViaChannel, channel}}
  end
end

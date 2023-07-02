alias ChatBot.SocketState

defmodule ChatBot.Socket do
  require Logger
  use WebSockex

  @url "wss://chat.qed-verein.de/websocket?position=0&version=2"

  @type message :: %{
    :name => String.t(),
    :message => String.t(),
    optional(:bottag) => integer | boolean,
    optional(:public_id) => integer | boolean
  }

  @spec start_link(channel: String.t()) :: {:ok, pid} | {:error, term}
  def start_link(channel: channel) do
    {user_id, pwhash} = ChatBot.LoginHelper.login()

    extra_headers = [
      {"Origin", "https://chat.qed-verein.de"},
      {"Cookie", "userid=#{user_id}; pwhash=#{pwhash}"}
    ]

    WebSockex.start_link(
      @url <> "&channel=" <> channel,
      __MODULE__,
      %SocketState{channel: channel},
      extra_headers: extra_headers,
      name: ChatBot.SocketSupervisor.socket_name(channel)
    )
  end

  @impl true
  @spec handle_connect(conn :: WebSockex.Conn.t(), state :: SocketState.t()) :: {:ok, SocketState.t()}
  def handle_connect(_conn, state) do
    Logger.metadata channel: state.channel
    Logger.info "Web socket connected."
    schedule_ping()
    {:ok, state}
  end


  @impl true
  @spec handle_cast({:send, {:message, message}}, SocketState.t()) :: {:reply, {:text, String.t()}, SocketState.t()}
  def handle_cast({:send, {:message, %{name: name, message: message} = opts}}, state) do
    bottag = case Map.get(opts, :bottag, 1) do
      x when is_integer(x) -> x
      true -> 1
      false -> 0
    end

    public_id = case Map.get(opts, :public_id, 1) do
      x when is_integer(x) -> x
      true -> 1
      false -> 0
    end

    frame = {:text, JSON.encode!(
      channel: state.channel,
      name: name,
      message: message,
      delay: state.delay + 1,
      bottag: bottag,
      type: "post",
      publicid: public_id
    )}

    {:reply, frame, state}
  end

  @impl true
  @spec handle_frame({:text, String.t()}, SocketState.t()) :: {:ok, term}
  def handle_frame({:text, msg}, state) do
    {:ok, handle_message(JSON.decode!(msg), state)}
  end

  @impl true
  @spec terminate(%{reason: WebSockex.close_reason() | WebSockex.close_error()}, SocketState.t()) :: term
  def handle_disconnect(%{reason: reason}, state) do
    Logger.warn("Web socket disconnected. (attempt=#{state.reconnect}, reason=#{inspect(reason)})")
    if state.reconnect < 4 do
      case state.reconnect do
        0 -> Process.sleep(1_000)
        1 -> Process.sleep(5_000)
        2 -> Process.sleep(10_000)
        3 -> Process.sleep(20_000)
      end

      {:reconnect, SocketState.increment_reconnect(state)}
    else
      {:ok, state}
    end
  end

  @impl true
  @spec terminate(WebSockex.close_reason(), SocketState.t()) :: term
  def terminate(close_reason, _state) do
    Logger.error("Web socket terminated. (reason=#{inspect(close_reason)})")
  end

  defp handle_message(%{"type" => "post", "message" => text, "name" => name, "delay" => delay} = message, state)
       when is_binary(text) and is_binary(name) and is_integer(delay) do
    Logger.info(JSON.encode!(name) <> ": " <> JSON.encode!(text))

    msg = parse_message(message)

    Supervisor.which_children(ChatBot.BotSupervisor)
    |> Enum.map(fn ({_id, pid, _type, _modules}) -> pid end)
    |> Enum.filter(&is_pid/1)
    |> Enum.each(fn pid -> GenServer.cast(pid, msg) end)

    SocketState.update_delay(state, delay)
  end

  defp handle_message(%{"type" => "ack"}, state), do: SocketState.reset_reconnect(state)

  defp handle_message(%{"type" => "pong"}, state), do: SocketState.reset_reconnect(state)

  defp handle_message(_message, state), do: state

  defp parse_message(message) do
    %ChatBot.Message{
      id: Map.get(message, "id"),
      name: Map.get(message, "name"),
      message: Map.get(message, "message"),
      channel: Map.get(message, "channel"),
      date: Map.get(message, "date"),
      delay: Map.get(message, "delay"),
      user_id: Map.get(message, "user_id", nil),
      user_name: Map.get(message, "username", nil),
      color: Map.get(message, "color"),
      bottag: Map.get(message, "bottag", 0)
    }
  end

  @doc """
  Sends a given `message` under the given `name` to a given `channel`. Arguments can be provided either as a keyword list
  or as a map.

  ## Examples

      iex> ChatBot.Socket.send_message(name: "Max Mustermann", channel: "test", message: "Hello World")
      :ok

  """
  @spec send_message(name: String.t(), message: String.t(), channel: String.t()) :: :ok
  @spec send_message(%{name: String.t(), message: String.t(), channel: String.t()}) :: :ok
  def send_message(opts) when is_list(opts) do
    send_message(opts |> Enum.into(%{}))
  end

  def send_message(%{name: _, message: _, channel: channel} = opts) do
    ChatBot.SocketSupervisor.socket_name(channel)
    |> WebSockex.cast({:send, {:message, opts}})
  end


  @impl true
  @spec handle_info({:send, :ping}, SocketState.t()) :: {:reply, {:text, String.t()}, SocketState.t()}
  def handle_info({:send, :ping}, state) do
    frame = {:text, JSON.encode!(type: "ping")}
    schedule_ping()
    {:reply, frame, state}
  end

  defp schedule_ping() do
    Process.send_after(self(), {:send, :ping}, 30_000)
  end
end

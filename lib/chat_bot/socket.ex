alias ChatBot.SocketState

defmodule ChatBot.Socket do
  require Logger
  use WebSockex

  @url "wss://chat.qed-verein.de/websocket?position=0&version=2"

  @type message :: %{name: String.t(), message: String.t()}

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

    frame = {:text, JSON.encode!(
      channel: state.channel,
      name: name,
      message: message,
      delay: state.delay + 1,
      bottag: bottag,
      type: "post"
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
    Logger.info("Web socket disconnected. (attempt=#{state.reconnect}, reason=#{inspect(reason)})")
    if state.reconnect < 2 do
      {:reconnect, SocketState.increment_reconnect(state)}
    else
      {:ok, state}
    end
  end

  @impl true
  @spec terminate(WebSockex.close_reason(), SocketState.t()) :: term
  def terminate(close_reason, _state) do
    Logger.info("Web socket terminated. (reason=#{inspect(close_reason)})")
  end

  defp handle_message(%{"type" => "post", "message" => text, "delay" => delay} = message, state) do
    Logger.info("Received Message - " <> text)

    msg = parse_message(message)

    Supervisor.which_children(ChatBot.BotSupervisor)
    |> Enum.map(fn ({_id, pid, _type, _modules}) -> pid end)
    |> Enum.filter(&is_pid/1)
    |> Enum.each(fn pid -> GenServer.cast(pid, msg) end)

    SocketState.update_delay(state, delay)
  end

  defp handle_message(%{"type" => "ack"}, state) do
    SocketState.reset_reconnect(state)
  end

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
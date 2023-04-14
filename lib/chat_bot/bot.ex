defmodule ChatBot.Bot do
  @callback handle_message(message :: ChatBot.Message.t(), state :: term) :: {new_state :: term}

  @spec __using__(name: String.t()) :: Macro.t()
  defmacro __using__([{:name, botname} | _ ] = opts) do
    ignore_bots = Keyword.get(opts, :ignore_bots, true)
    no_bottag = Keyword.get(opts, :no_bottag, false)

    quote do
      use GenServer
      @behaviour ChatBot.Bot
      @before_compile ChatBot.Bot

      def start_link(name, init_arg) do
        GenServer.start_link(__MODULE__, init_arg, name: name)
      end

      @impl true
      @spec handle_cast(message :: ChatBot.Message.t(), state :: term) :: term
      def handle_cast(message, state) do
        if unquote(ignore_bots) and message.bottag != 0 do
          {:noreply, state}
        else
          whitelist = ChatBot.BotState.get_channel_whitelist(get_name())
          if is_list(whitelist) and message.channel not in whitelist do
            {:noreply, state}
          else
            ChatBot.BotState.set_channel(get_name(), message.channel)
            result = handle_message(message, state)
            ChatBot.BotState.set_channel(get_name(), nil)
            {:noreply, result}
          end
        end
      end

      @spec post(message :: String.t()) :: :ok
      @spec post(name :: String.t(), message :: String.t()) :: :ok
      def post(name \\ unquote(botname), message, opts \\ []) do
        channel = ChatBot.BotState.get_channel(get_name())
        bottag = unquote(if no_bottag, do: false, else: true)

        ChatBot.Socket.send_message(Keyword.merge([channel: channel, name: name, message: message, bottag: bottag], opts))
      end

      defp get_name() do
        [name] = Registry.keys(ChatBot.Bot.ViaName, self())
        name
      end
    end
  end

  @spec __before_compile__(any) :: Macro.t()
  defmacro __before_compile__(_) do
    quote(generated: true) do
      def handle_message(_, state), do: state
    end
  end
end

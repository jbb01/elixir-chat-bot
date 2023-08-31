defmodule ChatBot.Bot do
  @moduledoc """
  A behaviour module for implementing a chat bot.

  ## Example

      defmodule GreetingBot do
        use ChatBot.Bot, name: "Greetings"

        @impl true
        def handle_message(%{name: name, message: _message}, state) do
          post("Hello, " <> name <> "!")
        end
      end
  """

  @callback handle_message(message :: ChatBot.Message.t(), state :: term) :: {new_state :: term}

  @typedoc """
  Supported options when using this behavior.

  - `name` (required): the default nickname that will be used when this bot makes a post
  - `ignore_bots` (optional, default `true`): whether `handle_message` should be called for messages sent from bots.
    When setting this to `false` care should be taken to prevent this bot from replying to its own messages.
  - `bottag` (optional, default `true`): whether to set the bottag. This can be overridden for a single post by
    providing appropriate arguments to the `post` function.
  - `public_id` (optional, default: `true`): whether to post with public id. This can be overridden for a single post by
    providing appropriate arguments to the `post` function.
  """
  @type option :: {:name, String.t()} | {:ignore_bots, boolean} | {:bottag, boolean} | {:public_id, boolean}

  @spec __using__([option]) :: Macro.t()
  defmacro __using__([{:name, bot_name} | _ ] = opts) do
    ignore_bots = Keyword.get(opts, :ignore_bots, true)
    bottag = Keyword.get(opts, :bottag, true)
    public_id = Keyword.get(opts, :public_id, true)

    quote do
      use GenServer
      require Logger

      @behaviour ChatBot.Bot
      @before_compile ChatBot.Bot

      @bot_name unquote(bot_name)

      def init({:__init_bot__, name, init_arg}) do
        Logger.metadata(bot_nick_name: unquote(bot_name))

        name_str = fn
          __MODULE__ -> ""
          obj -> " as " <> inspect(obj)
        end
        message = &("Starting bot " <> inspect(__MODULE__) <> name_str.(&1) <> " with options " <> inspect(unquote(opts)))

        case name do
          {:via, Registry, {ChatBot.Bot.ViaName, via}} ->
            Logger.metadata(bot_name: via)
            Logger.info(message.(via))
          _ ->
            Logger.metadata(bot_name: name)
            Logger.info(message.(name))
        end

        init(init_arg)
      end

      def start_link(name, init_arg) do
        GenServer.start_link(__MODULE__, {:__init_bot__, name, init_arg}, name: name)
      end

      @impl true
      @spec handle_cast(message :: ChatBot.Message.t(), state :: term) :: term
      def handle_cast(message, state) do
        if unquote(ignore_bots) and message.bottag != 0 do
          {:noreply, state}
        else
          whitelist = ChatBot.BotState.get_channel_whitelist(get_name())
          if is_list(whitelist) and String.downcase(message.channel) not in whitelist do
            {:noreply, state}
          else
            ChatBot.BotState.set_channel(self(), message.channel)
            result = handle_message(message, state)
            ChatBot.BotState.set_channel(self(), nil)
            {:noreply, result}
          end
        end
      end

      @doc """
      Posts a given `message`. This method should only be called from within `&handle_message/2`.

      By default, the message will be posted to the channel the currently handled
      message was received using name "#{unquote(bot_name)}".
      The bottag will #{unquote(if bottag, do: "", else: "not ")}be set by default.
      Public ID will #{unquote(if public_id, do: "", else: "not ")}be set by default.

      ## Example

          def handle_message(%{channel: channel}, state) do
            post("Hello World!") # Posts "Hello World!" to the current channel using name "#{unquote(bot_name)}"
            post("Bob", "I'm Bob!") # Posts "I'm Bob!" to the current channel using name "Bob"
            post("Charlie", "I'm Charlie!", bottag: false, public_id: false, channel: "foo") # Posts "I'm Charlie!" to the channel "foo" using the name "Charlie", without setting bottag or public_id
          end
      """
      @spec post(message :: String.t()) :: :ok
      @spec post(name :: String.t(), message :: String.t()) :: :ok
      def post(name \\ @bot_name, message, opts \\ []) do
        channel = ChatBot.BotState.get_channel(self())
        bottag = unquote(bottag)
        public_id = unquote(public_id)

        ChatBot.Socket.send_message(Keyword.merge([
          channel: channel,
          name: name,
          message: message,
          bottag: bottag,
          public_id: public_id
        ], opts))
      end

      @spec get_name() :: String.t()
      defp get_name() do
        ChatBot.Bot.get_name(self())
      end
    end
  end

  @spec __before_compile__(any) :: Macro.t()
  defmacro __before_compile__(_env) do
    quote(generated: true) do
      def handle_message(_, state), do: state

      def init(init_arg), do: {:ok, init_arg}
    end
  end

  def get_name(pid) when is_pid(pid) do
    [name] = Registry.keys(ChatBot.Bot.ViaName, pid)
    name
  end
end

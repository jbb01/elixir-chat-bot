defmodule ChatBot.Command do
  @callback handle_command(command :: OptionParser.argv(), message :: ChatBot.Message.t(), state :: term) :: {new_state :: term}

  @spec __using__(name: String.t()) :: Macro.t()
  defmacro __using__(args) do
    quote do
      use ChatBot.Bot, unquote(args)
      @behaviour ChatBot.Command
      @before_compile ChatBot.Command

      @impl true
      def handle_message(message, state) do
        OptionParser.split(message.message)
        |> handle_command(message, state)
      end
    end
  end

  @spec __before_compile__(any) :: Macro.t()
  defmacro __before_compile__(_) do
    quote(generated: true) do
      def handle_command(_, _, state), do: state
    end
  end
end

defmodule EchoBot do
  use ChatBot.Bot, name: "Echo"

  @impl true
  def init(init_arg) do
    {:ok, init_arg}
  end

  @impl true
  def handle_message(message, state) do
    post(message.message)
    state
  end
end

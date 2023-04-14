defmodule PingBot do
  use ChatBot.Command, name: "PingPongBot"

  @impl true
  def init(init_arg) do
    {:ok, init_arg}
  end

  @impl true
  def handle_command(["!ping"], _message, state) do
    post("Pong")
    state
  end
end
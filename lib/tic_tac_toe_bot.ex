defmodule TicTacToeBot do
  use ChatBot.Bot, name: "TicTacToe", no_bottag: true

  @impl true
  def init(init_arg) do
    {:ok, init_arg}
  end

  @impl true
  def handle_message(%ChatBot.Message{name: name, message: "!ttt start"}, state) do
    post("!ttt turn 0 0") # O
    post("!ttt turn 0 1") # X
    post("!ttt turn 0 2") # O
    post("!ttt turn 1 0") # X
    post("!ttt turn 2 0") # O
    post("!ttt turn 1 2") # X
    post("!ttt turn 2 2") # O
    post("!ttt turn 2 1") # X
    post("!ttt turn 1 1") # O
    state
  end
end
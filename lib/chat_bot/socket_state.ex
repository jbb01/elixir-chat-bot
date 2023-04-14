defmodule ChatBot.SocketState do
  defstruct [:channel, delay: 0, reconnect: 0]

  @type t() :: %__MODULE__{
    channel: String.t(),
    delay: integer,
    reconnect: integer
  }

  @spec increment_reconnect(state :: t()) :: t()
  def increment_reconnect(state) do
    %{state | reconnect: state.reconnect + 1}
  end

  @spec reset_reconnect(state :: t()) :: t()
  def reset_reconnect(state) do
    %{state | reconnect: 0}
  end

  @spec update_delay(state :: t(), new_delay :: integer) :: t()
  def update_delay(state, new_delay) do
    %{state | delay: max(state.delay, new_delay)}
  end
end
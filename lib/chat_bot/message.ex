defmodule ChatBot.Message do
  @enforce_keys [:id, :name, :message, :channel, :date, :delay, :user_id, :user_name, :color, :bottag]
  defstruct [:id, :name, :message, :channel, :date, :delay, :user_id, :user_name, :color, :bottag]

  @type t() :: %__MODULE__{
    id: integer,
    name: String.t(),
    message: String.t(),
    channel: String.t(),
    date: String.t(),
    delay: integer,
    user_id: integer,
    user_name: String.t(),
    color: String.t(),
    bottag: integer
  }
end

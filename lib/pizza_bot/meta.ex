defmodule PizzaBot.Meta do
  @enforce_keys [:running, :user_id, :deadline]
  defstruct [:running, :user_id, :deadline]

  @type t() :: %__MODULE__{
    running: bool,
    user_id: integer,
    deadline: String.t()
  }

  def parse(%{"running" => running, "user_id" => user_id, "deadline" => deadline}) do
    %__MODULE__{
      running: running,
      user_id: user_id,
      deadline: deadline
    }
  end
end
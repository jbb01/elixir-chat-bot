defmodule PizzaBot.Order do
  @enforce_keys [:user_id, :user_name, :pizza_id, :notes]
  defstruct [:id, :user_id, :user_name, :pizza_id, :notes]

  @type t() :: %__MODULE__{
    id: integer,
    user_id: integer,
    user_name: String.t(),
    pizza_id: integer,
    notes: String.t()
  }

  def parse(%{"id" => id, "user_id" => user_id, "user_name" => user_name, "pizza_id" => pizza_id, "notes" => notes}) do
    %__MODULE__{
      id: id,
      user_id: user_id,
      user_name: user_name,
      pizza_id: pizza_id,
      notes: notes
    }
  end
end
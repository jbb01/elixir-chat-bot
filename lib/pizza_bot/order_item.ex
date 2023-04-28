defmodule PizzaBot.OrderItem do
  @enforce_keys [:user_id, :user_name, :pizza_id, :notes]
  defstruct [:id, :user_id, :user_name, :pizza_id, :notes]

  @type t() :: %__MODULE__{
    id: integer,
    user_id: integer,
    user_name: String.t(),
    pizza_id: integer,
    notes: String.t()
  }

  @spec parse(map) :: PizzaBot.OrderItem.t()
  def parse(%{"id" => id, "user_id" => user_id, "user_name" => user_name, "pizza_id" => pizza_id, "notes" => notes})
    when is_integer(id) and is_integer(user_id) and is_binary(user_name) and is_integer(pizza_id) and is_binary(notes) do
    %__MODULE__{
      id: id,
      user_id: user_id,
      user_name: user_name,
      pizza_id: pizza_id,
      notes: notes
    }
  end
end
defmodule PizzaBot.OrderItem do
  @enforce_keys [:user_id, :user_name, :pizza_id, :notes, :payed?]
  defstruct [:id, :group, :user_id, :user_name, :pizza_id, :notes, :payed?]

  @type t() :: %__MODULE__{
    id: integer,
    group: String.t(),
    user_id: integer,
    user_name: String.t(),
    pizza_id: integer,
    notes: String.t(),
    payed?: boolean
  }

  @spec get_user(PizzaBot.OrderItem.t()) :: {user_id :: integer, user_name :: String.t()}
  def get_user(%__MODULE__{user_id: user_id, user_name: user_name}) do
    {user_id, user_name}
  end

  @spec parse(map) :: PizzaBot.OrderItem.t()
  def parse(%{"id" => id, "group" => group, "user_id" => user_id, "user_name" => user_name, "pizza_id" => pizza_id, "notes" => notes, "payed?" => payed})
    when is_integer(id) and is_binary(group) and is_integer(user_id) and is_binary(user_name) and is_integer(pizza_id) and is_binary(notes) and is_boolean(payed) do
    %__MODULE__{
      id: id,
      group: group,
      user_id: user_id,
      user_name: user_name,
      pizza_id: pizza_id,
      notes: notes,
      payed?: payed
    }
  end
end
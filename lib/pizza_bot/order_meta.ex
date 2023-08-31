defmodule PizzaBot.OrderMeta do
  @enforce_keys [:id, :user_id, :group, :deadline, :restaurant]
  defstruct [:id, :user_id, :group, :deadline, :restaurant]

  @type t() :: %__MODULE__{
    id: integer,
    user_id: integer,
    group: String.t(),
    deadline: String.t(),
    restaurant: String.t(),
  }

  @spec parse(map) :: PizzaBot.OrderMeta.t()
  def parse(%{"id" => id, "user_id" => user_id, "group" => group, "deadline" => deadline, "restaurant" => restaurant})
    when is_integer(id) and is_integer(user_id) and is_binary(group) and is_binary(deadline) and is_binary(restaurant) do
    %__MODULE__{
      id: id,
      user_id: user_id,
      group: group,
      deadline: deadline,
      restaurant: restaurant
    }
  end
end
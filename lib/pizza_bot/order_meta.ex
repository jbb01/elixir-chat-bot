defmodule PizzaBot.OrderMeta do
  @enforce_keys [:id, :user_id, :current_group, :groups, :restaurant]
  defstruct [:id, :user_id, :current_group, :groups, :restaurant]

  @type t() :: %__MODULE__{
    id: integer,
    user_id: integer,
    current_group: String.t() | nil,
    groups: %{group :: String.t() => PizzaBot.OrderMeta.Group.t()},
    restaurant: String.t(),
  }

  @spec parse(map) :: PizzaBot.OrderMeta.t()
  def parse(%{"id" => id, "user_id" => user_id, "groups" => groups, "restaurant" => restaurant} = data)
    when is_integer(id) and is_integer(user_id) and is_binary(restaurant) do

    parsed_groups = groups
                    |> Enum.map(fn {name, group} -> {name, PizzaBot.OrderMeta.Group.parse(name, group)} end)
                    |> Map.new

    current_group = cond do
      Map.has_key?(parsed_groups, name = Map.get(data, "current_group", nil)) -> name
      true -> nil
    end

    %__MODULE__{
      id: id,
      user_id: user_id,
      current_group: current_group,
      groups: parsed_groups,
      restaurant: restaurant
    }
  end

  @spec get_current_group(order :: PizzaBot.OrderMeta.t()) :: PizzaBot.OrderMeta.Group.t() | nil
  def get_current_group(%__MODULE__{current_group: current_group, groups: groups}) do
    case current_group do
      name when is_binary(name) -> Map.get(groups, name, nil)
      nil -> nil
    end
  end

  @spec get_group(order :: PizzaBot.OrderMeta.t(), group :: String.t()) :: PizzaBot.OrderMeta.Group.t() | nil
  def get_group(%__MODULE__{groups: groups}, group) do
    Map.get(groups, group, nil)
  end
end

defmodule PizzaBot.OrderMeta.Group do
  @enforce_keys [:name, :deadline]
  defstruct [:name, :deadline, :total_with_tip]

  @type t() :: %__MODULE__{
    name: String.t(),
    deadline: String.t(),
    total_with_tip: float | nil
  }

  @spec parse(String.t(), map) :: PizzaBot.OrderMeta.Group.t()
  def parse(name, %{"deadline" => deadline} = data) do
    %__MODULE__{
      name: name,
      deadline: deadline,
      total_with_tip: Map.get(data, "total_with_tip", nil)
    }
  end
end
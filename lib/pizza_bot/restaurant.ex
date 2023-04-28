defmodule PizzaBot.Restaurant do
  @enforce_keys [:name, :pizzas]
  defstruct [:name, :city, :phone, :pizzas]

  @type t() :: %__MODULE__{
    name: String.t(),
    city: String.t(),
    phone: String.t(),
    pizzas: [PizzaBot.Pizza.t()]
  }

  @spec parse(map) :: PizzaBot.Restaurant.t()
  def parse(%{"name" => name, "city" => city, "phone" => phone, "pizzas" => pizzas})
    when is_binary(name) and is_binary(city) and is_binary(phone) and is_list(pizzas) do
    %__MODULE__{
      name: name,
      city: city,
      phone: phone,
      pizzas: pizzas |> Enum.map(&PizzaBot.Pizza.parse/1)
    }
  end

  @spec get_pizza(restaurant :: PizzaBot.Restaurant.t(), pizza_id :: integer) :: PizzaBot.Pizza.t() | nil
  def get_pizza(%PizzaBot.Restaurant{} = restaurant, pizza_id) when is_integer(pizza_id) do
    restaurant.pizzas
    |> Enum.filter(fn pizza -> pizza.id == pizza_id end)
    |> List.first
  end
end
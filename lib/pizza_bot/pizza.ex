defmodule PizzaBot.Pizza do
  @enforce_keys [:id, :number, :name, :ingredients, :price]
  defstruct [:id, :number, :name, :ingredients, :price]

  @type t() :: %__MODULE__{
    id: integer,
    number: String.t(),
    name: String.t(),
    ingredients: String.t(),
    price: float
  }

  @spec parse(map) :: PizzaBot.Pizza.t()
  def parse(%{"id" => id, "name" => name, "number" => number, "ingredients" => ingredients, "price" => price})
    when is_integer(id) and is_binary(name) and is_binary(number) and is_binary(ingredients) and is_float(price) do
    %__MODULE__{
      id: id,
      name: name,
      ingredients: ingredients,
      number: number,
      price: price
    }
  end
end
defmodule PizzaBot.Pizza do
  defstruct [:id, :number, :name, :ingredients, :price]

  @type t() :: %__MODULE__{
    id: integer,
    number: String.t(),
    name: String.t(),
    ingredients: String.t(),
    price: float
  }

  def parse(%{"id" => id, "name" => name, "number" => number, "ingredients" => ingredients, "price" => price}) do
    %__MODULE__{
      id: id,
      name: name,
      ingredients: ingredients,
      number: number,
      price: price
    }
  end
end
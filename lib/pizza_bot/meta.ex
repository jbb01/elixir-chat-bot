defmodule PizzaBot.Meta do
  @enforce_keys [:current_order]
  defstruct [:current_order]

  @type t() :: %__MODULE__{
    current_order: integer
  }

  @spec parse(map) :: PizzaBot.Meta.t()
  def parse(%{"current_order" => current_order}) do
    %__MODULE__{
      current_order: current_order
    }
  end
end
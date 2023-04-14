defmodule PizzaBot.State do
  @meta_file "data/meta.json"
  @pizza_file "data/pizzas.json"
  @order_file "data/orders.json"

  @spec get_meta() :: PizzaBot.Meta.t()
  def get_meta() do
    File.read!(@meta_file)
    |> JSON.decode!()
    |> PizzaBot.Meta.parse()
  end


  @spec get_pizzas() :: [PizzaBot.Pizza.t()]
  def get_pizzas() do
    File.read!(@pizza_file)
    |> JSON.decode!()
    |> Enum.map(&PizzaBot.Pizza.parse/1)
  end

  @spec get_pizza(integer) :: PizzaBot.Pizza.t() | nil
  def get_pizza(id) do
    get_pizzas()
    |> Enum.filter(fn pizza -> pizza.id == id end)
    |> List.first
  end



  @spec get_orders() :: [PizzaBot.Order.t()]
  def get_orders() do
    File.read!(@order_file)
    |> JSON.decode!()
    |> Enum.map(&PizzaBot.Order.parse/1)
  end

  @spec get_orders_by_user(integer) :: [PizzaBot.Order.t()]
  def get_orders_by_user(user_id) do
    get_orders()
    |> Enum.filter(fn order -> order.user_id == user_id end)
  end

  @spec get_order(integer) :: PizzaBot.Order.t() | nil
  def get_order(id) do
    get_orders()
    |> Enum.filter(fn order -> order.id == id end)
    |> List.first
  end

  @spec add_order(PizzaBot.Order.t()) :: PizzaBot.Order.t()
  def add_order(order) do
    orders = get_orders()
    highest_id = orders
                 |> Enum.map(&(&1.id))
                 |> Enum.max(fn -> 0 end)

    order_with_id = Map.put(order, :id, highest_id + 1)
    File.write!(@order_file, JSON.encode!([order_with_id | orders]))
    order_with_id
  end

  @spec delete_order(integer) :: any
  def delete_order(order_id) do
    json = get_orders()
    |> Enum.filter(fn order -> order.id != order_id end)
    |> JSON.encode!()

    File.write!(@order_file, json)
  end

  @spec delete_order_by_user(integer) :: any
  def delete_order_by_user(user_id) do
    json = get_orders()
    |> Enum.filter(fn order -> order.user_id != user_id end)
    |> JSON.encode!()

    File.write!(@order_file, json)
  end
end
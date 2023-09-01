defmodule PizzaBot.State do
  @meta_file "data/meta.json"
  @pizza_file "data/pizza"
  @order_file "data/order"

  @spec get_current_order_id() :: integer
  def get_current_order_id() do
    meta = File.read!(@meta_file)
    |> JSON.decode!()
    |> PizzaBot.Meta.parse()

    meta.current_order
  end

  @spec get_current_order() :: PizzaBot.OrderMeta.t()
  def get_current_order() do
    get_current_order_id()
    |> get_order_meta()
  end

  @spec get_current_restaurant() :: PizzaBot.Restaurant.t()
  def get_current_restaurant() do
    get_current_order().restaurant
    |> get_restaurant()
  end


  @spec get_restaurant(restaurant :: String.t()) :: PizzaBot.Restaurant.t()
  def get_restaurant(restaurant) when is_binary(restaurant) do
    restaurant
    |> get_restaurant_file()
    |> File.read!()
    |> JSON.decode!()
    |> PizzaBot.Restaurant.parse()
  end

  @spec get_order_meta(order_id :: integer) :: PizzaBot.OrderMeta.t()
  def get_order_meta(order_id) when is_integer(order_id) do
    order_id
    |> get_order_meta_file()
    |> File.read!()
    |> JSON.decode!()
    |> PizzaBot.OrderMeta.parse()
  end

  @spec get_order_items(order_id :: integer) :: [PizzaBot.OrderItem.t()]
  def get_order_items(order_id) when is_integer(order_id) do
    order_id
    |> get_order_items_file()
    |> File.read!()
    |> JSON.decode!()
    |> Enum.map(&PizzaBot.OrderItem.parse/1)
  end

  @spec get_order_items_by_user(order_id :: integer, user_id :: integer) :: PizzaBot.OrderItem.t() | nil
  def get_order_item(order_id, item_id) when is_integer(order_id) and is_integer(item_id) do
    order_id
    |> get_order_items()
    |> Enum.filter(fn item -> item.id == item_id end)
    |> List.first()
  end

  @spec get_order_items_by_user(order_id :: integer, user_id :: integer) :: [PizzaBot.OrderItem.t()]
  def get_order_items_by_user(order_id, user_id) when is_integer(order_id) and is_integer(user_id) do
    order_id
    |> get_order_items()
    |> Enum.filter(fn item -> item.user_id == user_id end)
  end

  @spec save_order_item(order_id :: integer, item :: PizzaBot.OrderItem.t) :: :ok
  def save_order_item(order_id, %PizzaBot.OrderItem{id: item_id} = item) when is_integer(order_id) and is_integer(item_id) do
    items = get_order_items(order_id)
            |> Enum.filter(fn order -> order.id != item_id end)

    [item | items]
    |> save_order_items(order_id)
  end

  @spec add_order_item(order_id :: integer, item :: PizzaBot.OrderItem.t()) :: PizzaBot.OrderItem.t()
  def add_order_item(order_id, %PizzaBot.OrderItem{} = item) when is_integer(order_id) do
    order = get_order_meta(order_id)
    items = get_order_items(order_id)

    highest_id = items
                 |> Enum.map(&(&1.id))
                 |> Enum.max(fn -> 0 end)

    item_with_id = item
                   |> Map.put(:id, highest_id + 1)
                   |> Map.put(:group, order.current_group)

    result = [item_with_id | items]
    |> save_order_items(order_id)

    item_with_id
  end

  @spec delete_order_item(order_id :: integer, item :: PizzaBot.OrderItem.t()) :: :ok
  def delete_order_item(order_id, item_id) when is_integer(order_id) do
    get_order_items(order_id)
    |> Enum.filter(fn order -> order.id != item_id end)
    |> save_order_items(order_id)
  end

  @spec delete_order_by_user(order_id :: integer, user_id :: integer) :: :ok
  def delete_order_by_user(order_id, user_id) when is_integer(order_id) and is_integer(user_id) do
    get_order_items(order_id)
    |> Enum.filter(fn order -> order.user_id != user_id end)
    |> save_order_items(order_id)
  end

  @spec save_order_items(items :: [PizzaBot.OrderItem.t()], order_id :: integer) :: :ok
  defp save_order_items(items, order_id) when is_list(items) do
    File.write!(get_order_items_file(order_id), JSON.encode!(items))
  end



  @spec get_restaurant_file(restaurant :: binary) :: binary
  defp get_restaurant_file(restaurant) do
    @pizza_file <> "/" <> restaurant <> ".json"
  end

  @spec get_order_meta_file(order_id :: integer) :: binary
  defp get_order_meta_file(order_id) do
    @order_file <> "/" <> to_string(order_id) <> "_meta.json"
  end

  @spec get_order_items_file(order_id :: integer) :: binary
  defp get_order_items_file(order_id) do
    @order_file <> "/" <> to_string(order_id) <> "_items.json"
  end
end
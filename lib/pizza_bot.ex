alias ChatBot.Message

defmodule PizzaBot do
  use ChatBot.Command, name: "Marek"

  @command "!marek"

  @impl true
  def init(init_arg) do
    {:ok, init_arg}
  end

  @impl true
  def handle_command([@command, "info"], _message, state) do
    pizzas = PizzaBot.State.get_pizzas()
    |> Enum.map(fn pizza ->
      id = tabular_numbers(pizza.id)
      number = tabular_numbers(pizza.number)
      price = tabular_numbers(:erlang.float_to_binary(pizza.price, [decimals: 2]), 5)
      
      "#{id} | #{number} | #{price} € | #{String.upcase(pizza.name)} #{pizza.ingredients}"
    end)

    meta = PizzaBot.State.get_meta()

    ["Bestellannahmeschluss: " <> meta.deadline | pizzas]
    |> Enum.join("\n")
    |> post

    state
  end

#  @impl true
#  def handle_command([@command, "start", deadline], %Message{user_id: user_id}, state) when is_integer(user_id) do
#    post("""
#    Ich nehme bis #{deadline} Pizzabestellungen entgegen.
#    Bestellungen können mit \"!marek order\" aufgegeben werden.
#    """)
#  end

  @impl true
  def handle_command([@command, "summary"], %Message{user_id: user_id}, state) when is_integer(user_id) do
    meta = PizzaBot.State.get_meta()
    if user_id == meta.user_id do
      orders = PizzaBot.State.get_orders()
      |> Enum.group_by(
           fn order -> {order.pizza_id, order.notes} end,
           fn order -> order.user_name end
         )
      |> Enum.map(fn {{pizza_id, notes}, users} ->
        pizza = PizzaBot.State.get_pizza(pizza_id)
        tabular_numbers(length(users)) <> "x " <> pizza.name <> " " <> notes <> " (" <> Enum.join(users, ", ") <> ")"
      end)

      ["Übersicht" | orders]
      |> Enum.join("\n")
      |> post
    end

    state
  end

  @impl true
  def handle_command([@command, "check"], %Message{user_id: user_id}, state) when is_integer(user_id) do
    meta = PizzaBot.State.get_meta()

    if user_id == meta.user_id do
      payments = PizzaBot.State.get_orders()
      |> Enum.group_by(
          fn order -> {order.user_id, order.user_name} end,
          fn order ->
            pizza = PizzaBot.State.get_pizza(order.pizza_id)
            pizza.price
          end
        )
      |> Enum.map(fn {user, prices} -> {user, Enum.sum(prices)} end)

      total = payments
      |> Enum.map(fn {_, price} -> price end)
      |> Enum.sum()

      table = payments
      |> Enum.map(fn {{_, user_name}, price} ->
        user_name <> ": " <> tabular_numbers(price) <> " €"
      end)

      ["Rechnung (ohne Trinkgeld)", "alle Angaben ohne Gewähr", "" | table]
      ++ ["", "Gesamt: " <> tabular_numbers(total) <> " €"]
      |> Enum.join("\n")
      |> post
    end

    state
  end


  @impl true
  def handle_command([@command, "order", "list"], %Message{user_id: user_id, user_name: user_name}, state) when is_integer(user_id) do
    orders = PizzaBot.State.get_orders_by_user(user_id)
    |> Enum.map(fn order ->
      pizza = PizzaBot.State.get_pizza(order.pizza_id)
      "#{order.id} | #{pizza.name} | #{order.notes}"
    end)

    (["Bestellungen von " <> user_name, "" | orders])
    |> Enum.join("\n")
    |> post

    state
  end

  @impl true
  def handle_command([@command, "order", "revoke", order_id], %Message{user_id: user_id}, state) when is_integer(user_id) do
    order_id = String.to_integer(order_id)
    order = PizzaBot.State.get_order(order_id)
    cond do
      is_nil(order) ->
        post("Die Bestellung mit ID #{order_id} existiert nicht.")
      order.user_id != user_id ->
        post("Die Bestellung mit ID #{order_id} ist nicht deine.")
      true ->
        pizza = PizzaBot.State.get_pizza(order.pizza_id)
        PizzaBot.State.delete_order(order_id)
        post("Die Bestellung mit ID #{order_id} (#{pizza.name}) wurde zurückgenommen.")
    end
    state
  end

  @impl true
  def handle_command([@command, "order", pizza_id | notes], %Message{user_id: user_id, user_name: user_name}, state)
      when is_integer(user_id) do

    pizza_id = String.to_integer(pizza_id)
    pizza = PizzaBot.State.get_pizza(pizza_id)

    if is_nil(pizza) do
      post("Es gibt keine Pizza mit der ID " <> to_string(pizza_id))
    else
      note = Enum.join(notes, " ")
      |> String.replace(["\n", "\r"], " ")

      order = %PizzaBot.Order{user_id: user_id, user_name: user_name, pizza_id: pizza_id, notes: note}
      |> PizzaBot.State.add_order

      post("Pizza \"#{pizza.name}\" wurde zur Bestellung hinzugefügt (Order-ID #{order.id}).")
    end

    state
  end

  @impl true
  def handle_command([@command, "order" | _], %Message{user_id: user_id}, state) when is_integer(user_id) do
    help_order() |> post
    state
  end

  @impl true
  def handle_command([@command, "order" | _], %Message{user_id: user_id}, state) when is_nil(user_id) do
    post("Bestellungen können nur mit öffentlicher ID abgegeben oder bearbeitet werden.")
    state
  end



  @impl true
  def handle_command([@command | _], _message, state) do
    help() |> post()
    state
  end

  @impl true
  def handle_command(["!MAREK" | _], _message, state) do
    ["Jetzt schrei doch nicht so!", "Fresse!", "Es ist so dunkel, ich kann dich nicht hören!"]
    |> Enum.random()
    |> post()

    state
  end

  defp help() do
    """
    Marek is back!
    #{@command} info - Menü anzeigen

    """
    <> help_order()
  end

  defp help_order() do
    """
    Bestellungen:

    #{@command} order <pizza_id> [notizen] - Pizza bestellen
    #{@command} order revoke <order_id>    - Pizzabestellung zurücknehmen
    #{@command} order list                             - Bestellungen auflisten
    """
  end

  defp tabular_numbers(i, width \\ 2)
  defp tabular_numbers(str, width) when is_binary(str) do
    str
    |> String.replace("0", "𝟶")
    |> String.replace("1", "𝟷")
    |> String.replace("2", "𝟸")
    |> String.replace("3", "𝟹")
    |> String.replace("4", "𝟺")
    |> String.replace("5", "𝟻")
    |> String.replace("6", "𝟼")
    |> String.replace("7", "𝟽")
    |> String.replace("8", "𝟾")
    |> String.replace("9", "𝟿")
    |> String.replace(" ", "\u2002")
    |> String.pad_leading(width, "\u2002")
  end

  defp tabular_numbers(num, width) do
    tabular_numbers(to_string(num), width)
  end
end

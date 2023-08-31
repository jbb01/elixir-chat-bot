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
    order = PizzaBot.State.get_current_order()
    restaurant = PizzaBot.State.get_restaurant(order.restaurant)

    pizzas = restaurant.pizzas
    |> Enum.map(fn pizza ->
      id = tabular_numbers(pizza.id)
      number = tabular_numbers(pizza.number)
      price = tabular_numbers(pizza.price)
      
      "#{id} | #{number} | #{price} € | #{String.upcase(pizza.name)} #{pizza.ingredients}"
    end)

    name = "Pizzabestellung bei " <> restaurant.name <> " in " <> restaurant.city
    deadline = "Bestellannahmeschluss: " <> order.deadline

    [name, deadline | pizzas]
    |> Enum.join("\n")
    |> do_post()

    state
  end

  #
  # Admin Commands
  #

  @impl true
  def handle_command([@command, "summary"], %Message{user_id: user_id}, state) when is_integer(user_id) do
    order = PizzaBot.State.get_current_order()

    if user_id == order.user_id do
      print_summary(order.id, false)
    end

    state
  end

  @impl true
  def handle_command([@command, "summary", "--all"], %Message{user_id: user_id}, state) when is_integer(user_id) do
    order = PizzaBot.State.get_current_order()

    if user_id == order.user_id do
      print_summary(order.id, true)
    end

    state
  end

  @spec print_summary(order_id :: integer, all :: boolean) :: any
  defp print_summary(order_id, all) do
    order = PizzaBot.State.get_order_meta(order_id)
    restaurant = PizzaBot.State.get_restaurant(order.restaurant)

    items = PizzaBot.State.get_order_items(order.id)
            |> Enum.filter(fn item -> all || item.group == order.group end)
            |> Enum.group_by(
                 fn order -> {order.pizza_id, order.notes} end,
                 fn order -> order.user_name end
               )
            |> Enum.map(fn {{pizza_id, notes}, users} ->
      pizza = PizzaBot.Restaurant.get_pizza(restaurant, pizza_id)
      tabular_numbers(length(users)) <> "x " <> pizza.name <> " " <> notes <> " (" <> Enum.join(users, ", ") <> ")"
    end)

    ["Übersicht" | items]
    |> Enum.join("\n")
    |> do_post()
  end


  @impl true
  def handle_command([@command, "check"], %Message{user_id: user_id} = message, state) when is_integer(user_id) do
    order = PizzaBot.State.get_current_order()

    if user_id == order.user_id do
      print_check(order.id, false, nil)
    end

    state
  end

  @impl true
  def handle_command([@command, "check", "--all"], %Message{user_id: user_id} = message, state) when is_integer(user_id) do
    order = PizzaBot.State.get_current_order()

    if user_id == order.user_id do
      print_check(order.id, true, nil)
    end

    state
  end

  @impl true
  def handle_command([@command, "check", total_with_tip], %Message{user_id: user_id}, state) when is_integer(user_id) do
    order = PizzaBot.State.get_current_order()

    if user_id == order.user_id do
      print_check(order.id, false, total_with_tip)
    end

    state
  end

  @spec get_payments(order :: PizzaBot.OrderMeta.t(), all :: boolean)
        :: [{{user_id :: integer, user_name :: String.t(), group :: String.t()}, total :: number, payed :: number}]
  defp get_payments(order, all) do
    restaurant = PizzaBot.State.get_restaurant(order.restaurant)

    PizzaBot.State.get_order_items(order.id)
    |> Enum.filter(fn item -> all || item.group == order.group end)
    |> Enum.group_by(
         fn order -> {order.user_id, order.user_name} end,
         fn order ->
           pizza = PizzaBot.Restaurant.get_pizza(restaurant , order.pizza_id)
           {pizza.price, order.payed?}
         end
       )
    |> Enum.map(fn {user, prices} ->
      {
        user,
        prices |> Enum.map(fn {price, _payed?} -> price end) |> Enum.sum(),
        prices |> Enum.filter(fn {_price, payed?} -> payed? end) |> Enum.map(fn {price, _payed?} -> price end) |> Enum.sum()
      }
    end)
  end

  @spec print_check(order_id :: integer, all :: boolean, total_with_tip :: any) :: any
  defp print_check(order_id, all, total_with_tip) do
    order = PizzaBot.State.get_order_meta(order_id)

    # [{{user_id, user_name}, total, payed}, ...]
    payments = get_payments(order, all)

    total = payments
            |> Enum.map(fn {_user, total, _payment} -> total end)
            |> Enum.sum()

    {total_with_tip, tip_factor} = if is_nil(total_with_tip) do
      {nil, nil}
    else
      {float, _} = Float.parse(total_with_tip)
      {float, float / total}
    end

    currency = fn amount ->
      "#{tabular_numbers(amount)} €"
    end

    table = payments
            |> Enum.map(fn
      {{_user_id, user_name}, user_total, payment} when (payment == 0) ->
        if is_nil(tip_factor),
           do: "#{user_name}: #{currency.(user_total)}",
           else: "#{user_name}: #{currency.(user_total)} (#{currency.(user_total * tip_factor)})"
      {{_user_id, user_name}, user_total, payment} when (payment >= user_total) ->
        if is_nil(tip_factor),
           do: strikethrough("#{user_name}: #{currency.(user_total)}"),
           else: strikethrough("#{user_name}: #{currency.(user_total)} (#{currency.(user_total * tip_factor)})")
      {{_user_id, user_name}, user_total, payment} ->
        if is_nil(tip_factor),
           do: "#{user_name}: #{strikethrough(currency.(user_total))} #{currency.(user_total - payment)}",
           else: "#{user_name}: "
           <> "#{strikethrough("#{currency.(user_total)} (#{currency.(user_total * tip_factor)})")} "
                 <> "#{currency.(user_total - payment)} (#{currency.((user_total - payment) * tip_factor)})"
    end)

    ["Rechnung (#{if is_nil(tip_factor), do: "ohne", else: "mit"} Trinkgeld)", "alle Angaben ohne Gewähr", "" | table]
    ++ ["", "Gesamt: #{currency.(total)}#{if is_nil(tip_factor), do: "", else: " (#{currency.(total_with_tip)})"}"]
    |> Enum.join("\n")
    |> do_post()
  end

  @impl true
  def handle_command([@command, "order", "confirm", item_id], %Message{user_id: user_id}, state) when is_integer(user_id) do
    confirm_payment(item_id, user_id, true, fn pizza, item ->
      do_post("Zahlungseingang für \"#{pizza.name}\" (#{item.user_name}) wurde bestätigt.")
    end)

    state
  end

  @impl true
  def handle_command([@command, "order", "unconfirm", item_id], %Message{user_id: user_id}, state) when is_integer(user_id) do
    confirm_payment(item_id, user_id, false, fn pizza, item ->
      do_post("Bestätigung des Zahlungseingang für \"#{pizza.name}\" (#{item.user_name}) wurde zurückgenommen.")
    end)

    state
  end

  @impl true
  def handle_command([@command, "order", "list", "--all"], %Message{user_id: user_id}, state) when is_integer(user_id) do
    order = PizzaBot.State.get_current_order()

    if user_id == order.user_id do
      restaurant = PizzaBot.State.get_restaurant(order.restaurant)
      PizzaBot.State.get_order_items(order.id)
      |> Enum.map(fn item ->
        pizza = PizzaBot.Restaurant.get_pizza(restaurant, item.pizza_id)
        "#{item.id} | #{item.user_name} | #{item.group} | #{pizza.name} | #{item.notes}"
      end)
      |> Enum.join("\n")
      |> do_post()
    end

    state
  end

  @spec confirm_payment(
          item_id :: binary, user_id :: integer, payed? :: boolean,
          success :: ((pizza :: PizzaBot.Pizza.t(), item :: PizzaBot.OrderItem.t()) -> term)
        ) :: any
  defp confirm_payment(item_id, user_id, payed?, success) do
    item_id = String.to_integer(item_id)

    order = PizzaBot.State.get_current_order()
    if user_id == order.user_id do
      case PizzaBot.State.get_order_item(order.id, item_id) do
        nil ->
          do_post("Die Bestellung mit ID #{item_id} existiert nicht.")
        item ->
          pizza = PizzaBot.State.get_restaurant(order.restaurant)
                  |> PizzaBot.Restaurant.get_pizza(item.pizza_id)

          PizzaBot.State.save_order_item(order.id, %{item | payed?: payed?})
          success.(pizza, item)
      end
    end
  end

  #
  # Order Commands
  #

  @impl true
  def handle_command([@command, "order", "list"], %Message{user_id: user_id, user_name: user_name}, state) when is_integer(user_id) do
    order = PizzaBot.State.get_current_order()
    restaurant = PizzaBot.State.get_restaurant(order.restaurant)

    groups = PizzaBot.State.get_order_items_by_user(order.id, user_id)
    |> Enum.group_by(fn item -> item.group end)
    |> Enum.map(fn {group, items} ->
      items_as_string = items |> Enum.map(fn item ->
        pizza = PizzaBot.Restaurant.get_pizza(restaurant, item.pizza_id)
        price = if item.payed?, do: strikethrough(tabular_numbers(pizza.price)), else: tabular_numbers(pizza.price)
        "#{item.id} | #{pizza.name} | #{price} | #{item.notes}"
      end)

      Enum.join([group | items_as_string], "\n")
    end)

    (["Bestellungen von #{user_name}" | groups])
    |> Enum.join("\n\n")
    |> do_post()

    state
  end

  @impl true
  def handle_command([@command, "order", "revoke", item_id], %Message{user_id: user_id}, state) when is_integer(user_id) do
    item_id = String.to_integer(item_id)

    order = PizzaBot.State.get_current_order()
    item = PizzaBot.State.get_order_item(order.id, item_id)

    cond do
      is_nil(item) ->
        do_post("Die Bestellung mit ID #{item_id} existiert nicht.")
      item.user_id != user_id ->
        do_post("Die Bestellung mit ID #{item_id} ist nicht deine.")
      item.group != order.group ->
        do_post("Die Bestellung mit ID #{item_id} kann nicht mehr storniert werden.")
      true ->
        pizza = PizzaBot.State.get_restaurant(order.restaurant)
                |> PizzaBot.Restaurant.get_pizza(item.pizza_id)
        PizzaBot.State.delete_order_item(order.id, item.id)
        do_post("Die Bestellung mit ID #{item_id} (#{pizza.name}) wurde zurückgenommen.")
    end
    state
  end

  @impl true
  def handle_command([@command, "order", pizza_id | notes], %Message{user_id: user_id, user_name: user_name}, state)
      when is_integer(user_id) do
    pizza_id = String.to_integer(pizza_id)

    order = PizzaBot.State.get_current_order()
    pizza = PizzaBot.State.get_restaurant(order.restaurant)
            |> PizzaBot.Restaurant.get_pizza(pizza_id)

    if is_nil(pizza) do
      do_post("Es gibt keine Pizza mit der ID " <> to_string(pizza_id))
    else
      note = Enum.join(notes, " ")
      |> String.replace(["\n", "\r"], " ")

      item = %PizzaBot.OrderItem{user_id: user_id, user_name: user_name, pizza_id: pizza_id, notes: note, payed?: false}
      item_with_id = PizzaBot.State.add_order_item(order.id, item)

      do_post("Pizza \"#{pizza.name}\" wurde zur Bestellung hinzugefügt (Order-ID #{item_with_id.id}).")
    end

    state
  end

  @impl true
  def handle_command([@command, "order" | _], %Message{user_id: user_id}, state) when is_integer(user_id) do
    help_order() |> do_post()
    state
  end

  @impl true
  def handle_command([@command, "order" | _], %Message{user_id: user_id}, state) when is_nil(user_id) do
    do_post("Bestellungen können nur mit öffentlicher ID abgegeben oder bearbeitet werden.")
    state
  end

  #
  # Other Commands
  #

  @impl true
  def handle_command([@command, "help", "--all"], _message, state) do
    help(true) |> do_post()
    state
  end

  @impl true
  def handle_command([@command | _], _message, state) do
    help() |> do_post()
    state
  end

  @impl true
  def handle_command(["!MAREK" | _], _message, state) do
    ["Jetzt schrei doch nicht so!", "Fresse!", "Es ist so dunkel, ich kann dich nicht hören!"]
    |> Enum.random()
    |> do_post()

    state
  end

  @impl true
  def handle_command(["!Marek" | args], message, state) do
    handle_command([@command | args], message, state)
  end

  @impl true
  def handle_command([command | args], message, state) do
    lowercase? = fn <<chr>> -> ?a <= chr and chr <= ?z end
    uppercase? = fn <<chr>> -> ?A <= chr and chr <= ?Z end

    if String.downcase(command) == @command do
      up_count = String.codepoints(command) |> Enum.count(uppercase?)
      low_count = String.codepoints(command) |> Enum.count(lowercase?)
      fraction = up_count / (up_count + low_count)

      ChatBot.BotState.set_property(self(), :upcase_percentage, fraction)
      handle_command([@command | args], message, state)
      ChatBot.BotState.set_property(self(), :upcase_percentage, nil)
    else
      state
    end
  end

  defp help(admin \\ false) do
    if admin do
      Enum.join([help_general(), help_order(), help_admin()], "\n")
    else
      Enum.join([help_general(), help_order()], "\n")
    end
  end

  defp help_general() do
    """
    Marek is back!
    #{@command} info - Menü anzeigen
    """
  end

  defp help_order() do
    """
    Bestellungen:

    #{@command} order <pizza_id> [notizen] - Pizza bestellen
    #{@command} order revoke <order_id>    - Pizzabestellung zurücknehmen
    #{@command} order list                             - Bestellungen auflisten
    """
  end

  defp help_admin() do
    """
    Admin

    #{@command} summary [--all] - Zeigt eine Übersicht der Bestellungen an
    #{@command} check [total | --all] - Zeigt die Rechnung an

    #{@command} order confirm <order_id>     - Bestätigt den Zahlungseingang für eine Bestellung
    #{@command} order unconfirm <order_id> - Widerruft die Bestätigung eines Zahlungseingangs
    #{@command} order list [--all]                           - Listet alle Bestellungen auf
    """
  end

  #
  # Utilities
  #

  defp do_post(name \\ @bot_name, message, args \\ []) do
    case ChatBot.BotState.get_property(self(), :upcase_percentage) do
      upcase_percentage when is_float(upcase_percentage) ->
        post(name, random_upcase(message, upcase_percentage), args)
      _ ->
        post(name, message, args)
    end
  end

  defp tabular_numbers(obj) when is_binary(obj) when is_integer(obj) do
    tabular_numbers(obj, 2)
  end
  defp tabular_numbers(obj) when is_float(obj) do
    tabular_numbers(obj, 5)
  end
  defp tabular_numbers(str, width) when is_binary(str) and is_integer(width) do
    String.replace(str, ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", " "], fn
      "0" -> "𝟶"
      "1" -> "𝟷"
      "2" -> "𝟸"
      "3" -> "𝟹"
      "4" -> "𝟺"
      "5" -> "𝟻"
      "6" -> "𝟼"
      "7" -> "𝟽"
      "8" -> "𝟾"
      "9" -> "𝟿"
      " " -> "\u2007"
    end)
    |> String.pad_leading(width, "\u2007")
  end
  defp tabular_numbers(num, width) when is_integer(num) and is_integer(width) do
    tabular_numbers(to_string(num), width)
  end
  defp tabular_numbers(num, width, precision \\ 2) when is_float(num) and is_integer(width) do
    tabular_numbers(:erlang.float_to_binary(num, [decimals: precision]), width)
  end

  defp strikethrough(string) when is_binary(string) do
    case String.next_grapheme(string) do
      {<<digit::utf8>> = grapheme, rest} when ?𝟶 <= digit and digit <= ?𝟿 ->
        grapheme <> "\ufeff\u0336" <> strikethrough(rest)
      {grapheme, rest} ->
        grapheme <> "\u0336" <> strikethrough(rest)
      nil ->
        ""
    end
  end

  defp random_upcase(string, percentage) when is_binary(string) and is_float(percentage) do
    case String.next_grapheme(string) do
      {grapheme, rest} ->
        if :rand.uniform() < percentage do
          String.upcase(grapheme) <> random_upcase(rest, percentage)
        else
          grapheme <> random_upcase(rest, percentage)
        end
      nil ->
        ""
    end
  end
end

defmodule LogFormat do

  @spec format(atom, term, Logger.Formatter.time(), keyword()) :: IO.chardata()
  def format(level, message, {date, time}, metadata) do
    {module, _function, _arity} = Keyword.get(metadata, :mfa)

    channel = Keyword.get(metadata, :channel)
    bot_name = Keyword.get(metadata, :bot_name)

    name = cond do
      is_binary(channel) ->
        [inspect(module), "(channel=", inspect(channel), ")"]
      bot_name == module ->
        inspect(module)
      bot_name != nil ->
        [inspect(module), "(bot_name=", inspect(bot_name), ")"]
      true ->
        inspect(module)
    end

    [
      Logger.Formatter.format_date(date), " ", Logger.Formatter.format_time(time),
      " [", String.pad_trailing(to_string(level), 5), "]",
      " [", name, "]",
      " ", message, "\n"
    ]
  end
end
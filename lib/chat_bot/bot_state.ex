defmodule ChatBot.BotState do
  require Logger
  use Agent

  def start_link(_) do
    Agent.start_link(fn -> %{} end, name: __MODULE__)
  end

  @spec get_property(name :: String.t(), key :: atom) :: term
  def get_property(name, key) when is_atom(key) do
    Agent.get(__MODULE__, fn
      %{^name => %{^key => value}} ->
        value
      _ ->
        nil
    end)
  end

  @spec set_property(name :: String.t(), key :: atom, value :: term) :: :ok
  def set_property(name, key, value) when is_atom(key) do
    Logger.debug(inspect(key) <> " = " <> inspect(value), bot_name: name)
    Agent.update(__MODULE__, fn
      %{^name => %{} = bot_properties} = properties when is_nil(value) ->
        %{properties | name => Map.delete(bot_properties, key)}
      %{^name => %{} = bot_properties} = properties ->
        %{properties | name => Map.put(bot_properties, key, value)}
      %{} = properties when is_nil(value) ->
        properties
      %{} = properties ->
        Map.put(properties, name, %{key => value})
    end)
  end

  @spec set_channel(name :: pid, channel :: String.t()) :: :ok
  def set_channel(name, channel) when is_pid(name) and (is_binary(channel) or is_nil(channel)) do
    set_property(name, :channel, channel)
  end

  @spec get_channel(name :: pid) :: String.t()
  def get_channel(name) when is_pid(name) do
    get_property(name, :channel)
  end

  @spec set_channel_whitelist(name :: term, channels :: [String.t()]) :: :ok
  def set_channel_whitelist(name, channels) when is_list(channels) or is_nil(channels) do
    set_property(name, :channel_whitelist, channels)
  end

  @spec get_channel(name :: term) :: [String.t()]
  def get_channel_whitelist(name) do
    get_property(name, :channel_whitelist)
  end
end
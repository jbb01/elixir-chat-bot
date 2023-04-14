defmodule ChatBot.BotState do
  use Agent

  def start_link(_) do
    Agent.start_link(fn -> {%{}, %{}} end, name: __MODULE__)
  end

  @spec set_channel(name :: term, channel :: String.t()) :: :ok
  def set_channel(name, channel) when is_binary(channel) or is_nil(channel) do
    Agent.update(__MODULE__, fn {current_channel, channel_whitelist} ->
      new_current_channel = if is_nil(channel) do
        Map.delete(current_channel, name)
      else
        Map.put(current_channel, name, channel)
      end

      {new_current_channel, channel_whitelist}
    end)
  end

  @spec get_channel(name :: term) :: String.t()
  def get_channel(name) do
    Agent.get(__MODULE__, fn {state, _} -> Map.get(state, name) end)
  end

  @spec set_channel_whitelist(name :: term, channels :: [String.t()]) :: :ok
  def set_channel_whitelist(name, channels) when is_list(channels) or is_nil(channels) do
    Agent.update(__MODULE__, fn {current_channel, channel_whitelist} ->
      new_channel_whitelist = if is_nil(channels) do
        Map.delete(channel_whitelist, name)
      else
        Map.put(channel_whitelist, name, channels)
      end

      {current_channel, new_channel_whitelist}
    end)
  end

  @spec get_channel(name :: term) :: [String.t()]
  def get_channel_whitelist(name) do
    Agent.get(__MODULE__, fn {_, state} -> Map.get(state, name) end)
  end
end
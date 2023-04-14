defmodule ChatBot.LoginHelper do
  @type credentials :: {user_id :: String.t(), pwhash :: String.t()}

  @spec login() :: credentials
  def login() do
    {username, password} = read_credentials()
    authenticate(username, password)
  end

  @spec authenticate(username :: String.t(), password :: String.t()) :: credentials
  defp authenticate(username, password) do
    resp = HTTPoison.post!(
      "https://chat.qed-verein.de/rubychat/account",
      "username=#{username}&password=#{password}"
    )

    cookies = resp.headers
    |> Enum.filter(fn {key, _} ->
        String.match?(key, ~r/\Aset-cookie\z/i)
    end)
    |> Enum.map(fn {_, value} -> value
      |> String.split(";")
      |> hd
      |> String.split("=", parts: 2)
      |> List.to_tuple()
    end)
    |> Enum.into(%{})


    {cookies["userid"], cookies["pwhash"]}
  end

  @spec read_credentials() :: {username :: String.t(), password :: String.t()}
  defp read_credentials() do
    [username, password | _] =
      File.read!("login.txt")
      |> String.split("\n")
      |> Enum.map(&String.trim/1)

    {username, password}
  end
end
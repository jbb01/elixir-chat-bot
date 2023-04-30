defmodule ChatBot.MixProject do
  use Mix.Project

  def project do
    [
      app: :chat_bot,
      version: "0.1.2",
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {ChatBot, []},
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # Chat
      {:httpoison, "~> 2.0"},
      {:websockex, "~> 0.4.3"},
      {:json, "~> 1.4"},
    ]
  end
end

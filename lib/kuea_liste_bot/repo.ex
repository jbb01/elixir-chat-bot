defmodule KueaListeBot.Repo do
  use Ecto.Repo,
    otp_app: :kuea_liste_bot,
    adapter: Ecto.Adapters.Postgres
end

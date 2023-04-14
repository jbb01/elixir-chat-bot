defmodule KueaListeBot.Repo.Migrations.AddKueas do
  use Ecto.Migration

  def change do
    create table :kueas do
      add :name,             :string
      add :creator_name,     :string
      add :num_participants, :integer

      timestamps()
    end
  end
end

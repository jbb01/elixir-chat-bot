defmodule KueaListeBot.Repo.Migrations.AddUsers do
  use Ecto.Migration

  def change do
    create table :users do
      add :first_name, :string
      add :last_name,  :string

      timestamps()
    end

    alter table :kueas do
      remove :creator_name
      add :creator_id, references :users
    end
  end
end

defmodule KueaListeBot.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field(:first_name, :string)
    field(:last_name, :string)

    timestamps()
  end

  def changeset(struct \\ %__MODULE__{}, params) do
    cast(struct, params, [:first_name, :last_name])
  end
end
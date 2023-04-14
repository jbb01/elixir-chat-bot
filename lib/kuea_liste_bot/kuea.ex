defmodule KueaListeBot.Kuea do
  use Ecto.Schema
  import Ecto.Changeset

  schema "kueas" do
    field(:name, :string)
    field(:num_participants, :integer)

    belongs_to(:creator, KueaListeBot.User)

    timestamps()
  end

  def changeset(struct \\ %__MODULE__{}, params) do
    cast(struct, params, [:name, :num_participants, :creator_id])
    |> cast_assoc(:creator)
    |> validate_required(:name)
  end
end

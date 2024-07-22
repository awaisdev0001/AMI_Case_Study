defmodule ExAssignment.Todos.Todo do
  use Ecto.Schema
  import Ecto.Changeset

  schema "todos" do
    field(:done, :boolean, default: false)
    field(:priority, :integer)
    field(:title, :string)
    field(:is_persist, :boolean, default: false)

    timestamps()
  end

  @doc false
  def changeset(todo, attrs) do
    todo
    |> cast(attrs, [:title, :priority, :done, :is_persist])
    |> validate_required([:title, :priority, :done])
    |> validate_number(:priority, greater_than_or_equal_to: 1)
  end
end

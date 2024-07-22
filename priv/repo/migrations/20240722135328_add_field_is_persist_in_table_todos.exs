defmodule ExAssignment.Repo.Migrations.AddFieldIsPersistInTableTodos do
  use Ecto.Migration

  def change do
    alter table(:todos) do
      add(:is_persist, :boolean, default: false, null: false)
    end  end
end

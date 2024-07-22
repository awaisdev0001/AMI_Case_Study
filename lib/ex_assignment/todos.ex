defmodule ExAssignment.Todos do
  @moduledoc """
  Provides operations for working with todos.
  """

  import Ecto.Query, warn: false
  alias ExAssignment.Repo

  alias ExAssignment.Todos.Todo

  @doc """
  Returns the list of todos, optionally filtered by the given type.

  ## Examples

      iex> list_todos(:open)
      [%Todo{}, ...]

      iex> list_todos(:done)
      [%Todo{}, ...]

      iex> list_todos()
      [%Todo{}, ...]

  """
  def list_todos(type \\ nil) do
    query = case type do
      :open -> from(t in Todo, where: not t.done)
      :done -> from(t in Todo, where: t.done)
      _ ->  Todo
    end

    from(t in query, order_by: t.priority)
    |> Repo.all()
  end

  @doc """
  Returns the next todo that is recommended to be done by the system.

  ASSIGNMENT: ...
  """
  def get_recommended() do
    with nil <- get_todo_by([is_persist: true]),
      [_|_] = todos <- list_todos(:open),
      %Todo{} = todo <- recommend_todo(todos) do
      {:ok, todo} = update_todo(todo, %{is_persist: true})
      todo
      else
      nil -> nil
      [] -> nil
      todo -> todo
    end
  end

  @doc """
  Gets a single todo.

  Raises `Ecto.NoResultsError` if the Todo does not exist.

  ## Examples

      iex> get_todo!(123)
      %Todo{}

      iex> get_todo!(456)
      ** (Ecto.NoResultsError)

  """
  def get_todo!(id), do: Repo.get!(Todo, id)

  @doc """
  Gets a single todo on the base of filtered options.

  Raises `Ecto.NoResultsError` if the Todo does not exist.

  ## Examples

      iex> get_todo_by([id: 123])
      %Todo{}

      iex> get_todo_by([id: 456])
      nil

  """
  def get_todo_by(opts), do: Repo.get_by(Todo, opts)

  @doc """
  Creates a todo.

  ## Examples

      iex> create_todo(%{field: value})
      {:ok, %Todo{}}

      iex> create_todo(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_todo(attrs \\ %{}) do
    %Todo{}
    |> Todo.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a todo.

  ## Examples

      iex> update_todo(todo, %{field: new_value})
      {:ok, %Todo{}}

      iex> update_todo(todo, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_todo(%Todo{} = todo, attrs) do
    todo
    |> Todo.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a todo.

  ## Examples

      iex> delete_todo(todo)
      {:ok, %Todo{}}

      iex> delete_todo(todo)
      {:error, %Ecto.Changeset{}}

  """
  def delete_todo(%Todo{} = todo) do
    Repo.delete(todo)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking todo changes.

  ## Examples

      iex> change_todo(todo)
      %Ecto.Changeset{data: %Todo{}}

  """
  def change_todo(%Todo{} = todo, attrs \\ %{}) do
    Todo.changeset(todo, attrs)
  end

  @doc """
  Marks the todo referenced by the given id as checked (done).

  ## Examples

      iex> check(1)
      :ok

  """
  def check(id) do
    {_, _} =
      from(t in Todo, where: t.id == ^id, update: [set: [done: true, is_persist: false]])
      |> Repo.update_all([])

    :ok
  end

  @doc """
  Marks the todo referenced by the given id as unchecked (not done).

  ## Examples

      iex> uncheck(1)
      :ok

  """
  def uncheck(id) do
    {_, _} =
      from(t in Todo, where: t.id == ^id, update: [set: [done: false]])
      |> Repo.update_all([])

    :ok
  end

  defp calculate_probabilities(todos) do
    total_weight = Enum.reduce(todos, 0, fn todo, acc -> acc + 1.0 / todo.priority end)

    Enum.map(todos, fn todo ->
      probability = (1.0 / todo.priority) / total_weight
      {todo, probability}
    end)
  end

  @doc """
  Recommends a to-do item based on calculated probabilities.

  ## Parameters

    - todos: A list of to-do items, each containing a `priority` field.

  ## Returns

    - A to-do item selected based on weighted random selection according to their probabilities.

  The function first calculates the probabilities, then generates a random value to select a to-do item whose cumulative probability matches the random value.

  ## Example

      iex> todos = [%{priority: 1}, %{priority: 2}, %{priority: 3}]
      iex> recommend_todo(todos)
      %{priority: 1} # The output can vary due to randomness
  """
  def recommend_todo(todos) do
    probabilities = calculate_probabilities(todos)
    cumulative_probabilities = Enum.scan(probabilities, 0, fn {_, prob}, acc -> acc + prob end)

    random_value = :rand.uniform()

    {{selected_todo, _probability}, _cumulative} =
      Enum.zip(probabilities, cumulative_probabilities)
      |> Enum.find(fn {{_, _prob}, cum_prob} -> random_value <= cum_prob end)

    selected_todo
  end

  @doc """
  Resets the `is_persist` flag of the currently persisted to-do item.

  This function finds the to-do item that is currently marked as persistent (`is_persist: true`) and updates its `is_persist` flag to `false`.

  ## Returns

    - `{:ok, _}` if the update was successful.
    - `nil` if no persisted to-do item was found.

  ## Example

      iex> reset_recommended_todo()
      {:ok, _} # If a persisted to-do was found and updated
      nil      # If no persisted to-do was found
  """
  def reset_recommended_todo() do
    todo = get_todo_by(is_persist: true)
    if todo do
      {:ok, _} = update_todo(todo, %{is_persist: false})
    end
  end

end

defmodule Cim.StoreLogics do
  @moduledoc """
  Stateless module for handling CRUD operations on a key-value store
  """
  alias Cim.Store

  @spec new() :: Store.t()
  def new(), do: %{}

  @doc """
  Retrieves a value under a given key and database. Error out if database or key does not exist
  """
  @spec get(Store.t(), Store.database(), Store.key()) ::
          {:ok, Store.value()} | {:error, :not_found}
  def get(store, database, key) do
    case store do
      %{^database => %{^key => value}} -> {:ok, value}
      _ -> {:error, :not_found}
    end
  end

  @doc """
  Stores a value under the given database and key. Will create in place if either database/key does not exist
  """
  @spec put(Store.t(), Store.database(), Store.key(), Store.value()) ::
          {:ok, Store.t()}
  def put(store, database, key, value) do
    updated_store =
      case Map.has_key?(store, database) do
        true -> put_in(store, [database, key], value)
        false -> store |> Map.put(database, %{key => value})
      end

    {:ok, updated_store}
  end

  @doc """
  Removes a database. Will error if database does not exist
  """
  @spec delete(Store.t(), Store.database()) :: {:ok, Store.t()} | {:error, :not_found}
  def delete(store, database) do
    case Map.has_key?(store, database) do
      true -> {:ok, Map.delete(store, database)}
      false -> {:error, :not_found}
    end
  end

  @doc """
  Removes a key under a database. Returns the deleted value or nil if key does not exist
  Returns error tuple if database not found
  """
  @spec delete(Store.t(), Store.database(), Store.key()) ::
          {:ok, {Store.value(), store :: Store.t()}} | {:error, :not_found}
  def delete(store, database, key) do
    case store do
      %{^database => %{^key => value}} ->
        {:ok, {value, Map.update!(store, database, &Map.delete(&1, key))}}

      %{^database => _} ->
        {:ok, {nil, store}}

      _ ->
        {:error, :not_found}
    end
  end

  @spec has_database?(Store.t(), Store.database()) :: boolean
  def has_database?(store, database), do: Map.has_key?(store, database)
end

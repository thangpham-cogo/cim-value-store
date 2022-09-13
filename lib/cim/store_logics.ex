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
  Stores a value under the given database and key. Will create in place if either database/key does not exist.

  Returns the updated store
  """
  @spec put(Store.t(), Store.database(), Store.key(), Store.value()) :: Store.t()
  def put(store, database, key, value) do
    if has_database?(store, database) do
      put_in(store, [database, key], value)
    else
      Map.put(store, database, %{key => value})
    end
  end

  @doc """
  Removes a database. Will error if database does not exist
  """
  @spec delete(Store.t(), Store.database()) :: {:ok, Store.t()} | {:error, :not_found}
  def delete(store, database) do
    if has_database?(store, database) do
      {:ok, Map.delete(store, database)}
    else
      {:error, :not_found}
    end
  end

  @doc """
  Removes a key under a database. Returns the deleted value or nil if key does not exist
  Returns error tuple if database not found
  """
  @spec delete(Store.t(), Store.database(), Store.key()) ::
          {:ok, {Store.value(), store :: Store.t()}} | {:error, :not_found}
  def delete(store, database, key) do
    if has_database?(store, database) do
      {:ok, pop_in(store, [database, key])}
    else
      {:error, :not_found}
    end
  end

  @spec has_database?(Store.t(), Store.database()) :: boolean
  def has_database?(store, database), do: Map.has_key?(store, database)
end

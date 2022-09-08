defmodule Cim.StoreLogics do
  @moduledoc """
  Stateless module for handling CRUD operations on a key-value store
  """
  alias Cim.Store

  @type get_response :: {:ok, any} | {:error, :not_found}
  @type put_response :: {:ok, Store.t()}
  @type delete_response :: {:ok, Store.t()}

  @spec get(Store.t(), database :: String.t(), key :: String.t()) :: get_response
  def get(store, database, key) do
    case get_in(store, [database, key]) do
      nil -> {:error, :not_found}
      value -> {:ok, value}
    end
  end

  @spec put(Store.t(), database :: String.t(), key :: String.t(), value :: binary()) ::
          put_response()
  def put(store, database, key, value) do
    updated_store =
      case Map.has_key?(store, database) do
        true -> put_in(store, [database, key], value)
        false -> store |> Map.put(database, %{key => value})
      end

    {:ok, updated_store}
  end

  @spec delete(Store.t(), database :: String.t()) :: delete_response()
  def delete(store, database) do
    {:ok, Map.delete(store, database)}
  end

  @spec delete(Store.t(), database :: String.t(), key :: String.t()) :: delete_response()
  def delete(store, database, key) do
    updated_store =
      case Map.has_key?(store, database) do
        true -> Map.update!(store, database, &Map.delete(&1, key))
        false -> store
      end

    {:ok, updated_store}
  end
end

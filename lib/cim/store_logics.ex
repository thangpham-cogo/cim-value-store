defmodule Cim.StoreLogics do
  @moduledoc """
  Stateless module for handling CRUD operations on a key-value store
  """

  @type get_response :: {:ok, any} | {:error, :not_found}

  alias Cim.Store

  @spec get(Store.t(), database :: String.t(), key :: String.t()) :: get_response
  def get(store, database, key) do
    case get_in(store, [database, key]) do
      nil -> {:error, :not_found}
      value -> {:ok, value}
    end
  end
end

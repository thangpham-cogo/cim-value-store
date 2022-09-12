defmodule Cim.LuaStore do
  @moduledoc """
  Wrapper around Cim.MemoryStore inside lua script, exposing only 3 functions and handling value unwrapping
  """
  alias Cim.{Store, MemoryStore}

  @spec read(Store.database(), Store.key()) :: Store.value() | nil
  def read(database, key) do
    case MemoryStore.get(database, key) do
      {:ok, value} -> value
      {:error, :not_found} -> nil
    end
  end

  @spec write(Store.database(), Store.key(), Store.value()) :: :ok
  def write(database, key, value), do: MemoryStore.put(database, key, value)

  @spec delete(Store.database(), Store.key()) :: Store.value() | nil
  def delete(database, key) do
    case MemoryStore.drop_key(database, key) do
      {:ok, value} -> value
      {:error, :not_found} -> nil
    end
  end
end

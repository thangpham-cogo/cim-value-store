defmodule Cim.LuaStore do
  @moduledoc """
  Wrapper around Cim.MemoryStore inside lua script, exposing only 3 functions and handling value unwrapping
  """
  alias Cim.MemoryStore

  @spec read(any, any) :: any | nil
  def read(database, key) do
    case store().get(database, key) do
      {:ok, value} -> value
      {:error, :not_found} -> nil
    end
  end

  @spec write(any, any, any) :: :ok
  def write(database, key, value), do: store().put(database, key, value)

  @spec delete(any, any) :: any | nil
  def delete(database, key) do
    case MemoryStore.drop_key(database, key) do
      {:ok, value} -> value
      {:error, :not_found} -> nil
    end
  end

  defp store(), do: Application.get_env(:cim, :store, Cim.MemoryStore)
end

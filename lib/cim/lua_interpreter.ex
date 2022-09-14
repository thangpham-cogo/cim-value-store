defmodule Cim.LuaInterpreter do
  @moduledoc """
  Thin wrapper around erlang luerl for interacting with Cim.StoreServer in lua script
  """

  @namespace "cim"

  alias Cim.{Store, StoreServer, Luerl}

  @doc """
  Evaluates a valid lua script against a particular database in Cim.StoreServer.

  Allows the use of cim.read/1, cim.write/2 and cim.delete/1 in script.
  """
  @spec eval(Store.database(), script :: binary) :: Luerl.eval_response()
  def eval(database, script) do
    database
    |> init()
    |> Luerl.eval(script)
  end

  defp init(database) do
    Luerl.initial_state()
    |> Luerl.set_table([@namespace], %{})
    |> Luerl.set_table([@namespace, "read"], cim_read(database))
    |> Luerl.set_table([@namespace, "write"], cim_write(database))
    |> Luerl.set_table([@namespace, "delete"], cim_delete(database))
  end

  defp cim_read(database), do: fn [key] -> [read(database, key)] end
  defp cim_write(database), do: fn [key, value] -> [write(database, key, value)] end
  defp cim_delete(database), do: fn [key] -> [delete(database, key)] end

  defp read(database, key) do
    case StoreServer.get(database, key) do
      {:ok, value} -> value
      {:error, :not_found} -> nil
    end
  end

  defp write(database, key, value), do: StoreServer.put(database, key, value)

  defp delete(database, key) do
    case StoreServer.drop_key(database, key) do
      {:ok, value} -> value
      {:error, :not_found} -> nil
    end
  end
end

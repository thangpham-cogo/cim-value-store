defmodule Cim.LuaInterpreter do
  @moduledoc """
  Thin wrapper around erlang luerl for interacting with Cim.MemoryStore in lua script
  """

  @namespace "cim"
  alias Cim.{Store, LuaStore}

  @spec eval(Store.database(), script :: binary) ::
          {:error, :syntax_error | {:internal_error, any} | {:runtime_error, any}} | {:ok, any}
  def eval(database, script) when is_binary(database) do
    with {:ok, state} <- init(database),
         {:ok, chunk, next_state} <- :luerl.load(script, state),
         {:ok, result} when is_list(result) <- :luerl.eval(chunk, next_state) do
      {:ok, unwrap(result)}
    else
      # https://github.com/rvirding/luerl/blob/bc655178dc8f59f29199fd7df77a7c314c0f2e02/src/luerl_comp.erl#L301
      {:error, errors, warnings} when is_list(errors) and is_list(warnings) ->
        {:error, :syntax_error}

      {:error, {:lua_error, reason, _state}, _stack_trace} ->
        {:error, {:runtime_error, reason}}

      {:error, reason, _stack_trace} ->
        {:error, {:internal_error, reason}}

      error ->
        {:error, {:internal_error, error}}
    end
  end

  defp init(database) do
    initial_state = bind_store_api(database)

    {:ok, initial_state}
  end

  defp bind_store_api(database) do
    state = :luerl.set_table([@namespace], %{}, :luerl.init())
    functions_config = bind_functions_to(database)

    functions_config
    |> Enum.reduce(state, fn {paths, func}, next_state ->
      :luerl.set_table(paths, func, next_state)
    end)
  end

  defp bind_functions_to(database) do
    %{
      [@namespace, "read"] => fn [key] -> [LuaStore.read(database, key)] end,
      [@namespace, "write"] => fn [key, value] -> [LuaStore.write(database, key, value)] end,
      [@namespace, "delete"] => fn [key] -> [LuaStore.delete(database, key)] end
    }
  end

  defp unwrap([]), do: ""
  defp unwrap([{:ok, value}]), do: value
  defp unwrap([result]), do: result
end

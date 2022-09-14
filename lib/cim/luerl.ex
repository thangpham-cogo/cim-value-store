defmodule Cim.Luerl do
  @moduledoc """
  Wrapper around erlang luerl to minimize its api surface & make piping easier
  """

  @type luerl_state :: any
  @type eval_response ::
          {:error, :syntax_error | {:internal_error, any} | {:runtime_error, any}} | {:ok, any}

  @doc """
  Initialize a new sandboxed lua vm instance, returning a fresh vm state
  """
  @spec initial_state() :: luerl_state
  defdelegate initial_state(), to: :luerl_sandbox, as: :init

  @doc """
  Stores a value in the lua's vm table. Returns the updated vm state
  """
  @spec set_table(luerl_state, paths :: list(String.t()), value :: any) :: luerl_state
  def set_table(state, paths, value), do: :luerl.set_table(paths, value, state)

  @doc """
  Runs a script against the given vm state.
  """
  @spec eval(luerl_state, script :: binary) :: eval_response
  def eval(state, script) do
    with {:ok, chunk, next_state} <- :luerl.load(script, state),
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

  defp unwrap([]), do: ""
  defp unwrap([result]), do: result
end

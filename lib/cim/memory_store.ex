defmodule Cim.Store do
  @moduledoc """
  Store type definition
  """

  @type t() :: %{String.t() => %{String.t() => binary()}}
end

defmodule Cim.MemoryStore do
  @moduledoc """
  A gen server for holding the store, dispatching client requests to and passing back response from StoreLogics
  """
  use GenServer

  alias Cim.StoreLogics

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  @impl true
  def init(nil) do
    {:ok, new_store()}
  end

  def get(pid \\ __MODULE__, database, key) do
    GenServer.call(pid, {:get, [database, key]})
  end

  def put(pid \\ __MODULE__, database, key, value) do
    GenServer.cast(pid, {:put, [database, key, value]})
  end

  def drop_database(pid \\ __MODULE__, database) do
    GenServer.cast(pid, {:delete, database})
  end

  def drop_key(pid \\ __MODULE__, database, key) do
    GenServer.cast(pid, {:delete, [database, key]})
  end

  @impl true
  def handle_call({:get, [database, key]}, _from, state) do
    {:reply, StoreLogics.get(state, database, key), state}
  end

  @impl true
  def handle_cast({:put, [database, key, value]}, state) do
    {:ok, next_state} = StoreLogics.put(state, database, key, value)

    {:noreply, next_state}
  end

  @impl true
  def handle_cast({:delete, [database, key]}, state) do
    {:ok, next_state} = StoreLogics.delete(state, database, key)

    {:noreply, next_state}
  end

  @impl true
  def handle_cast({:delete, database}, state) do
    {:ok, next_state} = StoreLogics.delete(state, database)

    {:noreply, next_state}
  end

  defp new_store(), do: StoreLogics.new()
end

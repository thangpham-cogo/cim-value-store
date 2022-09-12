defmodule Cim.Store do
  @moduledoc """
  Store type definition
  """

  @type t() :: %{any => %{any => binary}}
end

defmodule Cim.MemoryStore do
  @moduledoc """
  A gen server for holding the store, dispatching client requests to and passing back response from StoreLogics
  """
  use GenServer

  alias Cim.StoreLogics

  @behaviour Cim.StoreBehavior

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  @impl GenServer
  def init(nil) do
    {:ok, new_store()}
  end

  @impl Cim.StoreBehavior
  def get(pid \\ __MODULE__, database, key) do
    GenServer.call(pid, {:get, [database, key]})
  end

  @impl Cim.StoreBehavior
  def put(pid \\ __MODULE__, database, key, value) do
    GenServer.cast(pid, {:put, [database, key, value]})
  end

  @impl Cim.StoreBehavior
  def drop_database(pid \\ __MODULE__, database) do
    GenServer.call(pid, {:delete, database})
  end

  @impl Cim.StoreBehavior
  def drop_key(pid \\ __MODULE__, database, key) do
    GenServer.call(pid, {:delete, [database, key]})
  end

  @impl Cim.StoreBehavior
  def has_database?(pid \\ __MODULE__, database) do
    GenServer.call(pid, {:database_exists?, database})
  end

  @impl GenServer
  def handle_call({:get, [database, key]}, _from, state) do
    {:reply, StoreLogics.get(state, database, key), state}
  end

  @impl GenServer
  def handle_call({:delete, [database, key]}, _from, state) do
    case StoreLogics.delete(state, database, key) do
      {:ok, {deleted, next_state}} ->
        {:reply, {:ok, deleted}, next_state}

      {:error, :not_found} ->
        {:reply, {:error, :not_found}, state}
    end
  end

  @impl GenServer
  def handle_call({:delete, database}, _from, state) do
    case StoreLogics.delete(state, database) do
      {:ok, next_state} ->
        {:reply, :ok, next_state}

      {:error, :not_found} ->
        {:reply, {:error, :not_found}, state}
    end
  end

  @impl GenServer
  def handle_call({:database_exists?, database}, _from, state) do
    {:reply, StoreLogics.has_database?(state, database), state}
  end

  @impl GenServer
  def handle_cast({:put, [database, key, value]}, state) do
    {:ok, next_state} = StoreLogics.put(state, database, key, value)

    {:noreply, next_state}
  end

  defp new_store(), do: StoreLogics.new()
end

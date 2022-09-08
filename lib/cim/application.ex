defmodule Cim.Application do
  @moduledoc false

  use Application
  require Logger

  @impl true
  def start(_type, _args) do
    children = [
      Cim.MemoryStore
    ]

    opts = [strategy: :one_for_one, name: Cim.Supervisor]

    {:ok, pid} = Supervisor.start_link(children, opts)
    Logger.info("Store Server started")

    {:ok, pid}
  end
end

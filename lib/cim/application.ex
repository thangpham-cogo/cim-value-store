defmodule Cim.Application do
  @moduledoc false

  use Application
  require Logger

  @impl true
  def start(_type, _args) do
    children = [
      Cim.MemoryStore,
      {Plug.Cowboy, scheme: :http, plug: CimWeb.Router, options: [port: port()]}
    ]

    opts = [strategy: :one_for_one, name: Cim.Supervisor]

    Logger.info("Key-Value Store Server listening on port #{port()}")
    Supervisor.start_link(children, opts)
  end

  defp port() do
    Application.get_env(:cim, :port) |> String.to_integer()
  end
end

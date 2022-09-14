defmodule Cim.Application do
  @moduledoc false

  use Application
  require Logger

  @impl true
  def start(_type, _args) do
    children = [
      Cim.StoreServer,
      {Plug.Cowboy, scheme: :http, plug: CimWeb.Router, options: [port: port()]}
    ]

    opts = [strategy: :one_for_one, name: Cim.Supervisor]

    Logger.info("Key-Value Store Server listening on port #{port()}")
    Supervisor.start_link(children, opts)
  end

  defp port() do
    port =
      Application.get_env(:cim, Cim.StoreServer)
      |> Keyword.get(:port)

    case Integer.parse(port) do
      {port, ""} ->
        port

      _ ->
        Logger.critical("Invalid port value: #{port}. Shutting down all applications")
        exit({:shutdown, :invalid_port})
    end
  end
end

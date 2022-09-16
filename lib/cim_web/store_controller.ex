defmodule CimWeb.StoreController do
  @moduledoc """
  Handlers for interacting with Cim.StoreServer
  """

  import Plug.Conn

  alias Cim.{LuaInterpreter, StoreServer}

  @spec get(Plug.Conn.t()) :: Plug.Conn.t()
  def get(%{path_params: %{"database" => database, "key" => key}} = conn) do
    case StoreServer.get(database, key) do
      {:ok, value} ->
        ok(conn, stringify(value))

      {:error, :not_found} ->
        not_found(conn)
    end
  end

  @spec put(Plug.Conn.t()) :: Plug.Conn.t()
  def put(%{path_params: %{"database" => database, "key" => key}} = conn) do
    with {:ok, body, conn} <- read_body(conn),
         :ok <- StoreServer.put(database, key, body) do
      ok(conn)
    end
  end

  @spec delete_database(Plug.Conn.t()) :: Plug.Conn.t()
  def delete_database(%{path_params: %{"database" => database}} = conn) do
    case StoreServer.drop_database(database) do
      :ok -> ok(conn)
      {:error, :not_found} -> not_found(conn)
    end
  end

  @spec delete_key(Plug.Conn.t()) :: Plug.Conn.t()
  def delete_key(%{path_params: %{"database" => database, "key" => key}} = conn) do
    case StoreServer.drop_key(database, key) do
      {:ok, value} when not is_nil(value) -> ok(conn)
      {:ok, nil} -> not_found(conn)
      {:error, :not_found} -> not_found(conn)
    end
  end

  @spec post(Plug.Conn.t()) :: Plug.Conn.t()
  def post(%{path_params: %{"database" => database}} = conn) do
    with {:ok, script, conn} <- read_body(conn),
         true <- StoreServer.has_database?(database),
         {:ok, value} <- LuaInterpreter.eval(database, script) do
      ok(conn, stringify(value))
    else
      false ->
        not_found(conn)

      {:error, :syntax_error} ->
        bad_request(conn, "invalid lua script")

      {:error, {:runtime_error, _reason}} ->
        bad_request(conn, "invalid lua script")
    end
  end

  defp ok(conn, body \\ "")
  defp ok(conn, ""), do: send_resp(conn, 200, "")

  defp ok(conn, body) do
    conn
    |> put_resp_content_type("application/octet-stream")
    |> send_resp(200, to_string(body))
  end

  defp bad_request(conn, err_message) do
    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(400, err_message)
  end

  defp not_found(conn), do: send_resp(conn, 404, "")
  defp stringify(value), do: to_string(value)
end

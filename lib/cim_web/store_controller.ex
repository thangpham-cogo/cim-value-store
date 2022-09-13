defmodule CimWeb.StoreController do
  @moduledoc """
  Handlers for interacting with Cim.MemoryStore
  """

  import Plug.Conn

  alias Cim.{LuaInterpreter, MemoryStore}

  @spec get(Plug.Conn.t()) :: Plug.Conn.t()
  def get(%{params: %{"database" => database, "key" => key}} = conn) do
    case MemoryStore.get(database, key) do
      {:ok, value} ->
        ok(conn, value)

      {:error, :not_found} ->
        not_found(conn)
    end
  end

  @spec put(Plug.Conn.t()) :: Plug.Conn.t()
  def put(%{params: %{"database" => database, "key" => key}} = conn) do
    with {:ok, body, conn} <- read_body(conn),
         :ok <- MemoryStore.put(database, key, body) do
      ok(conn)
    end
  end

  @spec delete_database(Plug.Conn.t()) :: Plug.Conn.t()
  def delete_database(%{params: %{"database" => database}} = conn) do
    case MemoryStore.drop_database(database) do
      :ok -> ok(conn)
      {:error, :not_found} -> not_found(conn)
    end
  end

  @spec delete_key(Plug.Conn.t()) :: Plug.Conn.t()
  def delete_key(%{params: %{"database" => database, "key" => key}} = conn) do
    case MemoryStore.drop_key(database, key) do
      {:ok, value} when not is_nil(value) -> ok(conn)
      {:ok, nil} -> not_found(conn)
      {:error, :not_found} -> not_found(conn)
    end
  end

  @spec post(Plug.Conn.t()) :: Plug.Conn.t()
  def post(%{params: %{"database" => database}} = conn) do
    with {:ok, script, conn} <- read_body(conn),
         true <- MemoryStore.has_database?(database),
         {:ok, value} <- LuaInterpreter.eval(database, script) do
      ok(conn, inspect(value))
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
    |> put_resp_header("content-type", "application/octet-stream")
    |> send_resp(200, body)
  end

  defp bad_request(conn, err_message) do
    conn
    |> put_resp_header("content-type", "text/plain")
    |> send_resp(400, err_message)
  end

  defp not_found(conn), do: send_resp(conn, 404, "")
end

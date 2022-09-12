defmodule CimWeb.StoreController do
  @moduledoc """
  Handlers for interacting with Cim.MemoryStore
  """

  import Plug.Conn

  alias Cim.LuaInterpreter

  @spec get(Plug.Conn.t(), atom) :: Plug.Conn.t()
  def get(conn, store \\ store()) do
    %{"database" => database, "key" => key} = conn.params

    case store.get(database, key) do
      {:ok, value} ->
        conn
        |> put_resp_header("content-type", "application/octet-stream")
        |> send_resp(200, value)

      {:error, :not_found} ->
        not_found(conn)
    end
  end

  @spec put(Plug.Conn.t(), atom) :: Plug.Conn.t()
  def put(conn, store \\ store()) do
    {:ok, body, _} = read_body(conn)
    %{"database" => database, "key" => key} = conn.params
    :ok = store.put(database, key, body)

    send_resp(conn, 200, "")
  end

  @spec delete_database(Plug.Conn.t(), atom) :: Plug.Conn.t()
  def delete_database(conn, store \\ store()) do
    case store.drop_database(Map.fetch!(conn.params, "database")) do
      :ok -> send_resp(conn, 200, "")
      {:error, :not_found} -> not_found(conn)
    end
  end

  @spec delete_key(Plug.Conn.t(), atom) :: Plug.Conn.t()
  def delete_key(conn, store \\ store()) do
    %{"database" => database, "key" => key} = conn.params

    case store.drop_key(database, key) do
      {:ok, value} when not is_nil(value) -> send_resp(conn, 200, "")
      {:ok, nil} -> not_found(conn)
      {:error, :not_found} -> not_found(conn)
    end
  end

  @spec post(Plug.Conn.t(), atom) :: Plug.Conn.t()
  def post(conn, store \\ store()) do
    {:ok, script, _} = read_body(conn)

    database = Map.fetch!(conn.params, "database")

    with true <- store.has_database?(database),
         {:ok, value} <- LuaInterpreter.eval(database, script) do
      conn
      |> put_req_header("content-type", "application/octet-stream")
      |> send_resp(200, inspect(value))
    else
      false ->
        not_found(conn)

      {:error, :syntax_error} ->
        send_text_error_message(conn, "invalid lua script")

      {:error, {:runtime_error, _reason}} ->
        send_text_error_message(conn, "invalid lua script")
    end
  end

  defp send_text_error_message(conn, err_message, status_code \\ 400) do
    conn
    |> put_req_header("content-type", "text/plain")
    |> send_resp(status_code, err_message)
  end

  defp not_found(conn), do: send_resp(conn, 404, "")

  defp store(), do: Application.get_env(:cim, :store, Cim.MemoryStore)
end

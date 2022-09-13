defmodule CimWeb.StoreControllerTest do
  require Logger
  use ExUnit.Case, async: true
  use Plug.Test

  alias CimWeb.Router
  alias Cim.MemoryStore

  @opts Router.init([])

  setup :db_with_one_entry

  describe "PUT /{database}/{key}" do
    test "inserts a value under a new key in an existing database", ctx do
      conn = request(:put, to_path(ctx.db, "new_key"), "value")

      assert %{state: :sent, status: 200} = conn
    end

    test "inserts a value under an existing database and key", ctx do
      conn = request(:put, to_path(ctx.db, ctx.key), "new_value")

      assert %{state: :sent, status: 200} = conn
    end

    test "inserts a value under a new database and key" do
      conn = request(:put, to_path("new_controller_test_db", "new_key"), "new_value")

      assert %{state: :sent, status: 200} = conn
    end
  end

  describe "GET /{database}/{key}" do
    test "returns value if key exists", ctx do
      conn = request(:get, to_path(ctx.db, ctx.key))

      assert %{state: :sent, status: 200} = conn
      assert conn.resp_body == ctx.value
      assert {"content-type", "application/octet-stream"} in conn.resp_headers
    end

    test "returns 404 if database or key not found", ctx do
      conn = request(:get, to_path(ctx.db, "unknown_key"))

      assert %{state: :sent, status: 404, resp_body: ""} = conn
    end
  end

  describe "DELETE /{database}" do
    test "removes and returns 200 if database exists", ctx do
      conn = request(:delete, to_path(ctx.db))

      assert %{state: :sent, status: 200, resp_body: ""} = conn
    end

    test "returns 404 if database does not exist" do
      conn = request(:delete, to_path("unknown_db"))

      assert %{state: :sent, status: 404, resp_body: ""} = conn
    end
  end

  describe "DELETE /{database}/{key}" do
    test "removes and returns 200 if key exists", ctx do
      conn = request(:delete, to_path(ctx.db, ctx.key))

      assert %{state: :sent, status: 200, resp_body: ""} = conn
    end

    test "returns 404 if database does not exist" do
      conn = request(:delete, to_path("unknown_db", "key"))

      assert %{state: :sent, status: 404, resp_body: ""} = conn
    end

    test "returns 404 if key does not exist", ctx do
      conn = request(:delete, to_path(ctx.db, "unknown_key"))

      assert %{state: :sent, status: 404, resp_body: ""} = conn
    end

    test "returns 404 if both database and key do not exist" do
      conn = request(:delete, to_path("unknown_db", "unknown_key"))

      assert %{state: :sent, status: 404, resp_body: ""} = conn
    end
  end

  describe "POST /{database}" do
    test "returns 200 with output for valid request", ctx do
      conn = request(:post, to_path(ctx.db), ~s|return "hello world"|)

      assert %{state: :sent, status: 200, resp_body: ~s|"hello world"|} = conn
      assert {"content-type", "application/octet-stream"} in conn.resp_headers
    end

    test "returns 200 for valid multiline script", ctx do
      script = """
      function test()
        return "hello world"
      end
      return test()
      """

      conn = request(:post, to_path(ctx.db), script)

      assert %{state: :sent, status: 200, resp_body: ~s|"hello world"|} = conn
      assert {"content-type", "application/octet-stream"} in conn.resp_headers
    end

    test "returns 200 for valid script that uses cim store lua api", ctx do
      script = """
      cim.write("ef", 12)
      ef_value = cim.read("ef")
      print(ef_value)
      return cim.delete("ef")
      """

      conn = request(:post, to_path(ctx.db), script)

      assert %{state: :sent, status: 200, resp_body: "12"} = conn
      assert {"content-type", "application/octet-stream"} in conn.resp_headers
    end

    test "returns 404 if database not found" do
      conn = request(:post, to_path("unknown_db"), ~s|return "hello world"|)

      assert %{state: :sent, status: 404} = conn
    end

    test "returns 400 error for script with invalid syntax", ctx do
      conn = request(:post, to_path(ctx.db), ~s|this is not valid lua syntax|)

      assert %{state: :sent, status: 400, resp_body: "invalid lua script"} = conn
      assert {"content-type", "text/plain"} in conn.resp_headers
    end

    test "returns 400 error for script with runtime error", ctx do
      conn = request(:post, to_path(ctx.db), ~s|return unknown_func("foo")|)

      assert %{state: :sent, status: 400, resp_body: "invalid lua script"} = conn
      assert {"content-type", "text/plain"} in conn.resp_headers
    end
  end

  defp db_with_one_entry(ctx) do
    db = unique_suffix("db")
    key = unique_suffix("key")
    value = unique_suffix("value")

    MemoryStore.put(db, key, value)
    Logger.debug(test: ctx.test, db: db, key: key, value: value)

    {:ok, db: db, key: key, value: value}
  end

  defp request(method, path) when method in [:get, :delete] do
    method
    |> conn(path)
    |> Router.call(@opts)
  end

  defp request(:put, path, body) do
    :put
    |> conn(path, body)
    |> put_req_header("content-type", "application/octet-stream")
    |> Router.call(@opts)
  end

  defp request(:post, path, body) do
    :post
    |> conn(path, body)
    |> Router.call(@opts)
  end

  defp to_path(part1, part2), do: to_path([part1, part2])
  defp to_path(part) when is_binary(part), do: to_path([part])
  defp to_path(parts), do: Enum.map_join(parts, &("/" <> &1))

  defp unique_suffix(str), do: "#{str}-#{System.unique_integer([:positive])}"
end

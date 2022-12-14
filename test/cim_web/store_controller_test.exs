defmodule CimWeb.StoreControllerTest do
  require Logger
  use ExUnit.Case, async: true
  use Plug.Test

  alias CimWeb.Router
  alias Cim.StoreServer

  @opts Router.init([])

  setup :db_with_one_entry

  describe "PUT /{database}/{key}" do
    test "inserts a value under a new key in an existing database", ctx do
      conn = request(:put, to_path(ctx.db, "new_key"), "value")
      assert %{state: :sent, status: 200} = conn

      conn = request(:get, to_path(ctx.db, "new_key"))
      assert %{state: :sent, status: 200, resp_body: "value"} = conn
      assert_octet_stream_content_type(conn)
    end

    test "inserts a value under an existing database and key", ctx do
      conn = request(:put, to_path(ctx.db, ctx.key), "new_value")
      assert %{state: :sent, status: 200} = conn

      conn = request(:get, to_path(ctx.db, ctx.key))
      assert %{state: :sent, status: 200, resp_body: "new_value"} = conn
      assert_octet_stream_content_type(conn)
    end

    test "inserts a value under a new database and key" do
      new_db = unique_suffix("new_db")
      key = "new_key"
      value = "new_value"

      conn = request(:get, to_path(new_db, key))
      assert %{state: :sent, status: 404, resp_body: ""} = conn

      conn = request(:put, to_path(new_db, key), value)
      assert %{state: :sent, status: 200} = conn

      conn = request(:get, to_path(new_db, key))
      assert %{state: :sent, status: 200, resp_body: ^value} = conn
      assert_octet_stream_content_type(conn)
    end

    test "inserts the value as given regardless of content type",
         ctx do
      cases = %{
        "application/x-www-form-urlencoded" => "hello=world",
        "text/plain; charset=utf-8" => "hello world",
        "application/octet-stream; charset=utf-8" => <<"hello-world">>,
        "application/json" => Jason.encode!(%{hello: "world"})
      }

      cases
      |> Enum.each(fn {content_type, body} ->
        key = unique_suffix("test_content_type")

        conn = request(:put, to_path(ctx.db, key), body, content_type)
        assert %{state: :sent, status: 200} = conn

        conn = request(:get, to_path(ctx.db, key))
        assert %{state: :sent, status: 200} = conn
        assert conn.resp_body == body
        assert_octet_stream_content_type(conn)
      end)
    end
  end

  describe "GET /{database}/{key}" do
    test "returns value if key exists", ctx do
      conn = request(:get, to_path(ctx.db, ctx.key))

      assert %{state: :sent, status: 200} = conn
      assert conn.resp_body == ctx.value
      assert_octet_stream_content_type(conn)
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

      conn = request(:get, to_path(ctx.db, ctx.key))
      assert %{state: :sent, status: 404, resp_body: ""} = conn
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

      conn = request(:get, to_path(ctx.db, ctx.key))
      assert %{state: :sent, status: 404, resp_body: ""} = conn
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

      assert %{state: :sent, status: 200, resp_body: "hello world"} = conn
      assert_octet_stream_content_type(conn)
    end

    test "returns 200 for valid multiline script", ctx do
      script = """
      function test()
        return "hello world"
      end
      return test()
      """

      conn = request(:post, to_path(ctx.db), script)

      assert %{state: :sent, status: 200, resp_body: "hello world"} = conn
      assert_octet_stream_content_type(conn)
    end

    test "returns 200 for valid script that uses cim store lua api", ctx do
      script = """
      cim.write("ef", 12)
      ef_value = cim.read("ef")
      return cim.delete("ef")
      """

      conn = request(:post, to_path(ctx.db), script)

      assert %{state: :sent, status: 200, resp_body: "12"} = conn
      assert_octet_stream_content_type(conn)
    end

    test "can access value being set by a separate GET request", ctx do
      key = "ef"
      value = "12"
      request(:put, to_path(ctx.db, key), value)
      script = ~s|return cim.read("#{key}") * 10|

      conn = request(:post, to_path(ctx.db), script)

      assert %{state: :sent, status: 200, resp_body: "120.0"} = conn
      assert_octet_stream_content_type(conn)
    end

    test "returns 404 if database not found" do
      conn = request(:post, to_path("unknown_db"), ~s|return "hello world"|)

      assert %{state: :sent, status: 404} = conn
    end

    test "returns 400 error for script with invalid syntax", ctx do
      conn = request(:post, to_path(ctx.db), ~s|this is not valid lua syntax|)

      assert %{state: :sent, status: 400, resp_body: "invalid lua script"} = conn
      assert_text_plain_content_type(conn)
    end

    test "returns 400 error for script with runtime error", ctx do
      conn = request(:post, to_path(ctx.db), ~s|return unknown_func("foo")|)

      assert %{state: :sent, status: 400, resp_body: "invalid lua script"} = conn
      assert_text_plain_content_type(conn)
    end
  end

  defp db_with_one_entry(ctx) do
    db = unique_suffix("db")
    key = unique_suffix("key")
    value = unique_suffix("value")

    StoreServer.put(db, key, value)
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
    |> Router.call(@opts)
  end

  defp request(:post, path, body) do
    :post
    |> conn(path, body)
    |> Router.call(@opts)
  end

  defp request(:put, path, body, content_type) do
    :put
    |> conn(path, body)
    |> put_req_header("content-type", content_type)
    |> Router.call(@opts)
  end

  defp to_path(part1, part2), do: to_path([part1, part2])
  defp to_path(part) when is_binary(part), do: to_path([part])
  defp to_path(parts), do: Enum.map_join(parts, &("/" <> &1))

  defp unique_suffix(str), do: "#{str}-#{System.unique_integer([:positive])}"

  defp assert_octet_stream_content_type(conn) do
    assert {"content-type", "application/octet-stream; charset=utf-8"} in conn.resp_headers
  end

  defp assert_text_plain_content_type(conn) do
    assert {"content-type", "text/plain; charset=utf-8"} in conn.resp_headers
  end
end

defmodule CimWeb.StoreControllerTest do
  use ExUnit.Case, async: true
  use Plug.Test

  alias CimWeb.Router
  alias Cim.MemoryStore

  @opts Router.init([])

  setup :default_db_with_entry

  describe "PUT /{database}/{key}" do
    test "inserts a value under a new key in an existing database", ctx do
      conn = put_key(ctx.db, "new_key", "value")

      assert %{state: :sent, status: 200} = conn
    end

    test "inserts a value under an existing database and key", ctx do
      conn = put_key(ctx.db, ctx.key, "new_value")

      assert %{state: :sent, status: 200} = conn
    end

    test "inserts a value under a new database and key" do
      conn = put_key("new_controller_test_db", "new_key", "new_value")

      assert %{state: :sent, status: 200} = conn
    end
  end

  describe "GET /{database}/{key}" do
    test "returns value if key exists", ctx do
      conn = get("/#{ctx.db}/#{ctx.key}")

      assert %{state: :sent, status: 200} = conn
      assert conn.resp_body == ctx.value
      assert {"content-type", "application/octet-stream"} in conn.resp_headers
    end

    test "returns 404 if database or key not found", ctx do
      conn = get("/#{ctx.db}/unknown_key")

      assert %{state: :sent, status: 404, resp_body: ""} = conn
    end
  end

  describe "DELETE /{database}" do
    test "removes and returns 200 if database exists" do
      db = "controller_test_db_delete"
      MemoryStore.put(db, "key", "value")

      conn = delete("/#{db}")

      assert %{state: :sent, status: 200, resp_body: ""} = conn
    end

    test "returns 404 if database does not exist" do
      conn = delete("/unknown_db")

      assert %{state: :sent, status: 404, resp_body: ""} = conn
    end
  end

  describe "DELETE /{database}/{key}" do
    test "removes and returns 200 if key exists", ctx do
      conn = delete("/#{ctx.db}/#{ctx.key}")

      assert %{state: :sent, status: 200, resp_body: ""} = conn
    end

    test "returns 404 if database does not exist" do
      conn = delete("/unknown_db/key")

      assert %{state: :sent, status: 404, resp_body: ""} = conn
    end

    test "returns 404 if key does not exist", ctx do
      conn = delete("/#{ctx.db}/unknown_key")

      assert %{state: :sent, status: 404, resp_body: ""} = conn
    end

    test "returns 404 if both database and key do not exist" do
      conn = delete("/unknown_db/unknown_key")

      assert %{state: :sent, status: 404, resp_body: ""} = conn
    end
  end

  describe "POST /{database}" do
    setup do
      lua_script_db = "lua_script_db"
      MemoryStore.put(lua_script_db, "key", "value")

      {:ok, lua_script_db: lua_script_db}
    end

    test "returns 200 with output for valid request", ctx do
      conn = post_script(ctx.lua_script_db, ~s|return "hello world"|)

      assert %{state: :sent, status: 200, resp_body: ~s|"hello world"|} = conn
    end

    test "returns 200 for valid multiline script", ctx do
      script = """
      function test()
        return "hello world"
      end
      return test()
      """

      conn = post_script(ctx.lua_script_db, script)

      assert %{state: :sent, status: 200, resp_body: ~s|"hello world"|} = conn
    end

    test "returns 200 for valid script that uses cim store lua api", ctx do
      script = """
      cim.write("ef", 12)
      ef_value = cim.read("ef")
      print(ef_value)
      return cim.delete("ef")
      """

      conn = post_script(ctx.lua_script_db, script)

      assert %{state: :sent, status: 200, resp_body: "12"} = conn
    end

    test "returns 404 if database not found" do
      conn = post_script("unknown_db", ~s|return "hello world"|)

      assert %{state: :sent, status: 404} = conn
    end

    test "returns 400 error for script with invalid syntax", ctx do
      conn = post_script(ctx.lua_script_db, ~s|this is not valid lua syntax|)

      assert %{state: :sent, status: 400, resp_body: "invalid lua script"} = conn
    end

    test "returns 400 error for script with runtime error", ctx do
      conn = post_script(ctx.lua_script_db, ~s|return unknown_func("foo")|)

      assert %{state: :sent, status: 400, resp_body: "invalid lua script"} = conn
    end
  end

  defp default_db_with_entry(_ctx) do
    db = "controller_test_db"
    key = "key"
    value = "value"

    MemoryStore.put(db, "key", "value")

    {:ok, db: db, key: key, value: value}
  end

  defp put_key(db, key, value) do
    :put
    |> conn("/#{db}/#{key}", value)
    |> put_req_header("content-type", "application/octet-stream")
    |> Router.call(@opts)
  end

  defp get(path) do
    :get
    |> conn(path)
    |> Router.call(@opts)
  end

  defp delete(path) do
    :delete
    |> conn(path)
    |> Router.call(@opts)
  end

  defp post_script(db, script) do
    :post
    |> conn("/#{db}", script)
    |> Router.call(@opts)
  end
end

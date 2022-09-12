defmodule CimWeb.StoreControllerTest do
  use ExUnit.Case, async: true
  use Plug.Test
  import Mox

  setup :verify_on_exit!

  alias CimWeb.Router

  @opts Router.init([])

  describe "PUT /{database}/{key}" do
    test "inserts a value under a database key" do
      expect(MockStore, :put, fn "db", "key", "value" -> :ok end)

      conn =
        :put
        |> conn("/db/key", "value")
        |> put_req_header("content-type", "application/octet-stream")
        |> Router.call(@opts)

      assert %{state: :sent, status: 200} = conn
    end
  end

  describe "GET /{database}/{key}" do
    test "returns data from store if key exists" do
      expect(MockStore, :get, fn "db", "key" -> {:ok, "value"} end)

      conn =
        :get
        |> conn("/db/key")
        |> Router.call(@opts)

      assert %{state: :sent, status: 200, resp_body: "value"} = conn
      assert {"content-type", "application/octet-stream"} in conn.resp_headers
    end

    test "returns 404 if database or key not found" do
      expect(MockStore, :get, fn "db", "key" -> {:error, :not_found} end)

      conn =
        :get
        |> conn("/db/key")
        |> Router.call(@opts)

      assert %{state: :sent, status: 404, resp_body: ""} = conn
    end
  end

  describe "DELETE /{database}" do
    test "removes and returns 200 if database exists" do
      expect(MockStore, :drop_database, fn "db" -> :ok end)

      conn =
        :delete
        |> conn("/db")
        |> Router.call(@opts)

      assert %{state: :sent, status: 200, resp_body: ""} = conn
    end

    test "returns 404 if database does not exist" do
      expect(MockStore, :drop_database, fn "unknown_db" -> {:error, :not_found} end)

      conn =
        :delete
        |> conn("/unknown_db")
        |> Router.call(@opts)

      assert %{state: :sent, status: 404, resp_body: ""} = conn
    end
  end

  describe "DELETE /{database}/{key}" do
    test "removes and returns 200 if key exists" do
      expect(MockStore, :drop_key, fn "db", "key" -> :ok end)

      conn =
        :delete
        |> conn("/db/key")
        |> Router.call(@opts)

      assert %{state: :sent, status: 200, resp_body: ""} = conn
    end

    test "returns 404 if either database or key does not exist" do
      expect(MockStore, :drop_key, fn "db", "key" -> {:error, :not_found} end)

      conn =
        :delete
        |> conn("/db/key")
        |> Router.call(@opts)

      assert %{state: :sent, status: 404, resp_body: ""} = conn
    end
  end

  describe "POST /{database}" do
    test "returns 200 with output for valid request" do
      expect(MockStore, :has_database?, fn "db" -> true end)

      conn =
        :post
        |> conn("/db", ~s|return "hello world"|)
        |> Router.call(@opts)

      assert %{state: :sent, status: 200, resp_body: ~s|"hello world"|} = conn
    end

    test "returns 200 for valid multiline script" do
      expect(MockStore, :has_database?, fn "db" -> true end)

      script = """
      function test()
        return "hello world"
      end
      return test()
      """

      conn =
        :post
        |> conn("/db", script)
        |> Router.call(@opts)

      assert %{state: :sent, status: 200, resp_body: ~s|"hello world"|} = conn
    end

    test "returns 404 if database not found" do
      expect(MockStore, :has_database?, fn "db" -> false end)

      conn =
        :post
        |> conn("/db", ~s|return "hello world"|)
        |> Router.call(@opts)

      assert %{state: :sent, status: 404} = conn
    end

    test "returns 400 error for script with invalid syntax" do
      expect(MockStore, :has_database?, fn "db" -> true end)

      conn =
        :post
        |> conn("/db", ~s|this is not valid lua syntax|)
        |> Router.call(@opts)

      assert %{state: :sent, status: 400, resp_body: "invalid lua script"} = conn
    end

    test "returns 400 error for script with runtime error" do
      expect(MockStore, :has_database?, fn "db" -> true end)

      conn =
        :post
        |> conn("/db", ~s|return unknown_func("foo")|)
        |> Router.call(@opts)

      assert %{state: :sent, status: 400, resp_body: "invalid lua script"} = conn
    end
  end
end

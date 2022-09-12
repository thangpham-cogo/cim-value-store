defmodule Cim.LuaStoreTest do
  use ExUnit.Case, async: true
  import Mox

  setup :verify_on_exit!

  alias Cim.LuaStore

  describe "read/1" do
    test "returns value if key is set" do
      database = "db"
      key = "key"
      value = "value"

      expect(MockStore, :get, fn ^database, ^key -> {:ok, value} end)

      assert value == LuaStore.read(database, key)
    end

    test "returns nil if key not set" do
      database = "db"
      key = "key"

      expect(MockStore, :get, fn ^database, ^key -> {:error, :not_found} end)

      assert nil == LuaStore.read(database, key)
    end
  end

  describe "write/2" do
    test "returns :ok if writing to key succeeds" do
      database = "db"
      key = "key"
      value = "value"

      expect(MockStore, :put, fn ^database, ^key, ^value -> :ok end)

      assert :ok = LuaStore.write(database, key, value)
    end
  end

  describe "delete/1" do
    test "returns deleted value if key is set" do
      database = "db"
      key = "key"
      value = "value"

      expect(MockStore, :drop_key, fn ^database, ^key ->
        {:ok, {value, %{"database" => %{}}}}
      end)

      assert value == LuaStore.delete(database, key)
    end

    test "returns nil if key is set" do
      database = "db"
      key = "key"

      expect(MockStore, :drop_key, fn ^database, ^key ->
        {:ok, {nil, %{"database" => %{}}}}
      end)

      assert nil == LuaStore.delete(database, key)
    end
  end
end

defmodule Cim.LuaStoreTest do
  use ExUnit.Case, async: true

  alias Cim.LuaStore
  alias Cim.MemoryStore

  setup do
    db = "lua_store"
    MemoryStore.put(db, "key", "value")

    {:ok, db: db}
  end

  describe "read/1" do
    test "returns value if key is set", ctx do
      assert "value" == LuaStore.read(ctx.db, "key")
    end

    test "returns nil if key not set", ctx do
      assert nil == LuaStore.read(ctx.db, "unknown_key")
    end
  end

  describe "write/2" do
    test "returns :ok if writing to key succeeds", ctx do
      key = "new_key"
      value = "value"

      assert :ok = LuaStore.write(ctx.db, key, value)
      assert value == LuaStore.read(ctx.db, key)
    end
  end

  describe "delete/1" do
    test "returns deleted value if key is set", ctx do
      assert "value" = LuaStore.delete(ctx.db, "key")
    end

    test "returns nil if key is not set", ctx do
      assert nil == LuaStore.delete(ctx.db, "unknown_key")
    end
  end
end

defmodule Cim.StoreLogicsTest do
  use ExUnit.Case, async: true

  alias Cim.StoreLogics

  setup :store_with_one_database_and_key

  describe "get/3" do
    test "returns an ok tuple with the stored value given an existing database and key", ctx do
      assert {:ok, "value"} = StoreLogics.get(ctx.store, "db", "key")
    end

    test "returns an error tuple with not found as the reason if the database does not exist",
         ctx do
      assert {:error, :not_found} = StoreLogics.get(ctx.store, "unknown_db", "key")
    end

    test "returns an error tuple with not found as the reason if the key does not exist", ctx do
      assert {:error, :not_found} = StoreLogics.get(ctx.store, "db", "unknown_key")
    end

    test "returns an error tuple with not found as the reason if both database and key do not exist",
         ctx do
      assert {:error, :not_found} = StoreLogics.get(ctx.store, "unknown_db", "unknown_key")
    end
  end

  describe "put/4" do
    test "replaces an existing value and returns the updated store", ctx do
      assert %{"db" => %{"key" => "new_value"}} =
               StoreLogics.put(ctx.store, "db", "key", "new_value")
    end

    test "stores the value under a new key and returns the updated store", ctx do
      assert %{"db" => %{"new_key" => "value"}} =
               StoreLogics.put(ctx.store, "db", "new_key", "value")
    end

    test "stores the value under a new database & key and returns the updated store",
         ctx do
      assert Map.merge(%{"new_db" => %{"key" => "value"}}, ctx.store) ==
               StoreLogics.put(ctx.store, "new_db", "key", "value")
    end

    test "returns the current store if key already set with the same value", ctx do
      assert ctx.store == StoreLogics.put(ctx.store, "db", "key", "value")
    end
  end

  describe "delete/2" do
    test "removes an existing database and returns ok tuple with updated store", ctx do
      assert {:ok, %{}} = StoreLogics.delete(ctx.store, "db")
    end

    test "returns not found error tuple if database does not exist", %{
      store: store
    } do
      assert {:error, :not_found} = StoreLogics.delete(store, "unknown_db")
    end
  end

  describe "delete/3" do
    test "removes an existing key and returns ok tuple with the key value & the updated store",
         ctx do
      assert {:ok, {"value", %{}}} = StoreLogics.delete(ctx.store, "db", "key")
    end

    test "returns nil with the existing store if key does not exist", %{
      store: store
    } do
      assert {:ok, {nil, ^store}} = StoreLogics.delete(store, "db", "unknown_key")
    end

    test "returns not found error tuple if database does not exist", %{
      store: store
    } do
      assert {:error, :not_found} = StoreLogics.delete(store, "unknown_db", "key")
    end
  end

  describe "has_database?/1" do
    test "returns true if database exists", ctx do
      assert StoreLogics.has_database?(ctx.store, "db")
    end

    test "returns false if database does not exist", ctx do
      refute StoreLogics.has_database?(ctx.store, "unknown_db")
    end
  end

  def store_with_one_database_and_key(_ctx) do
    store = %{
      "db" => %{
        "key" => "value"
      }
    }

    {:ok, store: store}
  end
end

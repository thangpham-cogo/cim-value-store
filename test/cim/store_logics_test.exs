defmodule Cim.StoreLogicsTest do
  use ExUnit.Case

  alias Cim.StoreLogics

  setup do
    store = %{
      "db" => %{
        "key" => "value"
      }
    }

    {:ok, store: store}
  end

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
  end

  describe "put/4" do
    test "replaces an existing value and returns ok tuple with the updated store", ctx do
      assert {:ok, %{"db" => %{"key" => "new_value"}}} =
               StoreLogics.put(ctx.store, "db", "key", "new_value")
    end

    test "stores the value under a new key and returns ok tuple with the updated store", ctx do
      assert {:ok, %{"db" => %{"new_key" => "value"}}} =
               StoreLogics.put(ctx.store, "db", "new_key", "value")
    end

    test "stores the value under a new database & key and returns ok tuple with the updated store",
         ctx do
      assert {:ok, %{"new_db" => %{"key" => "value"}}} =
               StoreLogics.put(ctx.store, "new_db", "key", "value")
    end
  end

  describe "delete/2" do
    test "removes an existing database and returns ok tuple with updated store", ctx do
      assert {:ok, %{}} = StoreLogics.delete(ctx.store, "db")
    end

    test "does nothing if database does not exist and returns ok tuple with store", %{
      store: store
    } do
      assert {:ok, ^store} = StoreLogics.delete(store, "unknown_db")
    end
  end

  describe "delete/3" do
    test "removes an existing key and returns ok tuple with updated store", ctx do
      assert {:ok, %{}} = StoreLogics.delete(ctx.store, "db", "key")
    end

    test "does nothing if database does not exist and returns ok tuple with store", %{
      store: store
    } do
      assert {:ok, ^store} = StoreLogics.delete(store, "unknown_db", "key")
    end
  end
end

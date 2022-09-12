defmodule Cim.LuaInterpreterTest do
  use ExUnit.Case, async: true

  alias Cim.LuaInterpreter

  describe "eval/2" do
    test "handle single-line script" do
      script = ~s|return "hello world"|

      assert {:ok, "hello world"} = LuaInterpreter.eval("db", script)
    end

    test "handle multiline script" do
      script = """
      function test()
        return "hello world"
      end
      return test()
      """

      assert {:ok, "hello world"} = LuaInterpreter.eval("db", script)
    end
  end
end

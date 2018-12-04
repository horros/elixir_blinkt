defmodule ElixirBlinktTest do
  use ExUnit.Case
  doctest ElixirBlinkt

  test "greets the world" do
    assert ElixirBlinkt.hello() == :world
  end
end

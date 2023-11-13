defmodule BrewTest do
  use ExUnit.Case
  doctest Brew

  test "greets the world" do
    assert Brew.hello() == :world
  end
end

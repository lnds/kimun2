defmodule Interpolation do
  def greet(name) do
    "hello #{name || "stranger"}#{if name == "", do: "!"}"
  end
end

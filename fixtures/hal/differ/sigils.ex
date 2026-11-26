defmodule Sigils do
  def check(s) do
    s =~ ~r/a+b/i or s in ~w(x y)
  end
end

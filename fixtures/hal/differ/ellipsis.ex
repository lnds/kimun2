defmodule Ellipsis do
  @type pair :: [integer, ...]
  def first([h, ...]), do: h
end

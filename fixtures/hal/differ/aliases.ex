defmodule Shop.Cart.Item do
  def total(xs) do
    Shop.Cart.sum(xs)
  end
end

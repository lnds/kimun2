defmodule Shop do
  @moduledoc """
  Prices and totals, written without atoms or keywords.
  """

  def total(items, discount) do
    sum = Enum.reduce(items, 0, fn item, acc -> acc + item end)

    if discount > 0 and sum > 100 do
      sum - discount
    else
      sum
    end
  end

  defp pick(x) when is_integer(x) do
    case x do
      0 -> 1
      n when n > 10 -> n * 2
      _ -> x
    end
  end

  def blank(c) do
    c == ?a or c == nil or false
  end

  def each(list) do
    for x <- list, x != nil do
      pick(x) |> to_string()
    end
  end
end

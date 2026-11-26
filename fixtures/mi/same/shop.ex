defmodule Shop do
  # Totals, written without atoms or keywords.

  def total(items, discount) do
    sum = Enum.reduce(items, 0, fn item, acc -> acc + item end)

    if discount > 0 and sum > 100 do
      sum - discount
    else
      sum
    end
  end

  def pick(x) do
    case x do
      0 -> 1
      n when n > 10 -> n * 2
      _ -> x
    end
  end
end

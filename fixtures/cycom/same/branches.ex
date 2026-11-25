defmodule M do
  @x if true, do: 1, else: 2

  def f(0), do: :zero
  def f(n) when n > 0 and n < 10 do
    case n do
      1 -> :one
      _ -> :many
    end
  end

  defp g(x) do
    fun = fn
      1 -> :a
      _ -> :b
    end
    with {:ok, y} <- x, true <- y > 0 || y < -1 do
      cond do
        y > 5 -> fun.(1)
        true -> :c
      end
    end
  end
end

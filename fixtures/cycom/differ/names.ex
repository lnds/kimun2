defmodule Names do
  def valid?(x) do
    if x, do: true, else: false
  end

  def fetch!(m), do: Map.fetch!(m, :k)
end

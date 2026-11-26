defmodule Names do
  def fetch!(m, k) do
    if valid?(k) do
      Map.fetch!(m, k)
    end
  end

  def valid?(k), do: k != nil
end

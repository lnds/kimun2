defmodule Ops do
  def outside(k, xs) do
    k not in xs and Kernel.not(k == 0)
  end
end

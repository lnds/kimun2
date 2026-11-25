defmodule Clauses do
  def safe(f) do
    try do
      f.()
    catch
      :exit, _ -> :exited
    end
  end
end

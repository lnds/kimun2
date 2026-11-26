defmodule Atoms do
  def status(x) do
    if x > 0, do: :ok, else: {:error, :negative}
  end
end

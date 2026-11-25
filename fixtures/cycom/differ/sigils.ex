defmodule Sigils do
  def check(warnings) do
    assert warnings =~
             ~s|no route path for Router matches "/unknown/#{123}"|
  end
end

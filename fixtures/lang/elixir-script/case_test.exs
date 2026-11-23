defmodule CaseTest do
  use ExUnit.Case

  @moduledoc """
  Docs.
  """

  # A comment.
  test "a # inside a string" do
    assert "#{1}" == "1"
    assert ~s(# not a comment) != ""
  end
end

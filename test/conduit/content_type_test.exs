defmodule Conduit.ContentTypeTest do
  use ExUnit.Case
  doctest Conduit.ContentType

  describe "unknown content type" do
    test "raises an error" do
      assert_raise Conduit.UnknownContentTypeError, "Unknown content type \"unknown/unknown\"", fn ->
        Conduit.ContentType.format(%Conduit.Message{}, "unknown/unknown", [])
      end
    end
  end
end

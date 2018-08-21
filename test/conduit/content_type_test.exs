defmodule Conduit.ContentTypeTest do
  use ExUnit.Case
  alias Conduit.{ContentType, Message, UnknownContentTypeError}
  doctest Conduit.ContentType

  describe "unknown content type" do
    test "raises an error" do
      assert_raise UnknownContentTypeError, "Unknown content type \"unknown/unknown\"", fn ->
        ContentType.format(%Message{}, "unknown/unknown", [])
      end
    end
  end
end

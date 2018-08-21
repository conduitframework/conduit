defmodule Conduit.EncodingTest do
  use ExUnit.Case
  alias Conduit.{Encoding, Message, UnknownEncodingError}
  doctest Conduit.Encoding

  describe "unknown encoding type" do
    test "raises an error" do
      assert_raise UnknownEncodingError, "Unknown encoding \"unknown\"", fn ->
        Encoding.encode(%Message{}, "unknown", [])
      end
    end
  end
end

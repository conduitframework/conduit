defmodule Conduit.EncodingTest do
  use ExUnit.Case
  doctest Conduit.Encoding

  describe "unknown encoding type" do
    test "raises an error" do
      assert_raise Conduit.UnknownEncodingError, "Unknown encoding \"unknown\"", fn ->
        Conduit.Encoding.encode(%Conduit.Message{}, "unknown", [])
      end
    end
  end
end

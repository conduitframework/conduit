defmodule ConduitTest do
  use ExUnit.Case
  doctest Conduit

  describe "broker_name/1,2" do
    test "generates a broker name with passed args" do
      assert Conduit.broker_name(Broker) == Broker
      assert Conduit.broker_name(Broker, nil) == Broker
      assert Conduit.broker_name(Broker, S1) == Broker.S1
      assert Conduit.broker_name(Broker, postfix: S1) == Broker.S1
    end
  end
end

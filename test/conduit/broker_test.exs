defmodule Conduit.BrokerTest do
  use ExUnit.Case

  defmodule ContentType do
    use Conduit.Plug.Builder

    def call(message, opts) do
      message
      |> put_meta(:content_type, opts)
    end
  end

  defmodule Adapter do
    use Supervisor

    def start_link(opts) do
      Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
    end

    def init(opts) do
      import Supervisor.Spec

      send(Conduit.BrokerTest, {opts})

      supervise([], strategy: :one_for_one)
    end

    def publish(message, opts) do
      send(Conduit.BrokerTest, {message, opts})
    end
  end

  defmodule Broker do
    use Conduit.Broker, otp_app: :my_app

    configure do

    end
  end
end

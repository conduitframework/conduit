defmodule Conduit.TestAdapter do
  use Conduit.Adapter
  use Supervisor

  def start_link(broker, topology, subscribers, opts) do
    Supervisor.start_link(__MODULE__, [broker, topology, subscribers, opts])
  end

  def init(opts) do
    import Supervisor.Spec

    process = Application.get_env(:conduit, :shared_test_process)
    if process, do: send(process, {:adapter, opts})

    supervise([], strategy: :one_for_one)
  end

  def publish(message, opts) do
    process = Application.get_env(:conduit, :shared_test_process, self)
    send(process, {:publish, message, opts})

    message
  end
end

defmodule Conduit.TestAdapter do
  use Conduit.Adapter
  use Supervisor

  @moduledoc """
  This module is intended to be used instead of a normal adapter in tests.

  See `Conduit.Test` for details.
  """

  @doc false
  def start_link(broker, topology, subscribers, opts) do
    Supervisor.start_link(__MODULE__, [broker, topology, subscribers, opts])
  end

  @doc false
  def init(opts) do
    import Supervisor.Spec

    process = Application.get_env(:conduit, :shared_test_process)
    if process, do: send(process, {:adapter, opts})

    supervise([], strategy: :one_for_one)
  end

  @doc """
  Sends a publish message to the current process or the shared_test_process
  if that is configured.
  """
  def publish(message, config, opts) do
    process = Application.get_env(:conduit, :shared_test_process, self())
    send(process, {:publish, message, config, opts})

    message
  end
end

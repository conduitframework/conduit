defmodule Conduit.Adapter.Memory do
  use GenServer

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(opts) do
    {:ok, consumers: {}}
  end

  def configure do

  end

  def consume(pipeline, opts) do

  end

  def publish(:destination, message) do

  end
end

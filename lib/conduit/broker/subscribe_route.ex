defmodule Conduit.Broker.SubscribeRoute do
  defstruct name: nil, subscriber: nil, opts: [], pipelines: []

  def new(name, subscriber, opts) do
    %__MODULE__{
      name: name,
      subscriber: subscriber,
      opts: opts
    }
  end

  def expand_subscriber(%__MODULE__{} = route, namespace) do
    %{route | subscriber: Module.concat(namespace, route.subscriber)}
  end

  def put_pipelines(%__MODULE__{} = route, pipelines) do
    %{route | pipelines: pipelines}
  end
end

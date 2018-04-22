defmodule Conduit.SubscribeRoute do
  defstruct [:name, :subscriber, :opts, :pipelines]

  def new(name, subscriber, opts) do
    %__MODULE__{
      name: name,
      subscriber: subscriber,
      opts: opts
    }
  end

  def extend(%__MODULE__{} = route, namespace, pipelines) do
    %{route | subscriber: Module.concat(namespace, route.subscriber), pipelines: pipelines}
  end
end

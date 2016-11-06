defmodule Conduit.Broker.IncomingScope do
  import Conduit.Broker.Scope

  defstruct pipelines: [], subscribers: [], namespace: nil

  def init(module) do
    Module.register_attribute(module, :subscriber_configs, accumulate: true)
    Module.register_attribute(module, :subscribers, accumulate: true)
    put_scope(module, nil)
  end

  def start_scope(module, namespace) do
    if get_scope(module) do
      raise "incoming cannot be nested under anything else"
    else
      put_scope(module, %__MODULE__{namespace: namespace})
    end
  end

  def end_scope(module) do
    scope = get_scope(module)

    Enum.each(scope.subscribers, fn {name, subscriber, opts} ->
      Module.put_attribute(module, :subscriber_configs,
        {name, Module.concat(scope.namespace, subscriber), scope.pipelines, opts})
    end)

    put_scope(module, nil)
  end

  def pipe_through(module, pipelines) do
    put_scope(module, %{get_scope(module) | pipelines: pipelines})
  end

  def subscribe(module, name, subscriber, opts) do
    if scope = get_scope(module) do
      sub = {name, subscriber, opts}
      put_scope(module, %{scope | subscribers: [sub | scope.subscribers]})
    else
      raise "subscribe can only be called under an incoming block"
    end
  end

  def compile(module) do
    Module.get_attribute(module, :subscriber_configs)
    |> Enum.each(fn {name, subscriber, pipeline_names, opts} ->
      mod = generate_module(module, name, "_incoming")
      expanded_pipelines = expand_pipelines(module, pipeline_names)

      defmodule mod do
        use Conduit.Plug.Builder

        Enum.each(expanded_pipelines, fn pipeline ->
          plug pipeline
        end)

        plug subscriber
      end
      Module.put_attribute(module, :subscribers, {name, {mod, opts}})
    end)
  end

  def methods do
    quote do
      @subscribers_map Enum.into(@subscribers, %{})
      def subscribers, do: @subscribers_map
    end
  end
end

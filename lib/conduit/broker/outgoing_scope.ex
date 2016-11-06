defmodule Conduit.Broker.OutgoingScope do
  import Conduit.Broker.Scope

  defstruct pipelines: [], publishers: []

  def init(broker) do
    Module.register_attribute(broker, :publisher_configs, accumulate: true)
    Module.register_attribute(broker, :publishers, accumulate: true)
    put_scope(broker, nil)
  end

  def start_scope(broker) do
    if get_scope(broker) do
      raise "outgoing cannot be nested under anything else"
    else
      put_scope(broker, %__MODULE__{})
    end
  end

  def pipe_through(broker, pipelines) do
    put_scope(broker, %{get_scope(broker) | pipelines: pipelines})
  end

  def publish(broker, name, opts) do
    if scope = get_scope(broker) do
      sub = {name, opts}
      put_scope(broker, %{scope | publishers: [sub | scope.publishers]})
    else
      raise "publish can only be called under an incoming block"
    end
  end

  def end_scope(broker) do
    scope = get_scope(broker)

    Enum.each(scope.publishers, fn {name, opts} ->
      Module.put_attribute(broker, :publisher_configs, {name, scope.pipelines, opts})
    end)

    put_scope(broker, nil)
  end

  def compile(broker) do
    Module.get_attribute(broker, :publisher_configs)
    |> Enum.each(fn {name, pipeline_names, opts} ->
      module = generate_module(broker, name, "_outgoing")
      expanded_pipelines = expand_pipelines(broker, pipeline_names)

      defmodule module do
        use Conduit.Plug.Builder
        @otp_app Module.get_attribute(broker, :otp_app)
        @broker broker

        Enum.each(expanded_pipelines, fn pipeline ->
          plug pipeline
        end)

        plug :publish, opts

        defp publish(message, opts) do
          adapter =
            Application.get_env(@otp_app, @broker)
            |> Keyword.get(:adapter)

          adapter.publish(message, opts)
        end
      end
      Module.put_attribute(broker, :publishers, {name, {module, opts}})
    end)
  end

  def methods do
    quote do
      @publishers_map Enum.into(@publishers, %{})
      def publishers, do: @publishers_map

      def publish(name, message, opts \\ []) do
        publishers[name].call(message)
      end
    end
  end
end

defmodule Conduit.Broker.OutgoingScope do
  @moduledoc false
  import Conduit.Broker.Scope

  defstruct pipelines: [], publishers: []

  @doc """
  Initializes outgoing scope for publishers.
  """
  def init(broker) do
    Module.register_attribute(broker, :publisher_configs, accumulate: true)
    Module.register_attribute(broker, :publishers, accumulate: true)
    put_scope(broker, nil)
  end

  @doc """
  Starts a scope block.
  """
  def start_scope(broker) do
    if get_scope(broker) do
      raise Conduit.BrokerDefinitionError, "outgoing cannot be nested under anything else"
    else
      put_scope(broker, %__MODULE__{})
    end
  end

  @doc """
  Sets the pipelines for the scope.
  """
  def pipe_through(broker, pipelines) do
    put_scope(broker, %{get_scope(broker) | pipelines: pipelines})
  end

  @doc """
  Defines a publisher.
  """
  def publish(broker, name, opts) do
    if scope = get_scope(broker) do
      sub = {name, opts}
      put_scope(broker, %{scope | publishers: [sub | scope.publishers]})
    else
      raise Conduit.BrokerDefinitionError, "publish can only be called under an outgoing block"
    end
  end

  @doc """
  Ends a scope block.
  """
  def end_scope(broker) do
    scope = get_scope(broker)

    Enum.each(scope.publishers, fn {name, opts} ->
      Module.put_attribute(broker, :publisher_configs, {name, scope.pipelines, opts})
    end)

    put_scope(broker, nil)
  end

  @doc """
  Compiles the publishers.
  """
  def compile(broker) do
    Module.get_attribute(broker, :publisher_configs)
    |> Enum.each(fn {name, pipeline_names, opts} ->
      module = generate_module(broker, name, "_outgoing")
      expanded_pipelines = expand_pipelines(broker, pipeline_names)
      destination = Keyword.get(opts, :to, Atom.to_string(name))

      defmodule module do
        @moduledoc false
        use Conduit.Plug.Builder
        @otp_app Module.get_attribute(broker, :otp_app)
        @broker broker

        plug :put_destination, destination

        Enum.each(expanded_pipelines, fn pipeline ->
          plug pipeline
        end)

        def call(message, _next, opts) do
          adapter =
            Application.get_env(@otp_app, @broker)
            |> Keyword.get(:adapter)

          adapter.publish(message, opts)
        end
      end
      Module.put_attribute(broker, :publishers, {name, {module, opts}})
    end)
  end

  @doc """
  Defines publishing related methods for the broker.
  """
  def methods do
    quote do
      @publishers_map Enum.into(@publishers, %{})
      def publishers, do: @publishers_map

      def publish(name, message, opts \\ []) do
        {publisher, broker_opts} = publishers()[name]

        publisher.run(message, Keyword.merge(broker_opts, opts))
      end
    end
  end
end

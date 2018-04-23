defmodule Conduit.Broker.OutgoingScope do
  @moduledoc false
  import Conduit.Broker.Scope
  alias Conduit.PublishRoute

  defstruct pipelines: [], publish_routes: []

  @doc """
  Initializes outgoing scope for publishers.
  """
  def init(broker) do
    Module.register_attribute(broker, :publish_routes, accumulate: true)
    put_scope(broker, nil)
  end

  @doc false
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
      route = PublishRoute.new(name, opts)
      put_scope(broker, %{scope | publish_routes: [route | scope.publish_routes]})
    else
      raise Conduit.BrokerDefinitionError, "publish can only be called under an outgoing block"
    end
  end

  @doc false
  def end_scope(broker) do
    scope = get_scope(broker)

    scope.publish_routes
    |> Enum.map(&PublishRoute.put_pipelines(&1, expand_pipelines(broker, scope.pipelines)))
    |> Enum.each(fn route ->
      Module.put_attribute(broker, :publish_routes, route)
    end)

    put_scope(broker, nil)
  end

  @doc false
  def compile(broker, route) do
    pipelines = Enum.map(route.pipelines, &{&1, []})
    destination = Keyword.get(route.opts, :to, Atom.to_string(route.name))

    plugs =
      [{:raw_publish, route.opts} | pipelines] ++
        [
          {:put_private, broker: broker, received: route.name},
          {:put_new_destination, destination}
        ]

    Conduit.Plug.Builder.compile(plugs, quote(do: & &1))
  end

  @doc """
  Defines publishing related methods for the broker.
  """
  def methods do
    quote unquote: false do
      def publish_routes, do: @publish_routes

      def publish(name, message, opts \\ [])

      import Conduit.Plug.MessageActions, only: [put_new_destination: 3, put_private: 3]

      for route <- @publish_routes do
        pipeline = Conduit.Broker.OutgoingScope.compile(__MODULE__, route)

        def publish(unquote(route.name), message, opts) do
          message
          |> Conduit.Message.put_private(:opts, opts)
          |> unquote(pipeline).()
        end
      end

      def publish(name, _, _) do
        message = """
        Undefined publish route #{inspect(name)}.

        Perhaps #{inspect(name)} is misspelled. Otherwise, it can be defined in #{inspect(__MODULE__)} by adding:

            outgoing do
              subscribe #{inspect(name)}, to: "my.destination", other: "options"
            end
        """

        raise Conduit.UndefinedPublishRouteError, message
      end

      @doc false
      def raw_publish(message, _next, broker_opts) do
        opts = Conduit.Message.get_private(message, :opts)

        Conduit.Broker.raw_publish(@otp_app, __MODULE__, message, Keyword.merge(broker_opts, opts))
      end
    end
  end
end

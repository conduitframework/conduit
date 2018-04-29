defmodule Conduit.Broker.Topology do
  @moduledoc false
  import Conduit.Broker.Scope
  alias Conduit.Util
  alias Conduit.Broker.Topology.{Queue, Exchange}

  @doc false
  def init(module) do
    Module.register_attribute(module, :topology, accumulate: true)
    put_scope(module, nil)
  end

  @doc false
  def start_scope(module) do
    if get_scope(module) do
      raise Conduit.BrokerDefinitionError, "configure cannot be nested under anything else"
    else
      put_scope(module, __MODULE__)
    end
  end

  @doc false
  def end_scope(module) do
    put_scope(module, nil)
  end

  @doc false
  def queue(module, name, opts) do
    case get_scope(module) do
      __MODULE__ ->
        Module.put_attribute(module, :topology, {Queue, [Util.escape(name), Util.escape(opts)]})
        []

      _ ->
        raise Conduit.BrokerDefinitionError, "queue can only be called in a configure block"
    end
  end

  @doc false
  def exchange(module, name, opts) do
    case get_scope(module) do
      __MODULE__ ->
        Module.put_attribute(module, :topology, {Exchange, [Util.escape(name), Util.escape(opts)]})
        []

      _ ->
        raise Conduit.BrokerDefinitionError, "exchange can only be called in a configure block"
    end
  end

  def methods do
    quote unquote: false do
      topology = @topology

      def topology do
        unquote(topology)
        |> Enum.reverse()
        |> Enum.map(fn {module, args} ->
          apply(module, :new, args)
        end)
      end

      def topology_config do
        Enum.map(topology(), fn %{__struct__: module} = data ->
          module.to_tuple(data)
        end)
      end
    end
  end
end

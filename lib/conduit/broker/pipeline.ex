defmodule Conduit.Broker.Pipeline do
  defstruct name: nil, plugs: []
  import Conduit.Broker.Scope

  @doc """
  Initializes the pipeline scope.
  """
  def init(module) do
    Module.register_attribute(module, :pipelines, accumulate: true)
    put_scope(module, nil)
  end

  @doc """
  Starts a scope block.
  """
  def start_scope(module, name) do
    if get_scope(module) do
      raise Conduit.BrokerDefinitionError, "pipeline cannot be nested under anything else"
    else
      put_scope(module, %__MODULE__{name: name})
    end
  end

  @doc """
  Ends a scope block.
  """
  def end_scope(module) do
    pipeline = get_scope(module)

    Module.put_attribute(module, :pipelines, {pipeline.name, pipeline})
    put_scope(module, nil)
  end

  @doc """
  Sets the pipelines for the scope.
  """
  def plug(module, plug) do
    pipeline = get_scope(module)
    put_scope(module, %{pipeline | plugs: [plug | pipeline.plugs]})
  end
end

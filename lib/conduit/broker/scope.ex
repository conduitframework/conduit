defmodule Conduit.Broker.Scope do
  @moduledoc false

  @doc """
  Returns scope for the module
  """
  @spec get_scope(module) :: term
  def get_scope(module) do
    Module.get_attribute(module, :scope)
  end

  @doc """
  Sets scope for the module
  """
  @spec put_scope(module, scope :: term) :: :ok
  def put_scope(module, scope) do
    Module.put_attribute(module, :scope, scope)
  end

  @doc """
  Converts a list of pipeline names into a list of pipeline modules
  """
  @spec expand_pipelines(module, pipeline_names :: [atom]) :: [module]
  def expand_pipelines(module, pipeline_names) do
    pipelines = Module.get_attribute(module, :pipelines)

    pipeline_names
    |> Enum.map(&pipelines[&1])
    |> Enum.reverse()
  end
end

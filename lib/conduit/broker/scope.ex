defmodule Conduit.Broker.Scope do
  @moduledoc false

  @doc """
  Returns scope for the module
  """
  def get_scope(module) do
    Module.get_attribute(module, :scope)
  end

  @doc """
  Sets scope for the module
  """
  def put_scope(module, scope) do
    Module.put_attribute(module, :scope, scope)
  end

  @doc """
  Generates a submodule name with a postfix
  """
  def generate_module(module, name, postfix) do
    module_name =
      name
      |> Atom.to_string()
      |> Kernel.<>(postfix)
      |> Macro.camelize()

    Module.concat(module, module_name)
  end

  @doc """
  Converts a list of pipeline names into a list of pipeline modules
  """
  def expand_pipelines(module, pipeline_names) do
    pipelines = Module.get_attribute(module, :pipelines)

    pipeline_names
    |> Enum.map(&pipelines[&1])
  end
end

defmodule Conduit.Broker.Scope do
  def get_scope(module) do
    Module.get_attribute(module, :scope)
  end

  def put_scope(module, scope) do
    Module.put_attribute(module, :scope, scope)
  end

  def generate_module(module, name, postfix) do
    module_name =
      name
      |> Atom.to_string
      |> Kernel.<>(postfix)
      |> Macro.camelize

    Module.concat(module, module_name)
  end

  def expand_pipelines(module, pipeline_names) do
    pipelines = Module.get_attribute(module, :pipelines)

    pipeline_names
    |> Enum.map(&(pipelines[&1]))
  end
end

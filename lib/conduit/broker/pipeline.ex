defmodule Conduit.Broker.Pipeline do
  @moduledoc false
  import Conduit.Broker.Scope

  @type name :: atom
  @type plugs :: [Conduit.Plug.t()]
  @type t :: %__MODULE__{
          name: name,
          plugs: plugs
        }

  defstruct name: nil, plugs: []

  @doc """
  Initializes the pipeline scope.
  """
  @spec init(module) :: :ok
  def init(module) do
    Module.register_attribute(module, :pipelines, accumulate: true)
    put_scope(module, nil)
  end

  @doc """
  Starts a scope block.
  """
  @spec start_scope(module, name) :: :ok | no_return
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
  @spec end_scope(module) :: :ok
  def end_scope(module) do
    pipeline = get_scope(module)

    Module.put_attribute(module, :pipelines, pipeline)
    put_scope(module, nil)
  end

  @doc """
  Sets the pipelines for the scope.
  """
  @spec plug(module, Conduit.Plug.t()) :: :ok
  def plug(module, plug) do
    pipeline = get_scope(module)
    put_scope(module, %{pipeline | plugs: [plug | pipeline.plugs]})
  end

  def escape(%__MODULE__{} = pipeline) do
    quote(do: Conduit.Pipeline.new())
    |> put_elem(2, name: pipeline.name, plugs: pipeline.plugs)
  end

  def compile(pipeline) do
    Conduit.Plug.Builder.compile(pipeline.plugs, quote(do: next))
  end

  defmacro defpipelines do
    pipelines =
      __CALLER__.module
      |> Module.get_attribute(:pipelines)
      |> Enum.map(&escape/1)

    quote do
      def pipelines, do: unquote(pipelines)
    end
  end

  defmacro defpipeline do
    pipelines =
      for pipeline <- Module.get_attribute(__CALLER__.module, :pipelines),
          compiled_pipeline = compile(pipeline) do
        quote do
          def pipeline(message, next, unquote(pipeline.name)) do
            unquote(compiled_pipeline).(message)
          end
        end
      end

    fallback_pipeline =
      quote do
        def pipeline(_message, _next, pipeline) do
          message = """
          Undefined pipeline #{inspect(pipeline)}.

          Perhaps #{inspect(pipeline)} is misspelled. Otherwise, it can be defined in #{inspect(__MODULE__)} by adding:

              pipeline #{inspect(pipeline)} do
                # plugs ...
              end
          """

          raise Conduit.UndefinedPipelineError, message
        end
      end

    pipelines ++ [fallback_pipeline]
  end
end

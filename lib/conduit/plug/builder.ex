defmodule Conduit.Plug.Builder do
  @moduledoc """
  A module that can be used to build pipelines of plugs.

  ## Examples

      iex> import Conduit.Message
      iex>
      iex> defmodule MyPipeline do
      iex>   use Conduit.Plug.Builder
      iex>
      iex>   plug Conduit.Plug.Format
      iex>   plug Conduit.Plug.Encode
      iex> end
      iex>
      iex> message =
      iex>   %Conduit.Message{}
      iex>   |> put_body(%{})
      iex>   |> MyPipeline.call([])
      iex> message.body
      "{}"
      iex> get_meta(message, :content_type)
      "application/json"
      iex> get_meta(message, :content_encoding)
      "identity"
  """
  @type plug :: module | atom

  @doc false
  defmacro __using__(opts) do
    quote do
      @behaviour Conduit.Plug
      @plug_builder_opts unquote(opts)

      def init(opts) do
        opts
      end

      def call(message, opts) do
        plug_builder_call(message, opts)
      end

      defoverridable [init: 1, call: 2]

      import Conduit.Message
      import Conduit.Plug.Builder, only: [plug: 1, plug: 2]

      Module.register_attribute(__MODULE__, :plugs, accumulate: true)
      @before_compile Conduit.Plug.Builder
    end
  end

  @doc false
  defmacro __before_compile__(env) do
    plugs        = Module.get_attribute(env.module, :plugs)
    builder_opts = Module.get_attribute(env.module, :plug_builder_opts)

    {message, body} = Conduit.Plug.Builder.compile(env, plugs, builder_opts)

    quote do
      defp plug_builder_call(unquote(message), _), do: unquote(body)
    end
  end

  @doc """
  A macro that stores a new plug. `opts` will be passed unchanged to the new
  plug.

  This macro doesn't add any guards when adding the new plug to the pipeline;
  for more information about adding plugs with guards see `compile/1`.

  ## Examples

      plug Conduit.Plug.Format                  # plug module
      plug :put_meta, content_encoding: "gzip"  # plug function

  """
  defmacro plug(plug, opts \\ []) do
    quote do
      @plugs {unquote(plug), unquote(opts), true}
    end
  end

  @doc """
  Compiles a plug pipeline.

  Each element of the plug pipeline (according to the type signature of this
  function) has the form:

      {plug_name, options, guards}

  Note that this function expects a reversed pipeline (with the last plug that
  has to be called coming first in the pipeline).

  The function returns a tuple with the first element being a quoted reference
  to the connection and the second element being the compiled quoted pipeline.

  ## Examples

      Conduit.Plug.Builder.compile(env, [
        {Conduit.Plug.Format, [], true}, # no guards, as added by the Plug.Builder.plug/2 macro
        {Conduit.Plug.Encode, [], quote(do: a when is_binary(a))}
      ], [])

  """
  @spec compile(Macro.Env.t, [{plug, Plug.opts, Macro.t}], Keyword.t) :: {Macro.t, Macro.t}
  def compile(env, pipeline, builder_opts) do
    message = quote do: message
    {message, Enum.reduce(pipeline, message, &quote_plug(init_plug(&1), &2, env, builder_opts))}
  end

  # Initializes the options of a plug at compile time.
  defp init_plug({plug, opts, guards}) do
    case Atom.to_char_list(plug) do
      ~c"Elixir." ++ _ -> init_module_plug(plug, opts, guards)
      _                -> init_fun_plug(plug, opts, guards)
    end
  end

  defp init_module_plug(plug, opts, guards) do
    initialized_opts = plug.init(opts)

    if function_exported?(plug, :call, 2) do
      {:module, plug, initialized_opts, guards}
    else
      raise ArgumentError, message: "#{inspect plug} plug must implement call/2"
    end
  end

  defp init_fun_plug(plug, opts, guards) do
    {:function, plug, opts, guards}
  end

  # `acc` is a series of nested plug calls in the form of
  # plug3(plug2(plug1(message))). `quote_plug` wraps a new plug around that series
  # of calls.
  defp quote_plug({plug_type, plug, opts, guards}, acc, env, builder_opts) do
    call = quote_plug_call(plug_type, plug, opts)

    error_message = case plug_type do
      :module   -> "expected #{inspect plug}.call/2 to return a Conduit.Message"
      :function -> "expected #{plug}/2 to return a Conduit.Message"
    end <> ", all plugs must receive a message and return a message"

    {fun, meta, [arg, [do: clauses]]} =
      quote do
        case unquote(compile_guards(call, guards)) do
          %Conduit.Message{status: :nack} = message ->
            unquote(log_nack(plug_type, plug, env, builder_opts))
            message
          %Conduit.Message{} = message ->
            unquote(acc)
          _ ->
            raise unquote(error_message)
        end
      end

    generated? = :erlang.system_info(:otp_release) >= '19'

    clauses =
      Enum.map(clauses, fn {:->, meta, args} ->
        if generated? do
          {:->, [generated: true] ++ meta, args}
        else
          {:->, Keyword.put(meta, :line, -1), args}
        end
      end)

    {fun, meta, [arg, [do: clauses]]}
  end

  defp quote_plug_call(:function, plug, opts) do
    quote do: unquote(plug)(message, unquote(Macro.escape(opts)))
  end

  defp quote_plug_call(:module, plug, opts) do
    quote do: unquote(plug).call(message, unquote(Macro.escape(opts)))
  end

  defp compile_guards(call, true) do
    call
  end

  defp compile_guards(call, guards) do
    quote do
      case true do
        true when unquote(guards) -> unquote(call)
        true -> message
      end
    end
  end

  defp log_nack(plug_type, plug, env, builder_opts) do
    if level = builder_opts[:log_on_nack] do
      message = case plug_type do
        :module   -> "#{inspect env.module} nacked in #{inspect plug}.call/2"
        :function -> "#{inspect env.module} nacked in #{inspect plug}/2"
      end

      quote do
        require Logger
        # Matching, to make Dialyzer happy on code executing Conduit.Plug.Builder.compile/3
        _ = Logger.unquote(level)(unquote(message))
      end
    else
      nil
    end
  end
end

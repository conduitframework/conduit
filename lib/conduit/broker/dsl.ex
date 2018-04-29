defmodule Conduit.Broker.DSL do
  @moduledoc """
  Provides macros for setting up a message broker, subscribing to queues,
  publishing messages, and pipelines for processing messages.
  """

  alias Conduit.Broker.{DSL, IncomingScope, OutgoingScope, Pipeline, Topology}

  @doc false
  defmacro __using__(opts) do
    otp_app = Keyword.get(opts, :otp_app)
    module = __CALLER__.module

    Topology.init(module)
    Pipeline.init(module)
    IncomingScope.init(module)
    OutgoingScope.init(module)

    quote do
      @otp_app unquote(otp_app)
      import DSL
      @before_compile unquote(__MODULE__)
    end
  end

  @doc """
  Defines configuration of a message queue.
  """
  defmacro configure(do: block) do
    Topology.start_scope(__CALLER__.module)

    quote do
      unquote(block)

      Topology.end_scope(__MODULE__)
    end
  end

  defmacro queue(name, opts \\ []) do
    Topology.queue(__CALLER__.module, name, opts)
  end

  defmacro exchange(name, opts \\ []) do
    Topology.exchange(__CALLER__.module, name, opts)
  end

  @doc """
  Defines a message pipeline.
  """
  defmacro pipeline(name, do: block) do
    quote bind_quoted: [name: name], unquote: true do
      Pipeline.start_scope(__MODULE__, name)

      unquote(block)

      Pipeline.end_scope(__MODULE__)
    end
  end

  defmacro plug(plug, opts \\ [])

  defmacro plug(plug, {:&, _, _} = fun) do
    quote bind_quoted: [plug: plug, fun: Macro.escape(fun)] do
      Conduit.Broker.Pipeline.plug(__MODULE__, {plug, fun})
    end
  end

  defmacro plug(plug, {:fn, _, _} = fun) do
    quote bind_quoted: [plug: plug, fun: Macro.escape(fun)] do
      Conduit.Broker.Pipeline.plug(__MODULE__, {plug, fun})
    end
  end

  defmacro plug(plug, opts) do
    quote bind_quoted: [plug: plug, opts: opts] do
      Conduit.Broker.Pipeline.plug(__MODULE__, {plug, opts})
    end
  end

  @doc """
  Defines a grouped of subscribers who share the same pipelines.
  """
  defmacro incoming(namespace, do: block) do
    quote bind_quoted: [namespace: namespace], unquote: true do
      IncomingScope.start_scope(__MODULE__, unquote(namespace))

      unquote(block)

      IncomingScope.end_scope(__MODULE__)
    end
  end

  @doc """
  Defines a set of pipelines for the surrounding scope.
  """
  defmacro pipe_through(pipelines) do
    quote bind_quoted: [pipelines: List.wrap(pipelines)] do
      if @scope do
        @scope.__struct__.pipe_through(__MODULE__, pipelines)
      else
        raise "pipe_through can only be called in an incoming or outgoing block"
      end
    end
  end

  @doc """
  Defines a subscriber.
  """
  defmacro subscribe(name, subscriber, opts \\ []) do
    quote bind_quoted: [name: name, subscriber: subscriber, opts: opts] do
      IncomingScope.subscribe(__MODULE__, name, subscriber, opts)
    end
  end

  @doc """
  Defines a group of outgoing message publications that share a set of pipelines.
  """
  defmacro outgoing(do: block) do
    quote do
      OutgoingScope.start_scope(__MODULE__)

      unquote(block)

      OutgoingScope.end_scope(__MODULE__)
    end
  end

  @doc """
  Defines a publisher.
  """
  defmacro publish(name, opts \\ []) do
    quote bind_quoted: [name: name, opts: opts] do
      OutgoingScope.publish(__MODULE__, name, opts)
    end
  end

  @doc false
  defmacro __before_compile__(_) do
    quote do
      unquote(Topology.methods())
      unquote(IncomingScope.methods())
      unquote(OutgoingScope.methods())
    end
  end
end

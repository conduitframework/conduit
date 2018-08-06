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
  Defines the topology of a message broker

  You can use `Conduit.Broker.DSL.queue/2` and `Conduit.Broker.DSL.exchange/2` within a configure block.

  ## Examples

      configure do
        queue "my_app.created.account", durable: true
        queue "my_app.deleted.account", durable: true
      end
  """
  defmacro configure(do: block) do
    Topology.start_scope(__CALLER__.module)

    quote do
      unquote(block)

      Topology.end_scope(__MODULE__)
    end
  end

  @doc """
  Defines configuration of a queue

  *Note: the name of the queue may only allow specific characters depending upon the message broker you use.*

  ## Examples

      configure do
        queue "my_app.created.account", durable: true
        queue "my_app.deleted.account", durable: true
      end
  """
  defmacro queue(name, opts \\ []) do
    Topology.queue(__CALLER__.module, name, opts)
  end

  @doc """
  Defines configuration of an exchange

  ## Examples

      configure do
        exchange "my_app.topic", durable: true, type: :topic
        queue "my_app.deleted.account", durable: true, exchange: "my_app.topic"
      end
  """
  defmacro exchange(name, opts \\ []) do
    Topology.exchange(__CALLER__.module, name, opts)
  end

  @doc """
  Defines a message pipeline

  ## Examples

      pipeline :serialize do
        plug Conduit.Plug.Format, content_type: "application/json"
        plug Conduit.Plug.Encode, content_encoding: "gzip"
      end
  """
  defmacro pipeline(name, do: block) do
    quote bind_quoted: [name: name], unquote: true do
      Pipeline.start_scope(__MODULE__, name)

      unquote(block)

      Pipeline.end_scope(__MODULE__)
    end
  end

  @doc """
  Defines a plug as part of a pipeline

  ## Examples

      pipeline :serialize do
        plug Conduit.Plug.Format, content_type: "application/json"
        plug Conduit.Plug.Encode, content_encoding: "gzip"
      end
  """
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
  Defines a group of subscribers who share the same pipelines

  ## Examples

      incoming MyApp do
        pipe_through [:in_tracking, :deserialize]

        subscribe :account_created, AccountCreatedSubscriber, from: "my_app.created.account"
      end
  """
  defmacro incoming(namespace, do: block) do
    quote bind_quoted: [namespace: namespace], unquote: true do
      IncomingScope.start_scope(__MODULE__, unquote(namespace))

      unquote(block)

      IncomingScope.end_scope(__MODULE__)
    end
  end

  @doc """
  Defines a set of pipelines for the surrounding outgoing or incoming scope

  ## Examples

    outgoing do
      pipe_through [:out_tracking, :serialize]

      publish :account_created, to: "my_app.created.account"
    end

    incoming MyApp do
      pipe_through [:in_tracking, :deserialize]

      subscribe :account_created, AccountCreatedSubscriber, from: "my_app.created.account"
    end
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
  Defines a subscriber

  ## Examples

      incoming MyApp do
        subscribe :account_created, AccountCreatedSubscriber, from: "my_app.created.account"
      end
  """
  defmacro subscribe(name, subscriber, opts \\ []) do
    quote bind_quoted: [name: name, subscriber: subscriber, opts: opts] do
      IncomingScope.subscribe(__MODULE__, name, subscriber, opts)
    end
  end

  @doc """
  Defines a group of outgoing message publications that share a set of pipelines.

  ## Examples

      outgoing do
        pipe_through [:tracking, :serialize]

        publish :account_created, to: "my_app.created.account"
        publish :account_deleted, to: "my_app.deleted.account"
      end
  """
  defmacro outgoing(do: block) do
    quote do
      OutgoingScope.start_scope(__MODULE__)

      unquote(block)

      OutgoingScope.end_scope(__MODULE__)
    end
  end

  @doc """
  Defines a publisher

  ## Examples

      outgoing do
        publish :account_created, to: "my_app.created.account"
      end
  """
  defmacro publish(name, opts \\ []) do
    quote bind_quoted: [name: name, opts: opts] do
      OutgoingScope.publish(__MODULE__, name, opts)
    end
  end

  @doc false
  defmacro __before_compile__(env) do
    quote do
      import Conduit.Plug.MessageActions
      unquote(Topology.methods())
      unquote(IncomingScope.methods(env.module))
      unquote(OutgoingScope.methods(env.module))
    end
  end
end

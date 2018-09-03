defmodule Conduit.Broker.DSL do
  @moduledoc """
  Provides macros for setting up a message broker, subscribing to queues,
  publishing messages, and pipelines for processing messages.
  """

  alias Conduit.Broker.{DSL, IncomingScope, OutgoingScope, Pipeline, Scope, Topology}

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
    env = __CALLER__
    Topology.start_scope(env.module)
    Code.eval_quoted(block, [], env)
    Topology.end_scope(env.module)
    []
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
    env = __CALLER__
    Pipeline.start_scope(env.module, name)
    Code.eval_quoted(block, [], env)
    Pipeline.end_scope(env.module)
    []
  end

  @doc """
  Defines a plug as part of a pipeline

  ## Examples

      pipeline :serialize do
        plug Conduit.Plug.Format, content_type: "application/json"
        plug Conduit.Plug.Encode, content_encoding: "gzip"
      end
  """
  defmacro plug(plug, opts \\ []) do
    plug =
      plug
      |> Code.eval_quoted([], __CALLER__)
      |> elem(0)

    Conduit.Broker.Pipeline.plug(__CALLER__.module, {plug, opts})
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
    env = __CALLER__

    namespace =
      namespace
      |> Code.eval_quoted([], env)
      |> elem(0)

    IncomingScope.start_scope(env.module, namespace)
    Code.eval_quoted(block, [], env)
    IncomingScope.end_scope(env.module)
    []
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
    module = __CALLER__.module
    scope = Scope.get_scope(module)

    if scope do
      scope.__struct__.pipe_through(module, pipelines)
    else
      raise "pipe_through can only be called in an incoming or outgoing block"
    end

    []
  end

  @doc """
  Defines a subscriber

  ## Examples

      incoming MyApp do
        subscribe :account_created, AccountCreatedSubscriber, from: "my_app.created.account"
      end
  """
  defmacro subscribe(name, subscriber, opts \\ []) do
    subscriber =
      subscriber
      |> Code.eval_quoted()
      |> elem(0)

    IncomingScope.subscribe(__CALLER__.module, name, subscriber, opts)
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
    env = __CALLER__
    OutgoingScope.start_scope(env.module)
    Code.eval_quoted(block, [], env)
    OutgoingScope.end_scope(env.module)
    []
  end

  @doc """
  Defines a publisher

  ## Examples

      outgoing do
        publish :account_created, to: "my_app.created.account"
      end
  """
  defmacro publish(name, opts \\ []) do
    OutgoingScope.publish(__CALLER__.module, name, opts)
  end

  @doc false
  defmacro __before_compile__(env) do
    quote do
      import Conduit.Plug.MessageActions
      unquote(Topology.methods())
      unquote(Pipeline.methods())
      unquote(IncomingScope.methods(env.module))
      unquote(OutgoingScope.methods(env.module))
    end
  end
end

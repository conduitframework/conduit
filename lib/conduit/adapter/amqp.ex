defmodule Conduit.Adapter.AMQP do
  use Supervisor
  use AMQP
  require Logger

  @pool_size 5
  @conn_pool_name Module.concat(Conduit, ConnPool)
  @pub_pool_name Module.concat(Conduit, PubPool)

  @moduledoc """
  This code was adapted from pma/phoenix_pubsub_rabbitmq which can be found on
  GitHub.
    * `options` - The optional RabbitMQ options:
      * `host` - The hostname of the broker (defaults to \"localhost\");
      * `port` - The port the broker is listening on (defaults to `5672`);
      * `username` - The name of a user registered with the broker (defaults to \"guest\");
      * `password` - The password of user (defaults to \"guest\");
      * `virtual_host` - The name of a virtual host in the broker (defaults to \"/\");
      * `heartbeat` - The hearbeat interval in seconds (defaults to `0` - turned off);
      * `connection_timeout` - The connection timeout in milliseconds (defaults to `infinity`);
      * `pool_size` - Number of active connections to the broker
  """

  def start_link(opts \\ []) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(opts) do
    Logger.info("AMQP Adapter started!")

    conn_pool_opts = [
      name: {:local, @conn_pool_name},
      worker_module: Conduit.Conn,
      size: opts[:pool_size] || @pool_size,
      strategy: :fifo,
      max_overflow: 0
    ]

    pub_pool_opts = [
      name: {:local, @pub_pool_name},
      worker_module: Conduit.Pub,
      size: opts[:pool_size] || @pool_size,
      max_overflow: 0
    ]

    children = [
      :poolboy.child_spec(@conn_pool_name, conn_pool_opts, opts),
      :poolboy.child_spec(@pub_pool_name, pub_pool_opts, @conn_pool_name),
    ]

    supervise(children, strategy: :one_for_one)
  end

  def with_conn(fun) when is_function(fun, 1) do
    case get_conn(0, @pool_size) do
      {:ok, conn}      -> fun.(conn)
      {:error, reason} -> {:error, reason}
    end
  end

  defp get_conn(retry_count, max_retry_count) do
    case :poolboy.transaction(@conn_pool_name, &GenServer.call(&1, :conn)) do
      {:ok, conn}      -> {:ok, conn}
      {:error, _reason} when retry_count < max_retry_count ->
        get_conn(retry_count + 1, max_retry_count)
      {:error, reason} -> {:error, reason}
    end
  end

  def publish(exchange, routing_key, payload, options \\ []) do
    case get_chan(0, @pool_size) do
      {:ok, chan} ->
        Basic.publish(chan, exchange, routing_key, payload, options)
      {:error, reason} ->
        {:error, reason}
    end
  end

  defp get_chan(retry_count, max_retry_count) do
    case :poolboy.transaction(@pub_pool_name, &GenServer.call(&1, :chan)) do
      {:ok, chan} ->
        {:ok, chan}
      {:error, _reason} when retry_count < max_retry_count ->
        get_chan(retry_count + 1, max_retry_count)
      {:error, reason} ->
        {:error, reason}
    end
  end
end

defmodule Conduit.Pub do
  use GenServer
  use AMQP

  @reconnect_after_ms 5_000

  @moduledoc """
  Worker for pooled publishers to RabbitMQ
  """

  @doc """
  Starts the server
  """
  def start_link(conn_pool_name) do
    GenServer.start_link(__MODULE__, [conn_pool_name])
  end

  @doc false
  def init([conn_pool_name]) do
    Process.flag(:trap_exit, true)
    send(self, :connect)
    {:ok, %{status: :disconnected, chan: nil, conn_pool_name: conn_pool_name}}
  end

  def handle_call(:chan, _from, %{status: :connected, chan: chan} = status) do
    {:reply, {:ok, chan}, status}
  end

  def handle_call(:chan, _from, %{status: :disconnected} = status) do
    {:reply, {:error, :disconnected}, status}
  end

  def handle_info(:connect, %{status: :disconnected} = state) do
    case Conduit.with_conn(&Channel.open/1) do
      {:ok, chan} ->
        Process.monitor(chan.pid)
        {:noreply, %{state | chan: chan, status: :connected}}
      _ ->
        Process.send_after(self, @reconnect_after_ms, :connect)
        {:noreply, %{state | chan: nil, status: :disconnected}}
    end
  end

  def handle_info({:DOWN, _ref, :process, _pid, _reason}, state) do
    Process.send_after(self, @reconnect_after_ms, :connect)
    {:noreply, %{state | status: :disconnected}}
  end

  def terminate(_reason, %{chan: chan, status: :connected}) do
    try do
      Channel.close(chan)
    catch
      _, _ -> :ok
    end
  end
  def terminate(_reason, _state) do
    :ok
  end
end

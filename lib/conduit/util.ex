defmodule Conduit.Util do
  @moduledoc """
  Provides utilities to wait for something to happen
  """

  @type attempt_function :: (() -> {:error, term} | term | no_return) | (integer() -> {:error, term} | term | no_return)

  @doc """
  Runs a function until it returns a truthy value.

  A timeout can optionally be specified to limit how long a function is attempted.

  ## Examples

      Conduit.Util.wait_until(fn ->
        table
        |> :ets.lookup(:thing)
        |> List.first()
      end)

      Conduit.Util.wait_until(30_000, fn ->
        table
        |> :ets.lookup(:thing)
        |> List.first()
      end)
  """
  @spec wait_until(timeout :: integer() | :infinity, attempt_function) :: :ok | {:error, term}
  def wait_until(timeout \\ :infinity, fun) when is_function(fun) do
    attempts = if(is_number(timeout), do: div(timeout, 10), else: timeout)

    retry([backoff_factor: 1, attempts: attempts], fn delay ->
      fun
      |> is_function(0)
      |> if(do: fun.(), else: fun.(delay))
      |> case do
        falsey when falsey in [nil, false] -> {:error, :timeout}
        _ -> :ok
      end
    end)
  end

  @doc """
  Attempts to run a function and retry's if it fails.

  Allows the following options:

  ## Options

    * `attempts` - Number of times to run the function before giving up. (defaults to 3)
    * `backoff_factor` - What multiple of the delay should be backoff on each attempt. For
      a backoff of 2, on each retry we double the amount of time of the last delay. Set to
      1 to use the same delay each retry.
      (defaults to 2)
    * `jitter` - Size of randomness applied to delay. This is useful to prevent multiple
      processes from retrying at the same time. (defaults to 0)
    * `delay` - How long to wait between attempts. (defaults to 1000ms)

  ## Examples

      Conduit.Util.retry(fn ->
        # thing that sometimes fails
      end)

      Conduit.Util.retry([attempts: 20, delay: 100], fn ->
        # thing that sometimes fails
      end)
  """
  @default_retry_opts %{
    delay: 10,
    backoff_factor: 2,
    jitter: 0,
    max_delay: 1_000,
    attempts: 3
  }
  @spec retry(opts :: Keyword.t(), attempt_function) :: term
  def retry(opts \\ [], fun) when is_function(fun) do
    opts = Map.merge(@default_retry_opts, Map.new(opts))

    sequence()
    |> delay(opts.delay, opts.backoff_factor)
    |> jitter(opts.jitter)
    |> max_delay(opts.max_delay)
    |> limit(opts.attempts)
    |> attempt(fun)
  end

  defp sequence do
    Stream.iterate(0, &Kernel.+(&1, 1))
  end

  defp delay(stream, delay, backoff_factor) do
    Stream.map(stream, fn
      0 -> 0
      retries -> delay * :math.pow(backoff_factor, retries)
    end)
  end

  defp jitter(stream, jitter) do
    Stream.map(stream, &round(:rand.uniform() * &1 * jitter + &1))
  end

  defp max_delay(stream, max_delay) do
    Stream.map(stream, &min(&1, max_delay))
  end

  defp limit(stream, :infinity), do: stream

  defp limit(stream, attempts) do
    Stream.take(stream, attempts)
  end

  defp attempt(stream, fun) do
    Enum.reduce_while(stream, nil, fn
      0, _ ->
        do_attempt(fun, 0)

      delay, _ ->
        Process.sleep(delay)
        do_attempt(fun, delay)
    end)
  end

  defp do_attempt(fun, delay) do
    fun
    |> is_function(0)
    |> if(do: fun.(), else: fun.(delay))
    |> case do
      {:error, reason} ->
        {:cont, {:error, reason}}

      result ->
        {:halt, result}
    end
  catch
    :error, reason ->
      {:cont, {:error, reason}}
  end
end

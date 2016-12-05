defmodule Conduit.Plug.Retry do
  use Conduit.Plug.Builder
  @moduledoc """
  Retries messages that were nacked or raised an exception.

  ## Options

    * `attempts` - Number of times to process the message before giving up. (defaults to 3)
    * `backoff_factor` - What multiple of the delay should be backoff on each attempt. For
      a backoff of 2, on each retry we double the amount of time of the last delay. Set to
      1 to use the same delay each retry.
      (defaults to 2)
    * `jitter` - Size of randomness applied to delay. This is useful to prevent multiple
      processes from retrying at the same time. (defaults to 0)
    * `delay` - How long to wait between attempts. (defaults to 1000ms)

  ## Examples

      plug Retry
      plug Retry, attempts: 10, delay: 10_000

  """

  @defaults %{
    attempts: 3,
    backoff_factor: 2,
    jitter: 0,
    delay: 1000
  }
  def init(opts) do
    Map.merge(@defaults, Enum.into(opts, %{}))
  end

  def call(message, next, opts) do
    attempt(message, next, 0, opts)
  end

  defp attempt(message, next, retries, opts) do
    message = next.(message)

    case message.status do
      :nack -> retry(message, next, retries, nil, opts)
      :ack -> message
    end
  rescue error ->
    retry(message, next, retries, error, opts)
  end

  defp retry(message, _, retries, nil, %{attempts: attempts})
  when retries >= attempts - 1 do
    nack(message)
  end
  defp retry(_, _, retries, error, %{attempts: attempts})
  when retries >= attempts - 1 do
    reraise error, System.stacktrace
  end
  defp retry(message, next, retries, _, opts) do
    delay = opts.delay * :math.pow(opts.backoff_factor, retries)
    jitter = :rand.uniform * delay * opts.jitter

    Process.sleep(round(delay + jitter))

    message
    |> put_header("retries", retries + 1)
    |> ack
    |> attempt(next, retries + 1, opts)
  end
end

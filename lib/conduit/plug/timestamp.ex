defmodule Conduit.Plug.Timestamp do
  use Conduit.Plug.Builder
  @moduledoc """
  Assigns a timestamp to meta.

  A format can be specified. The default is `"{ISO:Extended:Z}"`. The format
  can be anything that `Timex.format/1` accepts. See
  [here](https://hexdocs.pm/timex/formatting.html).

  `:unix_epoch` may also be passed, which will
  set the timestamp to seconds since the UNIX epoch.

      plug Conduit.Plug.Timestamp
      plug Conduit.Plug.Timestamp, format: "{YYYY}-{M}-{D}"
      plug Conduit.Plug.Timestamp, format: :unix_epoch

  """

  def init(opts) do
    Keyword.get(opts, :format, "{ISO:Extended:Z}")
  end

  @doc """
  Assigns a ISO8601 timestamp to meta.

  ## Examples

      iex> message = %Conduit.Message{}
      iex> message = Conduit.Plug.Timestamp.call(message, "{ISO:Extended:Z}")
      iex> # e.g. "2016-11-16T03:00:24.575904Z"
      iex> {:ok, %DateTime{}} = Timex.parse(message.meta.timestamp, "{ISO:Extended:Z}")
      iex> message = %Conduit.Message{}
      iex> message = Conduit.Plug.Timestamp.call(message, :unix_epoch)
      iex> # e.g. 1479265596
      iex> is_integer(message.meta.timestamp)
      true
  """
  @spec call(Conduit.Message.t, binary | atom) :: Conduit.Message.t
  def call(message, format) do
    message
    |> put_meta(:timestamp, timestamp(format))
  end

  defp timestamp(:unix_epoch), do: Timex.to_unix(Timex.now)
  defp timestamp(format), do: Timex.format!(Timex.now, format)
end

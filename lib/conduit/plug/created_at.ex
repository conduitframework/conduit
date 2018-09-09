defmodule Conduit.Plug.CreatedAt do
  use Conduit.Plug.Builder

  @moduledoc """
  Assigns a created_at date to the message.

  ## Options

    * `:format` - A format can be specified. The default is `"{ISO:Extended:Z}"`. The format can be anything that
      `Timex.format/1` accepts. See [here](https://hexdocs.pm/timex/formatting.html). `:unix_epoch` may also be passed,
      which will set the timestamp to seconds since the UNIX epoch.

  ## Examples

      iex> defmodule MyPipeline do
      iex>   use Conduit.Plug.Builder
      iex>   plug Conduit.Plug.CreatedAt
      iex>   # plug Conduit.Plug.CreatedAt, format: "{YYYY}-{M}-{D}"
      iex> end
      iex> message = MyPipeline.run(%Conduit.Message{})
      iex> message.created_at # e.g. "2016-11-16T03:00:24.575904Z"
      iex> %DateTime{} = Timex.parse!(message.created_at, "{ISO:Extended:Z}")
      iex> is_binary(message.created_at)
      true

      iex> defmodule MyOtherPipeline do
      iex>   use Conduit.Plug.Builder
      iex>   plug Conduit.Plug.CreatedAt, format: :unix_epoch
      iex> end
      iex> message = MyOtherPipeline.run(%Conduit.Message{})
      iex> message.created_at # e.g. 1479265596
      iex> is_integer(message.created_at)
      true

  """

  @doc """
  Assigns a ISO8601 timestamp to the message.
  """
  def call(message, next, opts) do
    format = Keyword.get(opts, :format, "{ISO:Extended:Z}")

    message
    |> put_created_at(created_at(format))
    |> next.()
  end

  defp created_at(:unix_epoch), do: Timex.to_unix(Timex.now())
  defp created_at(format), do: Timex.format!(Timex.now(), format)
end

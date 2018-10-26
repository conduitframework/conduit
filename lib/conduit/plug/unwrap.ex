defmodule Conduit.Plug.Unwrap do
  @moduledoc """
  Plug to help unwrap headers and fields from the message body

  This can be helpful if your broker doesn't support message headers natively.

  By default this plug expects the body to be a map containing 3 string keys:

  * `"headers"` - will be put into the message headers
  * `"fields" - will be put into the messages fields (i.e. `:message_id`, `:correlation_id`, etc.)
  * `"body"` - will replace the current wrapper body

  If you want a different wrapping structure for the message, you can pass the the
  `:unwrap_fn` option. The wrap function should accept a message and return a message.

  ## Examples

      iex> alias Conduit.Message
      iex> defmodule MyPipeline do
      iex>   use Conduit.Plug.Builder
      iex>   plug Conduit.Plug.Unwrap
      iex> end
      iex>
      iex> message =
      iex>   %Message{}
      iex>   |> Message.put_body(%{
      iex>     "body" => %{},
      iex>     "headers" => %{"foo" => "bar"},
      iex>     "fields" => %{"correlation_id" => "1"}
      iex>   })
      iex>   |> MyPipeline.run()
      iex> message.body
      %{}
      iex> Message.get_header(message, "foo")
      "bar"
      iex> message.correlation_id
      "1"

  """
  use Conduit.Plug.Builder

  require Logger

  @doc """
  Extracts the headers and fields from the wrapped body of the message
  """
  def call(message, next, opts) do
    unwrap_fn = Keyword.get(opts, :unwrap_fn, &default_unwrap/1)

    message
    |> unwrap_fn.()
    |> next.()
  end

  defp default_unwrap(message) do
    %{"fields" => fields, "headers" => headers, "body" => body} = message.body

    message
    # Merge here because lower down code is putting in a routing key, and source
    |> put_headers(Map.merge(message.headers, headers))
    |> put_body(body)
    |> put_content_encoding(fields["content_encoding"])
    |> put_content_type(fields["content_type"])
    |> put_correlation_id(fields["correlation_id"])
    |> put_created_at(fields["created_at"])
    |> put_created_by(fields["created_by"])
    |> put_message_id(fields["message_id"])
    |> put_user_id(fields["user_id"])
  end
end

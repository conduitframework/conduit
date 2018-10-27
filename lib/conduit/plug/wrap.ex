defmodule Conduit.Plug.Wrap do
  @moduledoc """
  Plug to help wrap headers and fields into the message body

  This can be helpful if your broker doesn't support message headers natively.

  By default this plug will update the body of the message to:

      %{
        "headers" => message.headers,
        "fields" => %{}, # message_id, correlation_id, etc.
        "body" => message.body
      }

  If you want a different wrapping structure for the message, you can pass the the
  `:wrap_fn` option. The wrap function should accept a message, the fields, the headers,
  and body. The return value should be a message.

  ## Examples

      iex> alias Conduit.Message
      iex> defmodule MyPipeline do
      iex>   use Conduit.Plug.Builder
      iex>   plug Conduit.Plug.Wrap
      iex> end
      iex>
      iex> message =
      iex>   %Message{}
      iex>   |> Message.put_correlation_id("1")
      iex>   |> Message.put_header("foo", "bar")
      iex>   |> Message.put_body(%{})
      iex>   |> MyPipeline.run()
      iex> message.body
      %{
        "headers" => %{
          "foo" => "bar"
        },
        "fields" => %{
          "correlation_id" => "1"
        },
        "body" => %{}
      }

      iex> alias Conduit.Message
      iex> defmodule MyOtherPipeline do
      iex>   use Conduit.Plug.Builder
      iex>   plug Conduit.Plug.Wrap, wrap_fn: fn message, fields, headers, body ->
      iex>     body =
      iex>       body
      iex>       |> Map.put("meta", fields)
      iex>       |> put_in(["meta", "headers"], headers)
      iex>
      iex>     Conduit.Message.put_body(message, body)
      iex>   end
      iex> end
      iex>
      iex> message =
      iex>   %Message{}
      iex>   |> Message.put_correlation_id("1")
      iex>   |> Message.put_header("foo", "bar")
      iex>   |> Message.put_body(%{})
      iex>   |> MyOtherPipeline.run()
      iex> message.body
      %{
        "meta" => %{
          "correlation_id" => "1",
          "headers" => %{
            "foo" => "bar"
          },
        }
      }
  """
  use Conduit.Plug.Builder

  @doc """
  Puts headers and fields into the body of the message
  """
  def call(%Message{headers: headers, body: body} = message, next, opts) do
    wrap_fn = Keyword.get(opts, :wrap_fn, &default_wrap/4)

    fields =
      message
      |> get_fields()
      |> Map.new(fn {key, value} -> {to_string(key), value} end)

    message
    |> wrap_fn.(fields, headers, body)
    |> Message.put_private(:wrapped, true)
    |> next.()
  end

  defp default_wrap(message, fields, headers, body) do
    put_body(message, %{"fields" => fields, "headers" => headers, "body" => body})
  end
end

defmodule Conduit.Plug.Format do
  use Conduit.Plug.Builder
  @moduledoc """
  Formats the message body based on the content type.

  It uses in order of preference:

    1. The content type specified for the plug.
    2. The content type specified on the message.
    3. The default content type `text/plain`.

  This plug should be used in an outgoing pipeline.

  ## Examples

      plug Conduit.Plug.Format
      plug Conduit.Plug.Format, content_type: "application/json"

      iex> import Conduit.Message
      iex> message =
      iex>   %Conduit.Message{}
      iex>   |> put_body(%{})
      iex>   |> Conduit.Plug.Format.run(content_type: "application/json")
      iex> message.body
      "{}"
      iex> message.content_type
      "application/json"

  """

  @doc """
  Formats the message body based on the content type.
  """
  @default_content_type "text/plain"
  def call(message, next, opts) do
    content_type =
      Keyword.get(opts, :content_type)
      || Map.get(message, :content_type)
      || @default_content_type

    message
    |> Conduit.ContentType.format(content_type, opts)
    |> next.()
  end
end

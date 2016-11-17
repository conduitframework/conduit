defmodule Conduit.Plug.Format do
  use Conduit.Plug.Builder
  @moduledoc """
  Formats the message body based on the content type.

  It uses in order of preference:

    1. The content type specified for the plug.
    2. The content type specified on the message.
    3. The default content type `application/json`.

  This plug should be used in an outgoing pipeline.

      plug Conduit.Plug.Format
      plug Conduit.Plug.Format, content_type: "application/xml"

  """

  @doc """
  Formats the message body based on the content type.

  ## Examples

      iex> import Conduit.Message
      iex> message =
      iex>   %Conduit.Message{}
      iex>   |> put_body(%{})
      iex>   |> Conduit.Plug.Format.call([])
      iex> message.body
      "{}"
      iex> get_meta(message, :content_type)
      "application/json"
  """
  @default_content_type "application/json"
  def call(message, opts) do
    content_type =
      Keyword.get(opts, :content_type)
      || get_meta(message, :content_type)
      || @default_content_type

    Conduit.ContentType.format(message, content_type, opts)
  end
end

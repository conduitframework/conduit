defmodule Conduit.Encoding do
  @moduledoc """
  Encodes and decodes a message body based on the content encoding given.

  Custom content encodings can be specified in your configuration.

      config :conduit, Conduit.Encoding, [{"custom", MyApp.CustomEncoding}]

  Note that any new content encodings specified in this way will require a recompile of Conduit.

      $ mix deps.clean conduit --build
      $ mix deps.get

  Any custom content encodings should implement the `Conduit.ContentType`
  behaviour. See `Conduit.Encoding.GZip` for an example.

  """
  @callback encode(Conduit.Message.t(), Keyword.t()) :: Conduit.Message.t()
  @callback decode(Conduit.Message.t(), Keyword.t()) :: Conduit.Message.t()

  @default_content_encodings [
    {"gzip", Conduit.Encoding.GZip},
    {"identity", Conduit.Encoding.Identity}
  ]

  @doc false
  defmacro __using__(_opts) do
    quote do
      @behaviour Conduit.Encoding
      import Conduit.Message
    end
  end

  @doc """
  Encodes the message body with the specified content encoding.

  ## Examples

      iex> import Conduit.Message
      iex> message =
      iex>   %Conduit.Message{}
      iex>   |> put_body("{}")
      iex>   |> Conduit.Encoding.encode("gzip", [])
      iex> :zlib.gunzip(message.body)
      "{}"

  """
  @spec encode(Conduit.Message.t(), String.t(), Keyword.t()) :: Conduit.Message.t()
  def encode(message, encoding, opts) do
    content_encoding(encoding).encode(message, opts)
  end

  @doc """
  Decodes the message body with the specified content encoding.

  ## Examples

      iex> import Conduit.Message
      iex> body = <<31, 139, 8, 0, 0, 0, 0, 0, 0, 3, 171, 174, 5, 0, 67, 191, 166, 163, 2, 0, 0, 0>>
      iex> message =
      iex>   %Conduit.Message{}
      iex>   |> put_body(body)
      iex>   |> Conduit.Encoding.decode("gzip", [])
      iex> message.body
      "{}"

  """
  @spec decode(Conduit.Message.t(), String.t(), Keyword.t()) :: Conduit.Message.t()
  def decode(message, encoding, opts) do
    content_encoding(encoding).decode(message, opts)
  end

  @spec content_encoding(String.t()) :: module
  config_content_encodings = Application.get_env(:conduit, Conduit.Encoding, [])
  encodings = config_content_encodings ++ @default_content_encodings

  for {encoding, content_encoding} <- encodings do
    defp content_encoding(unquote(encoding)), do: unquote(content_encoding)
  end

  defp content_encoding(content_encoding) do
    raise Conduit.UnknownEncodingError, "Unknown encoding #{inspect(content_encoding)}"
  end
end

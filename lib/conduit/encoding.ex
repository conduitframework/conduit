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
  @type body :: term

  @callback encode(body, Keyword.t) :: body
  @callback decode(body, Keyword.t) :: body

  @default_content_encodings [
    {"gzip", Conduit.Encoding.GZip},
    {"identity", Conduit.Encoding.Identity}
  ]

  @doc """
  Defines as implementing the `Conduit.Encoding` behavior and imports `Conduit.Message`.
  """
  defmacro __using__(_opts) do
    quote do
      @behaviour Conduit.Encoding
      import Conduit.Message
    end
  end

  @doc """
  Encodes the message body with the specified content encoding.

  ## Examples

      iex> body = Conduit.Encoding.encode("{}", "gzip", [])
      iex> :zlib.gunzip(body)
      "{}"

  """
  @spec encode(body, String.t, Keyword.t) :: body
  def encode(body, encoding, opts) do
    content_encoding(encoding).encode(body, opts)
  end

  @doc """
  Decodes the message body with the specified content encoding.

  ## Examples

      iex> body = <<31, 139, 8, 0, 0, 0, 0, 0, 0, 3, 171, 174, 5, 0, 67, 191, 166, 163, 2, 0, 0, 0>>
      iex> Conduit.Encoding.decode(body, "gzip", [])
      "{}"

  """
  @spec decode(body, String.t, Keyword.t) :: body
  def decode(body, encoding, opts) do
    content_encoding(encoding).decode(body, opts)
  end

  @spec content_encoding(String.t) :: module
  config_content_encodings = Application.get_env(:conduit, Conduit.Encoding, [])
  encodings = config_content_encodings ++ @default_content_encodings
  for {encoding, content_encoding} <- encodings do
    defp content_encoding(unquote(encoding)), do: unquote(content_encoding)
  end

  defp content_encoding(content_encoding) do
    raise Conduit.UnknownEncodingError, "Unknown encoding #{inspect content_encoding}"
  end
end

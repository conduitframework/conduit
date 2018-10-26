defmodule Conduit.Message do
  @moduledoc """
  The Conduit message.

  This module defines a `Conduit.Message` struct and the main functions
  for working with Conduit messages.

  Note this struct is used for sending and receiving messages from a
  message queue.

  ## Public fields

  These fields are for you to use in your application. The values in
  `user_id`, `correlation_id`, `message_id`, `content_type`,
  `content_encoding`, `created_by`, `created_at`, `headers`, and
  `status` may have special meaning based on the adapter you use.
  See your adapters documention to understand how to use them correctly.

    * `source` - For incoming messages, this will be set to the queue the message was
      consumed from.
    * `destination` - For outgoing messages, this will be set to the destination queue (or
      routing key) it is published to.
    * `user_id` - An ID representing which user the message pertains to.
    * `correlation_id` - An ID for a chain of messages, where the current message is one in
      that chain.
    * `message_id` - A unique ID for this message.
    * `content_type` - The media type of the message body.
    * `content_encoding` - The encoding of the message body.
    * `created_by` - The name of the app that created the message.
    * `created_at` - A timestamp or epoch representing when the message was created.
    * `headers` - Information applicable to a specific message stored as a keyword list.
    * `body` - The contents of the message.
    * `status` - The operation to perform on the message. This only applies to messages
      that are being received.

  ## Private fields

  These fields are reserved for library/framework usage.

    * `private` - shared library data as a map
  """

  @type source :: binary | fun | nil
  @type destination :: binary | fun | nil
  @type user_id :: binary | integer | fun | nil
  @type correlation_id :: binary | integer | fun | nil
  @type message_id :: binary | integer | fun | nil
  @type content_type :: String.t() | fun | nil
  @type content_encoding :: String.t() | fun | nil
  @type created_by :: binary | fun | nil
  @type created_at :: String.t() | integer | fun | nil
  @type headers :: %{String.t() => any}
  @type body :: any
  @type status :: :ack | :nack
  @type assigns :: %{atom => any}
  @type private :: %{atom => any}

  @type t :: %__MODULE__{
          source: source,
          destination: destination,
          user_id: user_id,
          correlation_id: correlation_id,
          message_id: message_id,
          content_type: content_type,
          content_encoding: content_encoding,
          created_by: created_by,
          created_at: created_at,
          headers: headers,
          body: body,
          status: status,
          assigns: assigns,
          private: private
        }
  defstruct source: nil,
            destination: nil,
            user_id: nil,
            correlation_id: nil,
            message_id: nil,
            content_type: nil,
            content_encoding: nil,
            created_by: nil,
            created_at: nil,
            headers: %{},
            body: nil,
            status: :ack,
            assigns: %{},
            private: %{}

  @doc """
  Creates a new message with the fields and headers specified.

  ## Examples

      iex> import Conduit.Message
      iex> old_message =
      iex>   %Conduit.Message{}
      iex>   |> put_correlation_id("123")
      iex>   |> put_header("retries", 1)
      iex> new_message = Conduit.Message.take(old_message,
      iex>   headers: ["retries"], fields: [:correlation_id])
      iex> new_message.correlation_id
      "123"
      iex> get_header(new_message, "retries")
      1

  """
  @spec take(from :: __MODULE__.t(), opts :: [fields: [atom], headers: [String.t()]]) :: __MODULE__.t()
  def take(from, opts) do
    %__MODULE__{}
    |> merge_fields(from, Keyword.get(opts, :fields, []))
    |> merge_headers(from, Keyword.get(opts, :headers, []))
  end

  @allowed_fields [
    :source,
    :destination,
    :user_id,
    :correlation_id,
    :message_id,
    :content_type,
    :content_encoding,
    :created_by,
    :created_at,
    :status
  ]
  @doc """
  Merges fields to one message from another.

  ## Examples

      iex> import Conduit.Message
      iex> old_message = put_correlation_id(%Conduit.Message{}, "123")
      iex> new_message = Conduit.Message.merge_fields(%Conduit.Message{}, old_message)
      iex> new_message.correlation_id
      "123"
      iex> new_message = Conduit.Message.merge_fields(%Conduit.Message{}, old_message, [:correlation_id])
      iex> new_message.correlation_id
      "123"

  """
  @spec merge_fields(to :: __MODULE__.t(), from :: __MODULE__.t(), fields :: [atom]) :: __MODULE__.t()
  def merge_fields(%__MODULE__{} = to, %__MODULE__{} = from, fields \\ @allowed_fields) do
    fields =
      MapSet.intersection(
        MapSet.new(@allowed_fields),
        MapSet.new(fields)
      )

    Map.merge(to, Map.take(from, fields))
  end

  @doc """
  Merges headers to one message from another.

  ## Examples

      iex> import Conduit.Message
      iex> old_message = put_header(%Conduit.Message{}, "retries", 1)
      iex> new_message = Conduit.Message.merge_headers(%Conduit.Message{}, old_message, ["retries"])
      iex> get_header(new_message, "retries")
      1
  """
  @spec merge_headers(to :: __MODULE__.t(), from :: __MODULE__.t(), headers :: [String.t()]) :: __MODULE__.t()
  def merge_headers(%__MODULE__{} = to, %__MODULE__{} = from, headers) do
    headers = Map.take(from.headers, headers)

    %{to | headers: Map.merge(to.headers, headers)}
  end

  @doc """
  Assigns the source of the message.

  ## Examples

      iex> import Conduit.Message
      iex> message =
      iex>   %Conduit.Message{}
      iex>   |> put_source("my.queue")
      iex>   |> put_header("routing_key", "my.routing_key")
      iex> message.source
      "my.queue"
      iex> message = put_source(message, fn mess ->
      iex>   get_header(mess, "routing_key")
      iex> end)
      iex> message.source
      "my.routing_key"

  """
  @spec put_source(__MODULE__.t(), source) :: __MODULE__.t()
  def put_source(%__MODULE__{} = message, source) when is_function(source) do
    put_source(message, call_fun(source, message))
  end

  def put_source(%__MODULE__{} = message, source) do
    %{message | source: source}
  end

  @doc """
  Assigns a source to the message when one isn't set already.

  ## Examples

      iex> import Conduit.Message
      iex> message = put_new_source(%Conduit.Message{}, "my.queue")
      iex> message = put_new_source(message, "your.queue")
      iex> message.source
      "my.queue"
      iex> message = put_new_source(%Conduit.Message{}, fn _mess -> "my.queue" end)
      iex> message = put_new_source(message, fn _mess -> "your.queue" end)
      iex> message.source
      "my.queue"

  """
  @spec put_new_source(__MODULE__.t(), source) :: __MODULE__.t()
  def put_new_source(%__MODULE__{source: nil} = message, source) do
    put_source(message, source)
  end

  def put_new_source(%__MODULE__{} = message, _) do
    message
  end

  @doc """
  Assigns the destination of the message.

  ## Examples

      iex> import Conduit.Message
      iex> message =
      iex>   %Conduit.Message{}
      iex>   |> put_source("over.there")
      iex>   |> put_destination("my.queue")
      iex> message.destination
      "my.queue"
      iex> message = put_destination(message, fn mess -> mess.source <> ".error" end)
      iex> message.destination
      "over.there.error"

  """
  @spec put_destination(__MODULE__.t(), destination) :: __MODULE__.t()
  def put_destination(%__MODULE__{} = message, destination) when is_function(destination) do
    put_destination(message, call_fun(destination, message))
  end

  def put_destination(%__MODULE__{} = message, destination) do
    %{message | destination: destination}
  end

  @doc """
  Assigns a destination to the message when one isn't set already.

  ## Examples

      iex> import Conduit.Message
      iex> message = put_new_destination(%Conduit.Message{}, "your.queue")
      iex> message = put_new_destination(message, "my.queue")
      iex> message.destination
      "your.queue"
      iex> message = put_new_destination(%Conduit.Message{}, fn _mess -> "your.queue" end)
      iex> message = put_new_destination(message, fn _mess -> "my.queue" end)
      iex> message.destination
      "your.queue"

  """
  @spec put_new_destination(__MODULE__.t(), destination) :: __MODULE__.t()
  def put_new_destination(%__MODULE__{destination: nil} = message, destination) do
    put_destination(message, destination)
  end

  def put_new_destination(%__MODULE__{} = message, _) do
    message
  end

  @doc """
  Assigns a user_id to the message.

  ## Examples

      iex> import Conduit.Message
      iex> message = put_user_id(%Conduit.Message{}, 1)
      iex> message.user_id
      1
      iex> message = put_user_id(message, fn _mess -> 2 end)
      iex> message.user_id
      2

  """
  @spec put_user_id(__MODULE__.t(), user_id) :: __MODULE__.t()
  def put_user_id(%__MODULE__{} = message, user_id) when is_function(user_id) do
    put_user_id(message, call_fun(user_id, message))
  end

  def put_user_id(%__MODULE__{} = message, user_id) do
    %{message | user_id: user_id}
  end

  @doc """
  Assigns a correlation_id to the message.

  ## Examples

      iex> import Conduit.Message
      iex> message = put_correlation_id(%Conduit.Message{}, 1)
      iex> message.correlation_id
      1
      iex> message = put_correlation_id(message, fn _mess -> 2 end)
      iex> message.correlation_id
      2

  """
  @spec put_correlation_id(__MODULE__.t(), correlation_id) :: __MODULE__.t()
  def put_correlation_id(%__MODULE__{} = message, correlation_id)
      when is_function(correlation_id) do
    put_correlation_id(message, call_fun(correlation_id, message))
  end

  def put_correlation_id(%__MODULE__{} = message, correlation_id) do
    %{message | correlation_id: correlation_id}
  end

  @doc """
  Assigns a correlation_id to the message when one isn't set already.

  ## Examples

      iex> import Conduit.Message
      iex> message = put_new_correlation_id(%Conduit.Message{}, 1)
      iex> message = put_new_correlation_id(message, 2)
      iex> message.correlation_id
      1
      iex> message = put_new_correlation_id(%Conduit.Message{}, fn _mess -> 1 end)
      iex> message = put_new_correlation_id(message, fn _mess -> 2 end)
      iex> message.correlation_id
      1

  """
  @spec put_new_correlation_id(__MODULE__.t(), correlation_id) :: __MODULE__.t()
  def put_new_correlation_id(%__MODULE__{correlation_id: nil} = message, correlation_id) do
    put_correlation_id(message, correlation_id)
  end

  def put_new_correlation_id(%__MODULE__{} = message, _) do
    message
  end

  @doc """
  Assigns a message_id to the message.

  ## Examples

      iex> import Conduit.Message
      iex> message = put_message_id(%Conduit.Message{}, 1)
      iex> message.message_id
      1
      iex> message = put_message_id(%Conduit.Message{}, fn _mess -> 1 end)
      iex> message.message_id
      1
  """
  @spec put_message_id(__MODULE__.t(), message_id) :: __MODULE__.t()
  def put_message_id(%__MODULE__{} = message, message_id) when is_function(message_id) do
    put_message_id(message, call_fun(message_id, message))
  end

  def put_message_id(%__MODULE__{} = message, message_id) do
    %{message | message_id: message_id}
  end

  @doc """
  Assigns a message_id to the message when one isn't set already.

  ## Examples

      iex> import Conduit.Message
      iex> message = put_new_message_id(%Conduit.Message{}, 1)
      iex> message = put_new_message_id(message, 2)
      iex> message.message_id
      1
      iex> message = put_new_message_id(%Conduit.Message{}, fn _mess -> 1 end)
      iex> message = put_new_message_id(message, fn _mess -> 2 end)
      iex> message.message_id
      1

  """
  @spec put_new_message_id(__MODULE__.t(), message_id) :: __MODULE__.t()
  def put_new_message_id(%__MODULE__{message_id: nil} = message, message_id) do
    put_message_id(message, message_id)
  end

  def put_new_message_id(%__MODULE__{} = message, _) do
    message
  end

  @doc """
  Assigns a content_type to the message.

  ## Examples

      iex> import Conduit.Message
      iex> message = put_content_type(%Conduit.Message{}, "application/json")
      iex> message.content_type
      "application/json"
      iex> message = put_content_type(%Conduit.Message{}, fn _mess -> "application/json" end)
      iex> message.content_type
      "application/json"

  """
  @spec put_content_type(__MODULE__.t(), content_type) :: __MODULE__.t()
  def put_content_type(%__MODULE__{} = message, content_type) when is_function(content_type) do
    put_content_type(message, call_fun(content_type, message))
  end

  def put_content_type(%__MODULE__{} = message, content_type) do
    %{message | content_type: content_type}
  end

  @doc """
  Assigns a content_encoding to the message.

  ## Examples

      iex> import Conduit.Message
      iex> message = put_content_encoding(%Conduit.Message{}, "gzip")
      iex> message.content_encoding
      "gzip"
      iex> message = put_content_encoding(%Conduit.Message{}, fn _mess -> "gzip" end)
      iex> message.content_encoding
      "gzip"

  """
  @spec put_content_encoding(__MODULE__.t(), content_encoding) :: __MODULE__.t()
  def put_content_encoding(%__MODULE__{} = message, content_encoding)
      when is_function(content_encoding) do
    put_content_encoding(message, call_fun(content_encoding, message))
  end

  def put_content_encoding(%__MODULE__{} = message, content_encoding) do
    %{message | content_encoding: content_encoding}
  end

  @doc """
  Assigns a created_by to the message.

  ## Examples

      iex> import Conduit.Message
      iex> message = put_created_by(%Conduit.Message{}, "my_app")
      iex> message.created_by
      "my_app"
      iex> message = put_created_by(%Conduit.Message{}, fn _mess ->"my_app" end)
      iex> message.created_by
      "my_app"

  """
  @spec put_created_by(__MODULE__.t(), created_by) :: __MODULE__.t()
  def put_created_by(%__MODULE__{} = message, created_by) when is_function(created_by) do
    put_created_by(message, call_fun(created_by, message))
  end

  def put_created_by(%__MODULE__{} = message, created_by) do
    %{message | created_by: created_by}
  end

  @doc """
  Assigns a created_at to the message.

  ## Examples

      iex> import Conduit.Message
      iex> message = put_created_at(%Conduit.Message{}, 1)
      iex> message.created_at
      1
      iex> message = put_created_at(%Conduit.Message{}, fn _mess -> 1 end)
      iex> message.created_at
      1

  """
  @spec put_created_at(__MODULE__.t(), created_at) :: __MODULE__.t()
  def put_created_at(%__MODULE__{} = message, created_at) when is_function(created_at) do
    put_created_at(message, call_fun(created_at, message))
  end

  def put_created_at(%__MODULE__{} = message, created_at) do
    %{message | created_at: created_at}
  end

  @fields [
    :source,
    :destination,
    :user_id,
    :correlation_id,
    :message_id,
    :content_type,
    :content_encoding,
    :created_by,
    :created_at
  ]
  @doc """
  Returns all non-`nil` fields from the message as a map.

  The following fields will be returned:
  #{@fields |> Enum.map(&"* `#{inspect(&1)}`") |> Enum.join("\n")}

  ## Examples

      iex> import Conduit.Message
      iex> message =
      iex>   %Conduit.Message{}
      iex>   |> put_message_id("1")
      iex>   |> put_correlation_id("2")
      iex> get_fields(message)
      %{
        message_id: "1",
        correlation_id: "2"
      }
  """
  @spec get_fields(__MODULE__.t()) :: %{atom() => term()}
  def get_fields(%__MODULE__{} = message) do
    message
    |> Map.take(@fields)
    |> Enum.filter(fn {_, value} -> value != nil end)
    |> Enum.into(%{})
  end

  @doc """
  Returns a header from the message specified by `key`.

  ## Examples

      iex> import Conduit.Message
      iex> message = put_header(%Conduit.Message{}, "retries", 1)
      iex> get_header(message, "retries")
      1

  """
  @spec get_header(__MODULE__.t(), String.t()) :: any
  def get_header(%__MODULE__{headers: headers}, key) when is_binary(key) do
    get_in(headers, [key])
  end

  @doc """
  Assigns a header for the message specified by `key`.

  ## Examples

      iex> import Conduit.Message
      iex> message = put_header(%Conduit.Message{}, "retries", 1)
      iex> get_header(message, "retries")
      1
      iex> message = put_header(message, "retries", fn mess -> get_header(mess, "retries") + 1 end)
      iex> get_header(message, "retries")
      2

  """
  @spec put_header(__MODULE__.t(), String.t(), any) :: __MODULE__.t()
  def put_header(%__MODULE__{} = message, key, value)
      when is_function(value) and is_binary(key) do
    put_header(message, key, call_fun(value, message))
  end

  def put_header(%__MODULE__{headers: headers} = message, key, value) when is_binary(key) do
    %{message | headers: put_in(headers, [key], value)}
  end

  @doc """
  Assigns a header for the message specified by `key`.

  ## Examples

      iex> import Conduit.Message
      iex> message = put_headers(%Conduit.Message{}, %{"retries" => 1})
      iex> get_header(message, "retries")
      1
      iex> message = put_headers(message, %{"retries" => fn mess -> get_header(mess, "retries") + 1 end})
      iex> get_header(message, "retries")
      2

  """
  @spec put_headers(__MODULE__.t(), %{String.t() => any}) :: __MODULE__.t()
  def put_headers(%__MODULE__{} = message, headers) when is_map(headers) do
    Enum.reduce(headers, message, fn {key, value}, mess ->
      put_header(mess, key, value)
    end)
  end

  @doc """
  Deletes a header from the message specified by `key`.

  ## Examples

      iex> import Conduit.Message
      iex> message = put_header(%Conduit.Message{}, "retries", 1)
      iex> message = delete_header(message, "retries")
      iex> get_header(message, "retries")
      nil
  """
  @spec delete_header(__MODULE__.t(), String.t()) :: __MODULE__.t()
  def delete_header(%__MODULE__{headers: headers} = message, key) do
    %{message | headers: Map.delete(headers, key)}
  end

  @doc """
  Assigns the content of the message.

  ## Examples

      iex> import Conduit.Message
      iex> message = put_body(%Conduit.Message{}, "hi")
      iex> message.body
      "hi"
      iex> message = put_body(message, fn _mess -> "bye" end)
      iex> message.body
      "bye"

  """
  @spec put_body(__MODULE__.t(), body) :: __MODULE__.t()
  def put_body(%__MODULE__{} = message, body) when is_function(body) do
    put_body(message, call_fun(body, message))
  end

  def put_body(%__MODULE__{} = message, body) do
    %{message | body: body}
  end

  @doc """
  Assigs the status of the message as acknowledged. This will be used
  to signal to the message queue that processing the message was successful
  and can be discarded.

  ## Examples

      iex> import Conduit.Message
      iex> message = ack(%Conduit.Message{})
      iex> message.status
      :ack

  """
  @spec ack(__MODULE__.t()) :: __MODULE__.t()
  def ack(message) do
    %{message | status: :ack}
  end

  @doc """
  Assigs the status of the message to a negative acknowledged. This will be used
  to signal to the message queue that processing the message was not successful.

  ## Examples

      iex> import Conduit.Message
      iex> message = nack(%Conduit.Message{})
      iex> message.status
      :nack

  """
  @spec nack(__MODULE__.t()) :: __MODULE__.t()
  def nack(message) do
    %{message | status: :nack}
  end

  @doc """
  Retrieves a named value from the message.

  ## Examples

      iex> import Conduit.Message
      iex> message = assign(%Conduit.Message{}, :user_id, 1)
      iex> assigns(message, :user_id)
      1

  """
  @spec assigns(__MODULE__.t(), term) :: __MODULE__.t()
  def assigns(%__MODULE__{assigns: assigns}, key) do
    get_in(assigns, [key])
  end

  @doc """
  Assigns a named value to the message.

  ## Examples

      iex> import Conduit.Message
      iex> message = assign(%Conduit.Message{}, :user_id, 1)
      iex> assigns(message, :user_id)
      1

  """
  @spec assign(__MODULE__.t(), atom, any) :: __MODULE__.t()
  def assign(%__MODULE__{assigns: assigns} = message, key, value) when is_atom(key) do
    %{message | assigns: Map.put(assigns, key, value)}
  end

  @doc """
  Retrieves a named value from the message. This is intended for libraries and framework use.

  ## Examples

      iex> import Conduit.Message
      iex> message = put_private(%Conduit.Message{}, :message_id, 1)
      iex> get_private(message, :message_id)
      1

  """
  @spec get_private(__MODULE__.t(), atom) :: term
  def get_private(%__MODULE__{private: private}, key) do
    get_in(private, [key])
  end

  @doc """
  Assigns a named value to the message. This is intended for libraries and framework use.

  ## Examples

      iex> import Conduit.Message
      iex> message = put_private(%Conduit.Message{}, :message_id, 1)
      iex> get_private(message, :message_id)
      1

  """
  @spec put_private(__MODULE__.t(), atom, any) :: __MODULE__.t()
  def put_private(%__MODULE__{private: private} = message, key, value) when is_atom(key) do
    %{message | private: Map.put(private, key, value)}
  end

  defp call_fun(fun, message) do
    call_fun(fun, message, :erlang.fun_info(fun, :arity))
  end

  defp call_fun(fun, _message, {:arity, 0}), do: fun.()
  defp call_fun(fun, message, {:arity, 1}), do: fun.(message)

  defp call_fun(_fun, _message, {:arity, n}) do
    message = """
    Expected function with arity of 0 or 1, but got one with arity #{n}.
    """

    raise Conduit.BadArityError, message
  end
end

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

  @type source :: binary | nil
  @type destination :: binary | fun | nil
  @type user_id :: binary | integer | nil
  @type correlation_id :: binary | integer | nil
  @type message_id :: binary | integer | nil
  @type content_type :: String.t | nil
  @type content_encoding :: String.t | nil
  @type created_by :: binary | nil
  @type created_at :: String.t | integer | nil
  @type headers :: %{String.t => any}
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

  alias Conduit.Message

  @doc """
  Assigns the source of the message.

  ## Examples

      iex> import Conduit.Message
      iex> message = put_source(%Conduit.Message{}, "my.queue")
      iex> message.source
      "my.queue"

  """
  @spec put_source(Conduit.Message.t, source) :: Conduit.Message.t
  def put_source(%Message{} = message, source) do
    %{message | source: source}
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
      iex> message = put_destination(message, fn message -> message.source <> ".error" end)
      iex> message.destination
      "over.there.error"

  """
  @spec put_destination(Conduit.Message.t, destination) :: Conduit.Message.t
  def put_destination(%Message{} = message, destination) when is_function(destination) do
    put_destination(message, destination.(message))
  end
  def put_destination(%Message{} = message, destination) do
    %{message | destination: destination}
  end

  @doc """
  Assigns a user_id to the message.

  ## Examples

      iex> import Conduit.Message
      iex> message = put_user_id(%Conduit.Message{}, 1)
      iex> message.user_id
      1

  """
  @spec put_user_id(Conduit.Message.t, user_id) :: Conduit.Message.t
  def put_user_id(%Message{} = message, user_id) do
    %{message | user_id: user_id}
  end

  @doc """
  Assigns a correlation_id to the message.

  ## Examples

      iex> import Conduit.Message
      iex> message = put_correlation_id(%Conduit.Message{}, 1)
      iex> message.correlation_id
      1

  """
  @spec put_correlation_id(Conduit.Message.t, correlation_id) :: Conduit.Message.t
  def put_correlation_id(%Message{} = message, correlation_id) do
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

  """
  @spec put_new_correlation_id(Conduit.Message.t, correlation_id) :: Conduit.Message.t
  def put_new_correlation_id(%Message{correlation_id: nil} = message, correlation_id) do
    %{message | correlation_id: correlation_id}
  end
  def put_new_correlation_id(%Message{} = message, _) do
    message
  end

  @doc """
  Assigns a message_id to the message.

  ## Examples

      iex> import Conduit.Message
      iex> message = put_message_id(%Conduit.Message{}, 1)
      iex> message.message_id
      1

  """
  @spec put_message_id(Conduit.Message.t, message_id) :: Conduit.Message.t
  def put_message_id(%Message{} = message, message_id) do
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

  """
  @spec put_new_message_id(Conduit.Message.t, message_id) :: Conduit.Message.t
  def put_new_message_id(%Message{message_id: nil} = message, message_id) do
    %{message | message_id: message_id}
  end
  def put_new_message_id(%Message{} = message, _) do
    message
  end

  @doc """
  Assigns a content_type to the message.

  ## Examples

      iex> import Conduit.Message
      iex> message = put_content_type(%Conduit.Message{}, 1)
      iex> message.content_type
      1

  """
  @spec put_content_type(Conduit.Message.t, content_type) :: Conduit.Message.t
  def put_content_type(%Message{} = message, content_type) do
    %{message | content_type: content_type}
  end

  @doc """
  Assigns a content_encoding to the message.

  ## Examples

      iex> import Conduit.Message
      iex> message = put_content_encoding(%Conduit.Message{}, 1)
      iex> message.content_encoding
      1

  """
  @spec put_content_encoding(Conduit.Message.t, content_encoding) :: Conduit.Message.t
  def put_content_encoding(%Message{} = message, content_encoding) do
    %{message | content_encoding: content_encoding}
  end

  @doc """
  Assigns a created_by to the message.

  ## Examples

      iex> import Conduit.Message
      iex> message = put_created_by(%Conduit.Message{}, 1)
      iex> message.created_by
      1

  """
  @spec put_created_by(Conduit.Message.t, created_by) :: Conduit.Message.t
  def put_created_by(%Message{} = message, created_by) do
    %{message | created_by: created_by}
  end

  @doc """
  Assigns a created_at to the message.

  ## Examples

      iex> import Conduit.Message
      iex> message = put_created_at(%Conduit.Message{}, 1)
      iex> message.created_at
      1

  """
  @spec put_created_at(Conduit.Message.t, created_at) :: Conduit.Message.t
  def put_created_at(%Message{} = message, created_at) do
    %{message | created_at: created_at}
  end

  @doc """
  Returns a header from the message specified by `key`.

  ## Examples

      iex> import Conduit.Message
      iex> message = put_header(%Conduit.Message{}, "retries", 1)
      iex> get_header(message, "retries")
      1

  """
  @spec get_header(Conduit.Message.t, String.t) :: any
  def get_header(%Message{headers: headers}, key) when is_binary(key) do
    get_in(headers, [key])
  end

  @doc """
  Assigns a header for the message specified by `key`.

  ## Examples

      iex> import Conduit.Message
      iex> message = put_header(%Conduit.Message{}, "retries", 1)
      iex> get_header(message, "retries")
      1
  """
  @spec put_header(Conduit.Message.t, String.t, any) :: Conduit.Message.t
  def put_header(%Message{headers: headers} = message, key, value) when is_binary(key) do
    %{message | headers: put_in(headers, [key], value)}
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
  @spec delete_header(Conduit.Message.t, String.t) :: Conduit.Message.t
  def delete_header(%Message{headers: headers} = message, key) do
    %{message | headers: Map.delete(headers, key)}
  end

  @doc """
  Assigns the content of the message.

  ## Examples

      iex> import Conduit.Message
      iex> message = put_body(%Conduit.Message{}, "hi")
      iex> message.body
      "hi"

  """
  @spec put_body(Conduit.Message.t, body) :: Conduit.Message.t
  def put_body(%Message{} = message, body) do
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
  @spec ack(Conduit.Message.t) :: Conduit.Message.t
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
  @spec nack(Conduit.Message.t) :: Conduit.Message.t
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
  @spec assigns(Conduit.Message.t, term) :: Conduit.Message.t
  def assigns(%Message{assigns: assigns}, key) do
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
  @spec assign(Conduit.Message.t, atom, any) :: Conduit.Message.t
  def assign(%Message{assigns: assigns} = message, key, value) when is_atom(key) do
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
  @spec get_private(Conduit.Message.t, term) :: Conduit.Message.t
  def get_private(%Message{private: private}, key) do
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
  @spec put_private(Conduit.Message.t, atom, any) :: Conduit.Message.t
  def put_private(%Message{private: private} = message, key, value) when is_atom(key) do
    %{message | private: Map.put(private, key, value)}
  end
end

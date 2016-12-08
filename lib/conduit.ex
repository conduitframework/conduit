defmodule Conduit do
  defmodule UnknownContentTypeError do
    @moduledoc """
    Exception raised when the content type is not recognized
    """
    defexception [:message]
  end

  defmodule UnknownEncodingError do
    @moduledoc """
    Exception raised when the content encoding is not recognized
    """
    defexception [:message]
  end

  defmodule BrokerDefinitionError do
    @moduledoc """
    Exception raised when broker is incorrectly defined
    """
    defexception [:message]
  end

  defmodule UnknownPlugError do
    @moduledoc """
    Exception raised when module is used as plug, but cannot be found
    """
    defexception [:message]
  end
end

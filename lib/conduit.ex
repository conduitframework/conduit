defmodule Conduit do
  @moduledoc """
  A message queue framework, with support for middleware and multiple adapters.
  """

  defmodule BadArityError do
    @moduledoc """
    Exception raised when a function with bad arity is provided.
    """
    defexception [:message]
  end

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

  defmodule UndefinedPipelineError do
    @moduledoc """
    Exception raised calling a pipeline that is undefined
    """
    defexception [:message]
  end

  defmodule UndefinedPublishRouteError do
    @moduledoc """
    Exception raised calling a publish route that is undefined
    """
    defexception [:message]
  end

  defmodule UndefinedSubscribeRouteError do
    @moduledoc """
    Exception raised calling a subscribe route that is undefined
    """
    defexception [:message]
  end

  defmodule DuplicateRouteError do
    @moduledoc """
    Exception raised when two routes have the same name
    """
    defexception [:message]
  end

  defmodule AdapterNotConfiguredError do
    @moduledoc """
    Exception raised when no adapter is configured
    """
    defexception message: """
                 There was no adapter configured for your broker. You can configured
                 an adapter in your config.

                     config :my_app, MyApp.Broker,
                       adapter: ConduitAdapter # The message queue adapter to use

                   Note that different adapters may have additional configuration
                   necessary.
                 """
  end
end

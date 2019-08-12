defmodule Conduit.BadArityError do
  @moduledoc """
  Exception raised when a function with bad arity is provided.
  """
  defexception [:message]
end

defmodule Conduit.UnknownContentTypeError do
  @moduledoc """
  Exception raised when the content type is not recognized
  """
  defexception [:message]
end

defmodule Conduit.UnknownEncodingError do
  @moduledoc """
  Exception raised when the content encoding is not recognized
  """
  defexception [:message]
end

defmodule Conduit.BrokerDefinitionError do
  @moduledoc """
  Exception raised when broker is incorrectly defined
  """
  defexception [:message]
end

defmodule Conduit.UnknownPlugError do
  @moduledoc """
  Exception raised when module is used as plug, but cannot be found
  """
  defexception [:message]
end

defmodule Conduit.UndefinedPipelineError do
  @moduledoc """
  Exception raised calling a pipeline that is undefined
  """
  defexception [:message]
end

defmodule Conduit.UndefinedPublishRouteError do
  @moduledoc """
  Exception raised calling a publish route that is undefined
  """
  defexception [:message]
end

defmodule Conduit.UndefinedSubscribeRouteError do
  @moduledoc """
  Exception raised calling a subscribe route that is undefined
  """
  defexception [:message]
end

defmodule Conduit.DuplicateRouteError do
  @moduledoc """
  Exception raised when two routes have the same name
  """
  defexception [:message]
end

defmodule Conduit.AdapterNotConfiguredError do
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

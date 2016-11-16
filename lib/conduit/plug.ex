defmodule Conduit.Plug do
  @moduledoc """
  Defines the plug behavior
  """
  @type opts :: tuple | atom | integer | float | [opts]

  @callback init(opts) :: opts
  @callback call(Conduit.Message.t, opts) :: Conduit.Message.t
end

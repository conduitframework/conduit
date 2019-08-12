defmodule Conduit do
  @moduledoc """
  A message queue framework, with support for middleware and multiple adapters.
  """

  @type postfix :: nil | module() | [postfix: module() | nil]
  @type broker_name :: module()

  @doc false
  @spec broker_name(Conduit.Broker.t(), postfix) :: broker_name()
  def broker_name(broker, postfix \\ nil)

  def broker_name(broker, config) when is_list(config) do
    broker_name(broker, config[:postfix])
  end

  def broker_name(broker, postfix) do
    Module.concat(broker, postfix)
  end
end

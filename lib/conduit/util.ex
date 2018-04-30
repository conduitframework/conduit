defmodule Conduit.Util do
  @moduledoc false

  @doc """
  Escapes ast code unless it's a function
  """
  @spec escape(term) :: term
  def escape({label, _, _} = fun) when label in [:&, :fn] do
    fun
  end

  def escape(data) do
    Macro.escape(data)
  end
end

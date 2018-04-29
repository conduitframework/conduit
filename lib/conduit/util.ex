defmodule Conduit.Util do
  def escape({label, _, _} = fun) when label in [:&, :fn] do
    fun
  end

  def escape(data) do
    Macro.escape(data)
  end
end

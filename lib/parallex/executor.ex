defmodule Parallex.Executor do
  alias Parallex.Executable

  def execute(executable), do: Executable.execute(executable, %{})
end

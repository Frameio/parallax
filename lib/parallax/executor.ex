defmodule Parallax.Executor do
  alias Parallax.Executable

  def execute(executable), do: Executable.execute(executable, %{})
end

defprotocol Parallex.Executable do
  @moduledoc """
  Protocol for handling execution of batch operations, sequences of batch operations, etc.
  """
  def execute(operation, args)
end

defimpl Parallex.Executable, for: Function do
  @doc """
  Just execute the function with `args`
  """
  def execute(fun, args), do: fun.(args)
end

defimpl Parallex.Executable, for: Parallex.Batch do
  @doc """
  Parallelizes the given set of ops by passing `args` to each and returns a map of names to results
  """
  def execute(%{operations: operations, opts: opts}, args) do
    operations
    |> Task.async_stream(fn {name, operation} ->
      {name, Parallex.Executable.execute(operation, args)}
    end, parallel_opts(opts, operations))
    |> Enum.map(fn
      {:ok, res} -> res
      {:exit, reason} -> %Parallex.Error{reason: reason}
    end)
    |> Enum.into(%{})
  end

  def parallel_opts(opts, operations) do
    (opts || [])
    |> Keyword.put_new(:max_concurrency, map_size(operations))
    |> Keyword.put_new(:ordered, false)
  end
end

defimpl Parallex.Executable, for: Parallex.Sequence do
  @doc """
  Executes each operation in sequence, merging the result maps along the way through
  each iteration in the reduce.
  """
  def execute(%{sequence: sequence}, args) do
    sequence
    |> Enum.reverse()
    |> Enum.reduce(args, fn executable, args ->
      Map.merge(args, Parallex.Executable.execute(executable, args))
    end)
  end
end

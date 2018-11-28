defprotocol Parallex.Executable do
  @moduledoc """
  Protocol for handling execution of batch operations, sequences of batch operations, etc.
  """
  @spec execute(Parallex.executable, map) :: Parallex.Result.t | map | any
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
    |> Parallex.Result.new()
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

  This implementation assumes that each operation returns a `Parallex.Result.t` or a map, so
  it should really only contain higher level orchestrators like a `Parallex.Batch.t` or
  another sequence
  """
  def execute(%{sequence: sequence}, args) do
    sequence
    |> Enum.reverse()
    |> maybe_halt(args)
  end

  defp maybe_halt([], args), do: args
  defp maybe_halt([operation | rest], args) do
    case Parallex.Executable.execute(operation, args) do
      %Parallex.Result{halted: true, results: results} -> Map.merge(args, results)
      %Parallex.Result{results: results} -> maybe_halt(rest, Map.merge(args, results))
      map when is_map(map) -> maybe_halt(rest, Map.merge(args, map))
    end
  end
end

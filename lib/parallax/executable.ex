defprotocol Parallax.Executable do
  @moduledoc """
  Protocol for handling execution of batch operations, sequences of batch operations, etc.
  """
  @spec execute(Parallax.executable, map) :: Parallax.Result.t | map | any
  def execute(operation, args)
end

defimpl Parallax.Executable, for: Function do
  @doc """
  Just execute the function with `args`
  """
  def execute(fun, args) do
    case :erlang.fun_info(fun, :arity) do
      {:arity, 1} -> fun.(args)
      {:arity, 0} -> fun.()
    end
  end
end

defimpl Parallax.Executable, for: Tuple do
  @doc """
  Accepts a tuple like `{fun, requirements}` and calls the function
  with the requirements mapped to the functions positional arguments
  """
  def execute({fun, requirements}, args), do: apply(fun, Enum.map(requirements, &Map.get(args, &1)))
end

defimpl Parallax.Executable, for: Parallax.Batch do
  @doc """
  Parallelizes the given set of ops by passing `args` to each and returns a map of names to results
  """
  def execute(%{operations: operations, opts: opts}, args) do
    operations
    |> Parallax.Parallelizer.parallelize(&Parallax.Executable.execute(&1, args), parallel_opts(opts, operations))
    |> Parallax.Result.new()
  end

  def parallel_opts(opts, operations) do
    (opts || [])
    |> Keyword.put_new(:max_concurrency, map_size(operations))
    |> Keyword.put_new(:ordered, false)
  end
end

defimpl Parallax.Executable, for: Parallax.Sequence do
  @doc """
  Executes each operation in sequence, merging the result maps along the way through
  each iteration in the reduce.

  This implementation assumes that each operation returns a `Parallax.Result.t` or a map, so
  it should really only contain higher level orchestrators like a `Parallax.Batch.t` or
  another sequence
  """
  def execute(%{sequence: sequence, args: seq_args}, args) do
    sequence
    |> Enum.reverse()
    |> maybe_halt(Map.merge(seq_args, args))
    |> Map.drop(Map.keys(seq_args))
  end

  defp maybe_halt([], args), do: args
  defp maybe_halt([operation | rest], args) do
    case Parallax.Executable.execute(operation, args) do
      %Parallax.Result{halted: true, results: results} -> Map.merge(args, results)
      %Parallax.Result{results: results} -> maybe_halt(rest, Map.merge(args, results))
      map when is_map(map) -> maybe_halt(rest, Map.merge(args, map))
    end
  end
end

defimpl Parallax.Executable, for: Parallax.Graph do
  @doc """
  Compiles the graph into a `Parallax.Sequence.t` and executes it
  """
  def execute(graph, args) do
    Parallax.Graph.compile(graph)
    |> Parallax.Executable.execute(args)
  end
end

defmodule Parallax do
  @moduledoc """
  Simple module for orchestrating parallel tasks.

  There are two basic abstractions for a Parallax operation, a `Parallax.Graph.t`,
  created by `new/0`, or a `Parallax.Sequence.t`, created by `sequence/0`.  The latter
  allows you to tweak your own parallelism structure, while the graph infers an optimal
  parallelism strategy from the dependency DAG defined by subsequent calls to `operation/4`.

  There are three main ways to add to sequences:

  * `sync/3` - appends a task to be executed synchronously
  * `parallel/3` - adds the task to be executed in parallel within the current batch
  * `nest/3` - nests an existing Parallax.Executable within the current batch

  To add to a graph, simply do `Parallax.sync(graph, :name, fun, requires: :requirement)` (also
  accepting a list of requirements)

  To execute the operation, simply call `Parallax.execute/1`

  All require a unique name so the result can be addressed after execution
  """
  alias Parallax.{Sequence, Graph, Batch, Executor}

  @type executable :: Batch.t | Sequence.t | (map -> any)

  @doc """
  Creates a new sequence with the given opts to pass along
  """
  def new(args \\ %{}, opts \\ []), do: %Graph{args: args, opts: opts}

  def sequence(args \\ %{}, opts \\ []), do: %Sequence{args: args, opts: opts}

  def operation(%Graph{deps: deps, adj: adj} = graph, name, operation, requires \\ []),
    do: Graph.add_node(graph, name, operation, Keyword.get(requires, :requires, :root))

  @doc  """
  Appends a new batch to the sequence, and adds the given operation to it.  Sequence ops are
  inherited.
  """
  def sync(%Sequence{opts: opts} = sequence, name, operation) do
    batch = Batch.new(opts: opts)
    Sequence.append(sequence, Batch.append(batch, name, operation))
  end

  @doc """
  Adds the operation to the current batch for parallelization.
  """
  def parallel(%Sequence{sequence: []} = seq, name, operation), do: sync(seq, name, operation)
  def parallel(%Sequence{sequence: [%Batch{} = batch | _]} = sequence, name, operation),
    do: Sequence.amend(sequence, Batch.append(batch, name, operation))

  @doc """
  Nests another executable within the current batch.  This is really just an alias to parallel, but
  distinct naming is there for clarity.
  """
  def nest(%Sequence{} = seq, name, operation) when not is_function(operation),
    do: parallel(seq, name, operation)

  def execute(%Sequence{} = sequence), do: Executor.execute(sequence)
  def execute(%Graph{} = graph), do: Executor.execute(graph)
end

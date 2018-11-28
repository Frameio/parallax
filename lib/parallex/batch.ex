defmodule Parallex.Batch do
  @moduledoc """
  Representation of a parallelized set of operations, each of which ought to
  be named
  """
  @type t :: %__MODULE__{}

  defstruct [
    operations: %{},
    opts: []
  ]

  @doc """
  Creates a new batch with the optionally supplied args
  """
  @spec new() :: t
  @spec new(list) :: t
  def new(args \\ []), do: struct(__MODULE__, Map.new(args))

  @doc """
  Adds the given named op to the batch.
  """
  @spec append(t, any, Parallex.executable) :: t
  def append(%__MODULE__{operations: ops} = batch, name, fnc),
    do: %{batch | operations: Map.put(ops, name, fnc)}
end

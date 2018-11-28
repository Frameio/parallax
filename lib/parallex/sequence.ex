defmodule Parallax.Sequence do
  @moduledoc """
  Representation of a sequence of tasks, each of which could contain a set of parallel tasks
  """

  @type t :: %__MODULE__{}
  defstruct [
    sequence: [],
    opts: []
  ]

  @doc """
  Creates a new sequence
  """
  @spec new(list) :: t
  def new(args \\ []), do: struct(__MODULE__, Map.new(args))

  @doc """
  Appends an operation to the sequence
  """
  @spec append(t, Parallax.executable) :: t
  def append(%__MODULE__{sequence: sequence} = seq, operation), do: %{seq | sequence: [operation | sequence]}

  @doc """
  Replaces the head of the sequence with the given op
  """
  @spec amend(t, Parallax.executable) :: t
  def amend(%__MODULE__{sequence: [_ | t]} = seq, new_head), do: %{seq | sequence: [new_head | t]}
end

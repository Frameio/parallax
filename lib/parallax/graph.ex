defmodule Parallax.Graph do
  @moduledoc """
  Repesents a graph of parallizable operations.  `Parallax.Executable` will topsort it from root, and
  parallize where possible
  """

  @type t :: %__MODULE__{}
  defstruct [
    deps: %{},
    operations: %{},
    adj: %{},
    opts: [],
    args: %{}
  ]

  def add_node(seq, name, op, requirement) when is_atom(requirement), do: add_node(seq, name, op, [requirement])
  def add_node(%__MODULE__{operations: operations, deps: deps, adj: adj} = seq, name, op, requirements) do
    adj  = Enum.reduce(requirements, adj, &add_dep(&2, &1, name))
    %{seq | adj: adj, operations: Map.put(operations, name, op), deps: Map.put(deps, name, requirements)}
  end


  @doc """
  Sequence the parallel operation by:

  1. Generating the max level in the dependency tree for each operation
  2. Group the operations by that level
  3. Executing each level in parallel, in sorted order
  """
  def compile(%__MODULE__{adj: adj, deps: deps, operations: ops, opts: opts, args: args}) do
    levels  = build_levels(adj)
    grouped = Enum.group_by(levels, &elem(&1, 1), &elem(&1, 0))

    grouped
    |> Map.keys()
    |> Enum.sort()
    |> Enum.reduce(Parallax.sequence(args, opts), fn level, parallax ->
      [name | rest] = Map.get(grouped, level)

      rest
      |> Enum.reduce(Parallax.sync(parallax, name, operation(ops, name, deps)), fn name, parallax ->
        Parallax.parallel(parallax, name, operation(ops, name, deps))
      end)
    end)
  end

  defp build_levels(map), do: build_levels(%{}, [:root], 0, map)
  defp build_levels(result, [], _level, _map), do: result
  defp build_levels(result, last, level, map) do
    nodes = Enum.flat_map(last, &Map.get(map, &1, []))

    nodes
    |> Enum.map(& {&1, level + 1})
    |> Enum.into(result)
    |> build_levels(nodes, level + 1, map)
  end

  defp operation(ops, name, deps) do
    {ops[name], Enum.reject(deps[name], & &1 == :root)}
  end

  defp add_dep(deps, requirement, operation) do
    Map.update(deps, requirement, [operation], fn l -> [operation | l] end)
  end
end

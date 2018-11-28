defmodule ParallexTest do
  use ExUnit.Case
  doctest Parallex

  @test_ops [:a, :b, :c]

  test "It can parallelize a sequence of operations" do
    assert build_parallel_operation(@test_ops)
           |> Parallex.execute() == %{a: 1, b: 1, c: 1}
  end

  test "It can execute a sequence of parallel operations" do
    sequence =
      build_parallel_operation(@test_ops)
      |> Parallex.sync(:d, fn _ -> 1 end)
      |> Parallex.parallel(:e, fn _ -> 1 end)

    assert Parallex.execute(sequence) == %{a: 1, b: 1, c: 1, d: 1, e: 1}
  end

  test "It can nest operations" do
    sequence = build_parallel_operation(@test_ops)
    nested = build_parallel_operation([:d, :e])

    sequence = Parallex.nest(sequence, :nested, nested)

    assert Parallex.execute(sequence) == %{a: 1, b: 1, c: 1, nested: %{d: 1, e: 1}}
  end

  test "It will pass along the results from previous operations" do
    sequence =
      build_parallel_operation(@test_ops)
      |> Parallex.sync(:end, fn
        %{a: 1, b: 1, c: 1} -> true
        _ -> false
      end)

    assert Parallex.execute(sequence)[:end]
  end

  test "It can short circuit an operation" do
    assert Parallex.new()
           |> Parallex.sync(:short, fn _ -> {:halt, 1} end)
           |> Parallex.sync(:next, fn _ -> 1 end)
           |> Parallex.execute() == %{short: 1}
  end

  defp build_parallel_operation(ops) do
    ops
    |> Enum.reduce(Parallex.new(), &Parallex.parallel(&2, &1, fn _ -> 1 end))
  end
end

defmodule ParallaxTest do
  use ExUnit.Case
  doctest Parallax

  @test_ops [:a, :b, :c]

  test "It can parallelize a sequence of operations" do
    assert build_parallel_operation(@test_ops)
           |> Parallax.execute() == %{a: 1, b: 1, c: 1}
  end

  test "It can execute a sequence of parallel operations" do
    sequence =
      build_parallel_operation(@test_ops)
      |> Parallax.sync(:d, fn _ -> 1 end)
      |> Parallax.parallel(:e, fn _ -> 1 end)

    assert Parallax.execute(sequence) == %{a: 1, b: 1, c: 1, d: 1, e: 1}
  end

  test "It can nest operations" do
    sequence = build_parallel_operation(@test_ops)
    nested = build_parallel_operation([:d, :e])

    sequence = Parallax.nest(sequence, :nested, nested)

    assert Parallax.execute(sequence) == %{a: 1, b: 1, c: 1, nested: %{d: 1, e: 1}}
  end

  test "It will pass along the results from previous operations" do
    sequence =
      build_parallel_operation(@test_ops)
      |> Parallax.sync(:end, fn
        %{a: 1, b: 1, c: 1} -> true
        _ -> false
      end)

    assert Parallax.execute(sequence)[:end]
  end

  test "It can short circuit an operation" do
    assert Parallax.sequence()
           |> Parallax.sync(:short, fn _ -> {:halt, 1} end)
           |> Parallax.sync(:next, fn _ -> 1 end)
           |> Parallax.execute() == %{short: 1}
  end

  test "It can pass along args within a sequence" do
    assert Parallax.sequence(%{arg: 1})
           |> Parallax.parallel(:first, fn %{arg: 1} -> 1 end)
           |> Parallax.sync(:second, fn %{arg: 1} -> 1 end)
           |> Parallax.execute() == %{first: 1, second: 1}
  end

  test "It can handle graph operations" do
    result =
      Parallax.new()
      |> Parallax.operation(:first, fn -> 1 end)
      |> Parallax.operation(:second, fn -> 2 end)
      |> Parallax.operation(:third, fn first -> first + 1 end, requires: :first)
      |> Parallax.operation(:fourth, fn second, third -> second + third end, requires: [:second, :third])
      |> Parallax.operation(:fifth, fn first, third, fourth -> first + third + fourth end, requires: [:first, :third, :fourth])
      |> Parallax.execute()

    assert result == %{first: 1, second: 2, third: 2, fourth: 4, fifth: 7}
  end

  defp build_parallel_operation(ops) do
    ops
    |> Enum.reduce(Parallax.sequence(), &Parallax.parallel(&2, &1, fn _ -> 1 end))
  end
end

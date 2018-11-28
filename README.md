# Parallex

Parallelization made simple.  Supports three basic use cases: running n tasks in parallel,
running an arbitrary sequence of batches of parallel tasks, passing the results along the way,
and nesting sequences of parallelized tasks for more complicated graphs of control flow.

The api should look something like

```elixir
Parallex.new()
|> Parallex.parallel(:first, &first_func/1)
|> Parallex.parallel(:second, &second_func/1)
|> Parallex.nest(:nested, additional_sequence)
|> Parallex.sync(:cleanup, fn %{first: f, second: s, nested: nested} -> cleanup(f, s, nested) end)
|> Parallex.execute()
```

You can short circuit execution by returning a `{:halt, any}` tuple in any operation.  Note that parallelized
batches can't be short circuited.

Additionally, the library runs on a protocol `Parallex.Executable`.  If you want to implement your own orchestration
primitive, like `Parallex.Batch` or `Parallex.Sequene`, simply write an implementation of the protocol, and return either
a map or a `Parallex.Result` (if you want to support halting).

## Installation

```elixir
def deps do
  [
    {:parallex, "~> 0.2.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/parallex](https://hexdocs.pm/parallex).


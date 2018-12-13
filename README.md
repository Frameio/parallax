# Parallax

Parallelization made simple.  Supports three basic use cases: running n tasks in parallel,
running an arbitrary sequence of batches of parallel tasks, passing the results along the way,
and nesting sequences of parallelized tasks for more complicated graphs of control flow.

The api should look something like

```elixir
Parallax.new()
|> Parallax.operation(:first, &first_func/1)
|> Parallax.operation(:second, &second_func/1)
|> Parallax.operation(:nested, additional_sequence)
|> Parallax.operation(:cleanup, fn f, s, nested -> 
  cleanup(f, s, nested) 
end, requires: [:first, :second, :nested])
|> Parallax.execute()
```

You can short circuit execution by returning a `{:halt, any}` tuple in any operation.  Note that parallelized
batches can't be short circuited.

Additionally, the library runs on a protocol `Parallax.Executable`.  If you want to implement your own orchestration
primitive, like `Parallax.Batch` or `Parallax.Sequence`, simply write an implementation of the protocol, and return either
a map or a `Parallax.Result` (if you want to support halting).

## Installation

```elixir
def deps do
  [
    {:parallax, "~> 1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/parallex](https://hexdocs.pm/parallex).


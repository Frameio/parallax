defmodule Parallax.Parallelizer do

  def parallelize(enumerable, fun, opts \\ []) do
    enumerable
    |> Enum.map(fn {op, arg} -> {Task.async(fn -> fun.(arg) end), op} end)
    |> Map.new()
    |> yield_all(Keyword.get(opts, :timeout, 5000))
  end

  defp yield_all(tasks_and_names, timeout) do
    tasks_and_names
    |> Map.keys()
    |> Task.yield_many(timeout)
    |> Enum.map(&handle_result(&1, tasks_and_names))
  end

  defp handle_result({task, nil}, tasks_and_names) do
    Task.shutdown(task, :brutal_kill)
    task_result(task, %Parallax.Error{reason: :timeout}, tasks_and_names)
  end
  defp handle_result({task, {:ok, result}}, tasks_and_names), do: task_result(task, result, tasks_and_names)
  defp handle_result({task, {:error, error}}, tasks_and_names),
    do: task_result(task, %Parallax.Error{reason: error}, tasks_and_names)

  defp task_result(task, result, tasks_and_names), do: {Map.get(tasks_and_names, task), result}
end

defmodule Parallax.Result do
  @moduledoc """
  Parallel result return type
  """
  @type t :: %__MODULE__{}
  defstruct [
    results: %{},
    halted: false
  ]

  @doc """
  Creates a new result
  """
  def new(results) do
    result = %__MODULE__{results: results}
    %{result | halted: halted?(result)}
    |> clean()
  end

  defp halted?(%__MODULE__{results: results}) do
    Enum.any?(results, fn
      {_, {:halt, _}} -> true
      _ -> false
    end)
  end

  defp clean(%__MODULE__{results: results} = res) do
    results = Enum.into(results, %{}, fn
      {k, {:halt, v}} -> {k, v}
      pair -> pair
    end)

    %{res | results: results}
  end
end

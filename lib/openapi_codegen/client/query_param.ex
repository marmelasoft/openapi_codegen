defmodule OpenApiCodeGen.Client.QueryParam do
  @moduledoc """
  Generates query param AST from OpenAPI spec using the `parameters` key.
  """
  alias OpenApiCodeGen.Ast

  @doc """
  Generates query param AST from OpenAPI spec using the `parameters` key.
  Returns the variable and the keyword list elements to be used.
  """
  @spec generate(atom(), map()) :: Keyword.t()
  def generate(name, %{"parameters" => parameters}),
    do:
      parameters
      |> Enum.flat_map(&generate_url_parameter(name, &1))
      |> Enum.reduce([], &Keyword.merge/2)
      |> Enum.reverse()

  def generate(_, _), do: []

  defp generate_url_parameter(name, %{"in" => "query"} = parameter), do: parameter_to_ast(name, parameter)

  defp generate_url_parameter(_, _), do: []

  defp parameter_to_ast(name, %{"name" => param_name}) do
    var_name =
      param_name
      |> Macro.underscore()
      |> String.to_atom()

    var = Ast.to_var(var_name, name)

    [quote(do: [{unquote(var_name), unquote(var)}])]
  end
end

defmodule TeslaCodegen.Client.QueryParam do
  @moduledoc """
  Query param generation operations
  """

  @doc """
  Generates query param AST from OpenAPI spec using the `parameters` key.
  Returns the variable and the keyword list elements to be used
  """
  def generate(name, %{"parameters" => parameters}), do: Enum.flat_map(parameters, &generate_url_parameter(name, &1))

  def generate(_, _), do: []

  defp generate_url_parameter(name, %{"in" => "query"} = parameter), do: parameter_to_ast(name, parameter)

  defp generate_url_parameter(_, _), do: []

  defp parameter_to_ast(name, parameter) do
    var_name =
      parameter
      |> Map.get("name")
      |> Macro.underscore()
      |> String.to_atom()

    var = Macro.var(var_name, name)

    [{var, quote(do: [{unquote(var_name), unquote(var)}])}]
  end
end

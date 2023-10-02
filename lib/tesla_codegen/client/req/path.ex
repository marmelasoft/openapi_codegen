defmodule OpenApiCodegen.Client.Req.Path do
  @moduledoc """
  Path generation operations for Req
  """
  alias OpenApiCodegen.Ast

  @path_elements_pattern ~r/{([^}]*)}/
  @doc """
  Generates an interpolated string using:

  ## Params

    * `client_module_name` to generate the module name
    * `path` to generate the request path with string interpolation
  """
  def generate(client_module_name, path), do: generate_path_interpolation(client_module_name, path)

  defp generate_path_interpolation(client_module_name, path) do
    @path_elements_pattern
    |> Regex.split(path, include_captures: true)
    |> Enum.reject(&(&1 == ""))
    |> Enum.map(fn path ->
      case Regex.run(@path_elements_pattern, path) do
        [_, path] ->
          path
          |> Ast.to_var(client_module_name)
          |> then(&quote(do: :"Elixir.Kernel".to_string(unquote(&1)) :: binary))

        _ ->
          quote(do: unquote(path))
      end
    end)
    |> then(&{:<<>>, [], &1})
  end
end

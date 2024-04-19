defmodule OpenApiCodeGen.Client.Req.Path do
  @moduledoc """
  Path generation operations for Req.
  """

  alias OpenApiCodeGen.Ast

  @doc """
  Generates an interpolated string to be used by the client.

  ## Params

    * `client_module_name` module name of the generated client
    * `path` to generate the request path with string interpolation
  """
  def generate(client_module_name, path), do: Ast.generate_path_interpolation(client_module_name, path)
end

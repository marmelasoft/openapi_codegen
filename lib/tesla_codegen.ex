defmodule TeslaCodegen do
  @moduledoc """
  Generates Tesla client from OpenAPI specification.
  """
  alias TeslaCodegen.Ast
  alias TeslaCodegen.Client
  alias TeslaCodegen.Components

  @spec generate(Path.t(), binary()) :: %{schemas: list(Path.t()), client: Path.t()}
  def generate(path, spec_path) do
    name =
      path
      |> Path.split()
      |> Enum.take(-1)
      |> hd()
      |> Macro.camelize()

    # Path.extname()
    spec =
      spec_path
      |> File.read!()
      |> then(
        &case Path.extname(spec_path) do
          ".json" -> Jason.decode!(&1)
          ".yml" -> YamlElixir.read_from_string!(&1)
          ".yaml" -> YamlElixir.read_from_string!(&1)
        end
      )

    schemas = Components.generate(name, spec)
    client = Client.generate(name, spec)

    client_file_path = Ast.to_file!(client, name, path)

    schema_file_paths =
      Enum.map(schemas, fn %{component_module_name: component_module_name, ast: ast} ->
        component_module_name = Atom.to_string(component_module_name)
        Ast.ast_to_file!(ast, component_module_name, Path.join(path, "components"))
      end)

    %{schemas: schema_file_paths, client: client_file_path}
  end
end

defmodule TeslaCodegen do
  @moduledoc """
  Generates Tesla client from OpenAPI specification.
  """

  @doc """
  Generates files from OpenAPI specification and returns the paths for the generated files.
  """
  @path_elements_pattern ~r/{([^}]*)}/

  @spec generate(Path.t(), binary()) :: %{schemas: list(Path.t()), client: Path.t()}
  def generate(path, spec) when is_binary(spec) do
    name = path |> Path.split() |> Enum.take(-1) |> hd() |> Macro.camelize()
    spec = Jason.decode!(spec)
    schemas = generate_schemas(name, path, spec)
    schema_file_paths = Enum.map(schemas, &Map.get(&1, :path))

    %{schemas: schema_file_paths, client: generate_client(name, path, spec)}
  end

  # Generate Components
  defp generate_schemas(name, path, %{"components" => %{"schemas" => schemas}}) do
    Enum.map(schemas, &generate_component(name, path, &1))
  end

  defp generate_component(name, path, {key, %{"properties" => properties}}) do
    component = build_component_ast(name, key, properties)
    file = write_ast_to_file!(component, key, Path.join(path, "components"))

    %{path: file, component: component}
  end

  defp build_component_ast(name, key, properties) do
    quote do
      defmodule unquote(String.to_atom("Elixir.#{name}.#{key}")) do
        @moduledoc unquote("Structure for #{key} component")
        @derive Jason.Encoder
        defstruct(
          unquote(
            properties
            |> Map.keys()
            |> Enum.map(&Macro.underscore/1)
            |> Enum.map(&String.to_atom/1)
          )
        )
      end
    end
  end

  # Generate Client
  defp generate_client(name, path, %{"paths" => paths, "servers" => [%{"url" => server} | _]}) do
    name
    |> build_client_ast(paths, server)
    |> write_ast_to_file!(name, path)
  end

  defp build_client_ast(name, paths, server) do
    name = String.to_atom("Elixir.#{name}")

    quote do
      defmodule unquote(name) do
        use Tesla

        plug(Tesla.Middleware.BaseUrl, unquote(server))

        unquote_splicing(generate_functions_ast(name, paths))
      end
    end
  end

  defp generate_functions_ast(name, paths), do: Enum.map(paths, &generate_function_ast(name, &1))

  defp generate_function_ast(name, {path, %{"get" => content}}), do: generate_function_ast(name, path, content, :get)

  defp generate_function_ast(name, {path, %{"post" => content}}), do: generate_function_ast(name, path, content, :post)

  defp generate_function_ast(name, {path, %{"put" => content}}), do: generate_function_ast(name, path, content, :put)

  defp generate_function_ast(name, {path, %{"delete" => content}}),
    do: generate_function_ast(name, path, content, :delete)

  defp generate_function_ast(name, path, %{"operationId" => func_name} = schema, method) do
    arguments =
      @path_elements_pattern
      |> Regex.scan(path)
      |> Enum.map(fn [_, arg] -> arg |> String.to_atom() |> Macro.var(name) end)

    request_body = generate_request_body_argument(name, schema)
    url_parameters = generate_url_parameters(name, schema)

    arguments =
      case request_body do
        nil -> arguments
        {_, ast} -> arguments ++ [ast]
      end

    arguments =
      case url_parameters do
        [] -> arguments
        url_parameters -> arguments ++ Enum.map(url_parameters, &elem(&1, 0))
      end

    path =
      case url_parameters do
        [] ->
          generate_path_interpolation(name, path)

        url_parameters ->
          path_params = Enum.flat_map(url_parameters, &elem(&1, 1))
          quote do: Tesla.build_url(unquote(generate_path_interpolation(name, path)), unquote(path_params))
      end

    quote do
      def unquote(:"#{Macro.underscore(func_name)}")(unquote_splicing(arguments)) do
        unquote(
          cond do
            method == :get ->
              quote do: get(unquote(path))

            method == :post and is_nil(request_body) ->
              quote do: post(unquote(path))

            method == :post ->
              quote do: post(unquote(path), unquote(elem(request_body, 0)))

            method == :put ->
              quote do: put(unquote(path))

            method == :delete ->
              quote do: delete(unquote(path))

            true ->
              raise "Unknown method #{method}"
          end
        )
      end
    end
  end

  defp generate_request_body_argument(name, %{
         "requestBody" => %{"content" => %{"application/json" => %{"schema" => %{"$ref" => ref}}}}
       }) do
    ref_to_var_ast(name, ref, :single)
  end

  defp generate_request_body_argument(name, %{
         "requestBody" => %{"content" => %{"application/json" => %{"schema" => %{"items" => %{"$ref" => ref}}}}}
       }) do
    ref_to_var_ast(name, ref, :array)
  end

  defp generate_request_body_argument(name, %{"requestBody" => _}) do
    var = Macro.var(:body, name)
    {var, quote(do: unquote(var))}
  end

  defp generate_request_body_argument(_, _), do: nil

  defp ref_to_var_ast(name, ref, type) do
    ref
    |> String.split("/")
    |> Enum.take(-1)
    |> hd()
    |> then(&String.to_atom("#{name}.#{&1}"))
    |> then(fn module ->
      var =
        module
        |> Atom.to_string()
        |> String.split(".")
        |> Enum.take(-1)
        |> hd()
        |> then(
          &case type do
            :array -> "#{&1}s"
            _ -> &1
          end
        )
        |> String.downcase()
        |> String.to_atom()
        |> Macro.var(name)

      ast =
        case type do
          :single -> quote do: %unquote(module){} = unquote(var)
          _ -> quote do: unquote(var)
        end

      {var, ast}
    end)
  end

  defp generate_url_parameters(name, %{"parameters" => parameters}) do
    Enum.flat_map(parameters, &generate_url_parameter(name, &1))
  end

  defp generate_url_parameters(_, _), do: []

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

  defp generate_path_interpolation(name, path) do
    @path_elements_pattern
    |> Regex.split(path, include_captures: true)
    |> Enum.reject(&(&1 == ""))
    |> Enum.map(fn path ->
      case Regex.run(@path_elements_pattern, path) do
        [_, path] ->
          path
          |> String.to_atom()
          |> Macro.var(name)
          |> then(&quote(do: :"Elixir.Kernel".to_string(unquote(&1)) :: binary))

        _ ->
          quote(do: unquote(path))
      end
    end)
    |> then(&{:<<>>, [], &1})
  end

  defp write_ast_to_file!(ast, key, path) do
    File.mkdir_p!(path)

    file_path = Path.join(path, "#{key}.ex")

    ast
    |> Macro.to_string()
    |> Code.format_string!()
    |> Enum.join()
    |> then(&Styler.format(&1, []))
    |> then(&File.write!(file_path, &1))

    file_path
  end
end

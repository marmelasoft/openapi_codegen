defmodule OpenApiCodeGen.Client.Req do
  @moduledoc """
  Req client code generation.
  """
  alias OpenApiCodeGen.Ast
  alias OpenApiCodeGen.Client.QueryParam
  alias OpenApiCodeGen.Client.Req.Path
  alias OpenApiCodeGen.Client.RequestBody

  @path_elements_pattern ~r/{([^}]*)}/

  @doc """
  Generates client AST from OpenAPI spec using:

  ## Params

    * `servers` to generate Tesla middleware for the base URL
    * `operationId` for the name of the functions
    * `paths` keys to determine method for the function
    * `requestBody` to generate the request body argument
    * `path` to generate the request path with string interpolation
    * `parameters` to generate the URL parameters (if they are of type `query`)
  """
  @spec generate(String.t(), map()) :: Macro.t()
  def generate(name, %{"paths" => paths, "servers" => servers}) do
    case servers do
      [%{"url" => server} | _] -> build_client_ast(name, paths, server)
      _ -> build_client_ast(name, paths, "")
    end
  end

  defp build_client_ast(name, paths, server) do
    client_module_name = String.to_atom("Elixir.#{name}")

    quote do
      defmodule unquote(client_module_name) do
        @req Req.new(base_url: unquote(server))

        unquote_splicing(generate_functions_ast(client_module_name, paths))
      end
    end
  end

  defp generate_functions_ast(client_module_name, paths), do: Enum.map(paths, &generate_function(client_module_name, &1))

  defp generate_function(client_module_name, spec) do
    case spec do
      {path, %{"get" => content}} -> generate_function(client_module_name, path, content, :get)
      {path, %{"post" => content}} -> generate_function(client_module_name, path, content, :post)
      {path, %{"put" => content}} -> generate_function(client_module_name, path, content, :put)
      {path, %{"delete" => content}} -> generate_function(client_module_name, path, content, :delete)
      {path, %{"patch" => content}} -> generate_function(client_module_name, path, content, :patch)
    end
  end

  defp generate_function(client_module_name, path, %{"operationId" => func_name} = schema, method) do
    request_body_arguments = RequestBody.generate(client_module_name, schema)
    url_parameters = QueryParam.generate(client_module_name, schema)
    request_path = Path.generate(client_module_name, path)

    function_arguments =
      generate_function_arguments(client_module_name, path, request_body_arguments, url_parameters)

    build_request_function_ast(
      client_module_name,
      func_name,
      method,
      request_path,
      function_arguments,
      request_body_arguments,
      url_parameters
    )
  end

  defp generate_function_arguments(client_module_name, path, request_body_arguments, url_parameters) do
    path_arguments =
      @path_elements_pattern
      |> Regex.scan(path)
      |> Enum.map(fn [_, arg] -> Ast.to_var(arg, client_module_name) end)

    path_arguments
    |> maybe_append_request_body_function_argument(request_body_arguments)
    |> maybe_append_url_parameters_function_arguments(url_parameters, client_module_name)
  end

  defp maybe_append_request_body_function_argument(function_arguments, request_body_arguments) do
    case request_body_arguments do
      nil -> function_arguments
      {_, ast} -> function_arguments ++ [ast]
    end
  end

  defp maybe_append_url_parameters_function_arguments(function_arguments, url_parameters, client_module_name) do
    case url_parameters do
      [] ->
        function_arguments

      url_parameters ->
        url_parameters =
          url_parameters
          |> Keyword.keys()
          |> Enum.map(&Ast.to_var(&1, client_module_name))

        function_arguments ++ url_parameters
    end
  end

  # credo:disable-for-next-line Credo.Check.Refactor.CyclomaticComplexity
  defp build_request_function_ast(
         client_module_name,
         func_name,
         method,
         request_path,
         function_arguments,
         request_body_arguments,
         url_parameters
       ) do
    opts =
      cond do
        url_parameters == [] and is_nil(request_body_arguments) -> []
        is_nil(request_body_arguments) -> [params: url_parameters]
        url_parameters == [] -> [json: elem(request_body_arguments, 0)]
        true -> [json: elem(request_body_arguments, 0), params: url_parameters]
      end

    opts = [url: Ast.to_var("url", client_module_name)] ++ opts

    quote location: :keep do
      def unquote(Ast.sanitize_name(func_name))(unquote_splicing(function_arguments)) do
        url = unquote(request_path)

        unquote(
          cond do
            method == :get -> quote do: Req.get!(@req, unquote(opts))
            method == :post -> quote do: Req.post!(@req, unquote(opts))
            method == :put -> quote do: Req.put!(@req, unquote(opts))
            method == :patch -> quote do: Req.patch!(@req, unquote(opts))
            method == :delete -> quote do: Req.delete!(@req, unquote(opts))
          end
        )
      end
    end
  end
end

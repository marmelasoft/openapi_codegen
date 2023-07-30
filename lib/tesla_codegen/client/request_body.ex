defmodule TeslaCodegen.Client.RequestBody do
  @moduledoc """
  Request body generation operations
  """

  def generate(name, %{"requestBody" => %{"content" => %{"application/json" => %{"schema" => %{"$ref" => ref}}}}}),
    do: ref_to_var_ast(name, ref, :single)

  def generate(name, %{
        "requestBody" => %{"content" => %{"application/json" => %{"schema" => %{"items" => %{"$ref" => ref}}}}}
      }),
      do: ref_to_var_ast(name, ref, :array)

  def generate(name, %{"requestBody" => _}) do
    var = Macro.var(:body, name)
    {var, quote(do: unquote(var))}
  end

  def generate(_, _), do: nil

  defp ref_to_var_ast(client_module_name, ref, type) do
    component_name = component_name_from_ref(ref, client_module_name)
    var = var_from_module(component_name, type)

    ast =
      case type do
        :single -> quote do: %unquote(component_name){} = unquote(var)
        _ -> quote do: unquote(var)
      end

    {var, ast}
  end

  defp component_name_from_ref(ref, client_module_name) do
    ref
    |> String.split("/")
    |> Enum.take(-1)
    |> hd()
    |> then(&String.to_atom("#{client_module_name}.#{&1}"))
  end

  defp var_from_module(client_module_name, type) do
    client_module_name
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
    |> Macro.var(client_module_name)
  end
end

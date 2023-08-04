defmodule TeslaCodegen.Ast do
  @moduledoc """
  AST operations.
  """

  @doc """
  Converts the AST into a string, formats it, styles it and writes it to a file and returns the path to the file.
  """
  @spec to_file!(Macro.t(), String.t(), Path.t()) :: Path.t()
  def to_file!(ast, key, path) do
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

  @doc """
  Converts a string or atom into a variable.

  ## Examples

      iex> to_var(:my_var, __MODULE__)
      {:my_var, [], __MODULE__}

      iex> to_var("my_var", __MODULE__)
      {:my_var, [], __MODULE__}

      iex> to_var("myVar", __MODULE__)
      {:my_var, [], __MODULE__}
  """
  @spec to_var(binary() | atom(), atom()) :: Macro.t()
  def to_var(name, context) when is_atom(name) do
    name
    |> Atom.to_string()
    |> to_var(context)
  end

  def to_var(name, context) when is_binary(name) do
    name
    |> Macro.underscore()
    |> String.to_atom()
    |> Macro.var(context)
  end
end

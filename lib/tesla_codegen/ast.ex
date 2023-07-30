defmodule TeslaCodegen.Ast do
  @moduledoc """
  AST operations
  """

  @doc """
  Converts the AST into a string, formats it, styles it and writes it to a file and returns the path to the file
  """
  @spec ast_to_file!(Macro.t(), String.t(), Path.t()) :: Path.t()
  def ast_to_file!(ast, key, path) do
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

defmodule OpenApiCodeGen.AstTest do
  use ExUnit.Case

  alias OpenApiCodeGen.Ast

  doctest Ast, import: true

  describe "generate_path_interpolation/2" do
    test "with URL params" do
      assert __MODULE__
             |> Ast.generate_path_interpolation("/users/{user_id}/posts/{post_id}")
             |> Macro.to_string() == "\"/users/\#{user_id}/posts/\#{post_id}\""
    end

    test "without URL params" do
      assert __MODULE__
             |> Ast.generate_path_interpolation("/users/1/posts/2")
             |> Macro.to_string() == "\"/users/1/posts/2\""
    end
  end
end

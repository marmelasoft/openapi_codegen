defmodule TeslaCodegenTest do
  use ExUnit.Case

  doctest TeslaCodegen

  setup do
    on_exit(fn -> File.rm_rf!("tmp") end)
  end

  describe "generate/1" do
    test "generates components" do
      content = File.read!("test/support/fixtures/openapi_petstore.json")
      %{schemas: result} = TeslaCodegen.generate(PetStore, "tmp", content)

      assert result == [
               "tmp/components/Address.ex",
               "tmp/components/ApiResponse.ex",
               "tmp/components/Category.ex",
               "tmp/components/Customer.ex",
               "tmp/components/Order.ex",
               "tmp/components/Pet.ex",
               "tmp/components/Tag.ex",
               "tmp/components/User.ex"
             ]

      Enum.each(result, fn path ->
        assert File.exists?(path)
        fixture_path = path |> String.split("/") |> Enum.drop(1) |> Path.join()
        assert File.read!(path) == File.read!("test/support/fixtures/expected/#{fixture_path}")
      end)
    end
  end
end

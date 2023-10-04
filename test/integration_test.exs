defmodule IntegrationTest do
  use ExUnit.Case, async: false

  @moduletag :integration

  describe "pet store spec integration test" do
    test "generated Tesla client is able to call service" do
      on_exit(fn -> File.rm_rf!("tmp") end)

      %{client: client, schemas: schemas} =
        OpenApiCodeGen.CLI.main([
          "--tesla",
          "--output-path",
          "tmp/integration/tesla/petstore_client",
          "test/support/fixtures/openapi_petstore.json"
        ])

      Enum.map(schemas ++ [client], &Code.compile_file/1)
      assert_functions(Tesla.Env)
    end

    test "generated Req client is able to call service" do
      on_exit(fn -> File.rm_rf!("tmp") end)

      %{client: client, schemas: schemas} =
        OpenApiCodeGen.CLI.main([
          "--req",
          "--output-path",
          "tmp/integration/req/petstore_client",
          "test/support/fixtures/openapi_petstore.json"
        ])

      Enum.map(schemas ++ [client], &Code.compile_file/1)

      assert_functions(Req.Response)
    end
  end

  defp assert_functions(expected_struct) do
    pet = struct(PetstoreClient.Pet, name: "test", id: 1)
    user = struct(PetstoreClient.User, username: "test", id: 1)
    order = struct(PetstoreClient.Order, id: 1)

    assert is_struct(apply(PetstoreClient, :find_pets_by_status, ["status"]), expected_struct)
    assert is_struct(apply(PetstoreClient, :find_pets_by_tags, ["tag"]), expected_struct)
    assert is_struct(apply(PetstoreClient, :get_inventory, []), expected_struct)
    assert is_struct(apply(PetstoreClient, :get_order_by_id, [1]), expected_struct)
    assert is_struct(apply(PetstoreClient, :get_user_by_name, ["username"]), expected_struct)
    assert is_struct(apply(PetstoreClient, :get_pet_by_id, [1]), expected_struct)

    assert is_struct(apply(PetstoreClient, :create_user, [user]), expected_struct)
    assert is_struct(apply(PetstoreClient, :add_pet, [pet]), expected_struct)
    assert is_struct(apply(PetstoreClient, :place_order, [order]), expected_struct)
    assert is_struct(apply(PetstoreClient, :create_users_with_list_input, [[user]]), expected_struct)

    # TODO: currently failing due to forced json decoding
    # assert is_struct(apply(PetstoreClient, :login_user, ["user", "password"]), expected_struct)
    # assert is_struct(apply(PetstoreClient, :logout_user, []), expected_struct)

    # TODO: currently fails because of forced json encoding instead of octet-stream
    # assert is_struct(apply(PetstoreClient, :upload_file, [1, "body", "additional_metadata"]), expected_struct)
  end
end

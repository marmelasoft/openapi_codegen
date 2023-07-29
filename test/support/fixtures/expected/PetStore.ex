defmodule PetStore do
  @moduledoc false
  use Tesla

  plug(Tesla.Middleware.BaseUrl, "https://petstore3.swagger.io/api/v3")

  def add_pet(%PetStore.Pet{} = pet) do
    post("/pet", pet)
  end

  def find_pets_by_status(status) do
    get(Tesla.build_url("/pet/findByStatus", status: status))
  end

  def find_pets_by_tags(tags) do
    get(Tesla.build_url("/pet/findByTags", tags: tags))
  end

  def get_pet_by_id(petId) do
    get("/pet/#{petId}")
  end

  def upload_file(petId, body, additional_metadata) do
    post(
      Tesla.build_url("/pet/#{petId}/uploadImage", additional_metadata: additional_metadata),
      body
    )
  end

  def get_inventory do
    get("/store/inventory")
  end

  def place_order(%PetStore.Order{} = order) do
    post("/store/order", order)
  end

  def get_order_by_id(orderId) do
    get("/store/order/#{orderId}")
  end

  def create_user(%PetStore.User{} = user) do
    post("/user", user)
  end

  def create_users_with_list_input(users) do
    post("/user/createWithList", users)
  end

  def login_user(username, password) do
    get(Tesla.build_url("/user/login", username: username, password: password))
  end

  def logout_user do
    get("/user/logout")
  end

  def get_user_by_name(username) do
    get("/user/#{username}")
  end
end

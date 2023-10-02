defmodule PetStore do
  @moduledoc false
  use Tesla

  plug(Tesla.Middleware.BaseUrl, "https://petstore3.swagger.io/api/v3")

  def add_pet(%PetStore.Pet{} = pet) do
    url = "/pet"
    post(url, pet)
  end

  def find_pets_by_status(status) do
    url = Tesla.build_url("/pet/findByStatus", status: status)
    get(url)
  end

  def find_pets_by_tags(tags) do
    url = Tesla.build_url("/pet/findByTags", tags: tags)
    get(url)
  end

  def get_pet_by_id(pet_id) do
    url = "/pet/#{pet_id}"
    get(url)
  end

  def upload_file(pet_id, body, additional_metadata) do
    url = Tesla.build_url("/pet/#{pet_id}/uploadImage", additional_metadata: additional_metadata)
    post(url, body)
  end

  def get_inventory do
    url = "/store/inventory"
    get(url)
  end

  def place_order(%PetStore.Order{} = order) do
    url = "/store/order"
    post(url, order)
  end

  def get_order_by_id(order_id) do
    url = "/store/order/#{order_id}"
    get(url)
  end

  def create_user(%PetStore.User{} = user) do
    url = "/user"
    post(url, user)
  end

  def create_users_with_list_input(users) do
    url = "/user/createWithList"
    post(url, users)
  end

  def login_user(username, password) do
    url = Tesla.build_url("/user/login", username: username, password: password)
    get(url)
  end

  def logout_user do
    url = "/user/logout"
    get(url)
  end

  def get_user_by_name(username) do
    url = "/user/#{username}"
    get(url)
  end
end

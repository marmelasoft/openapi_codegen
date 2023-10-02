defmodule PetStore do
  @moduledoc false
  @req Req.new(base_url: "https://petstore3.swagger.io/api/v3")
  def add_pet(%PetStore.Pet{} = pet) do
    url = "/pet"
    Req.post!(@req, url: url, json: pet)
  end

  def find_pets_by_status(status) do
    url = "/pet/findByStatus"
    Req.get!(@req, url: url, params: [status: status])
  end

  def find_pets_by_tags(tags) do
    url = "/pet/findByTags"
    Req.get!(@req, url: url, params: [tags: tags])
  end

  def get_pet_by_id(pet_id) do
    url = "/pet/#{pet_id}"
    Req.get!(@req, url: url)
  end

  def upload_file(pet_id, body, additional_metadata) do
    url = "/pet/#{pet_id}/uploadImage"
    Req.post!(@req, url: url, json: body, params: [additional_metadata: additional_metadata])
  end

  def get_inventory do
    url = "/store/inventory"
    Req.get!(@req, url: url)
  end

  def place_order(%PetStore.Order{} = order) do
    url = "/store/order"
    Req.post!(@req, url: url, json: order)
  end

  def get_order_by_id(order_id) do
    url = "/store/order/#{order_id}"
    Req.get!(@req, url: url)
  end

  def create_user(%PetStore.User{} = user) do
    url = "/user"
    Req.post!(@req, url: url, json: user)
  end

  def create_users_with_list_input(users) do
    url = "/user/createWithList"
    Req.post!(@req, url: url, json: users)
  end

  def login_user(username, password) do
    url = "/user/login"
    Req.get!(@req, url: url, params: [username: username, password: password])
  end

  def logout_user do
    url = "/user/logout"
    Req.get!(@req, url: url)
  end

  def get_user_by_name(username) do
    url = "/user/#{username}"
    Req.get!(@req, url: url)
  end
end

defmodule PetStore.User do
  @moduledoc "Structure for User component"
  defstruct [:email, :firstName, :id, :lastName, :password, :phone, :userStatus, :username]
end
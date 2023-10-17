defmodule PetStore.User do
  @moduledoc "Structure for User component"
  @derive Jason.Encoder
  @enforce_keys [:id, :username]
  defstruct [:email, :first_name, :id, :last_name, :password, :phone, :user_status, :username]
end

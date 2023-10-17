defmodule PetStore.Customer do
  @moduledoc "Structure for Customer component"
  @derive Jason.Encoder
  @enforce_keys []
  defstruct [:address, :id, :username]
end

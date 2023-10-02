defmodule PetStore.Customer do
  @moduledoc "Structure for Customer component"
  @derive Jason.Encoder
  defstruct [:address, :id, :username]
end

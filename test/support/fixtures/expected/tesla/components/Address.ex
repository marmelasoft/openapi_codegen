defmodule PetStore.Address do
  @moduledoc "Structure for Address component"
  @derive Jason.Encoder
  @enforce_keys []
  defstruct [:city, :state, :street, :zip]
end

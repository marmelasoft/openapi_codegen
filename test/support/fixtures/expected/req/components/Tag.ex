defmodule PetStore.Tag do
  @moduledoc "Structure for Tag component"
  @derive Jason.Encoder
  @enforce_keys []
  defstruct [:id, :name]
end

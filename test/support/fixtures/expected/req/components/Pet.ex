defmodule PetStore.Pet do
  @moduledoc "Structure for Pet component"
  @derive Jason.Encoder
  @enforce_keys [:name, :photo_urls]
  defstruct [:category, :id, :name, :photo_urls, :status, :tags]
end

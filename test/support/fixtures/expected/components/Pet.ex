defmodule PetStore.Pet do
  @moduledoc "Structure for Pet component"
  @derive Jason.Encoder
  defstruct [:category, :id, :name, :photo_urls, :status, :tags]
end

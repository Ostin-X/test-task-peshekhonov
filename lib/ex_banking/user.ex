defmodule ExBanking.User do
  @enforce_keys [:name]
  defstruct [:name, balances: %{}]
end

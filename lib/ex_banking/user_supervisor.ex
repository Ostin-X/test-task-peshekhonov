defmodule ExBanking.UserSupervisor do
  @moduledoc """
  UserSupervisor module for creating users and their servers at the same time
  """
  use DynamicSupervisor

  alias ExBanking.UserServer

  def start_link(_) do
    DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @impl true
  def init(:ok) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  @spec start_user(name :: String.t()) :: {:ok, pid}
  def start_user(name) do
    spec = %{
      id: name,
      start: {UserServer, :start_link, [name]},
      restart: :transient,
      shutdown: 5000,
      type: :worker
    }

    DynamicSupervisor.start_child(__MODULE__, spec)
  end
end

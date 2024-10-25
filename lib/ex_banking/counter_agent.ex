defmodule ExBanking.CounterAgent do
  @moduledoc """
  CounterAgent module for counting requests per user
  """
  use Agent

  @max_ops 10

  def start_link(_), do: Agent.start_link(fn -> %{} end, name: __MODULE__)

  @spec get_count(name :: String.t()) :: integer
  def get_count(name), do: Agent.get(__MODULE__, &Map.get(&1, name, 0))

  @spec increment_or_error(name :: String.t()) :: :ok | {:error, :too_many_requests_to_user}
  def increment_or_error(name) do
    user_ops =
      Agent.get_and_update(__MODULE__, fn state ->
        Map.get_and_update(state, name, &{&1 || 0, (&1 || 0) + 1})
      end)

    case user_ops < @max_ops do
      true ->
        :ok

      false ->
        decrement(name)
        {:error, :too_many_requests_to_user}
    end
  end

  @spec decrement(name :: String.t()) :: :ok
  def decrement(name),
    do:
      Agent.update(__MODULE__, fn state ->
        Map.update(state, name, 0, &(&1 - 1))
      end)
end

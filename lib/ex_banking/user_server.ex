defmodule ExBanking.UserServer do
  @moduledoc """
  UserServer module for handling user requests and balances
  """
  use GenServer
  alias ExBanking.User
  import ExBanking.Utils

  def start_link(user), do: GenServer.start_link(__MODULE__, user, name: via_tuple(user))
  def get_balance(user, currency), do: GenServer.call(via_tuple(user), {:get_balance, currency})

  def deposit(user, amount, currency),
    do: GenServer.call(via_tuple(user), {:deposit, amount, currency})

  def withdraw(user, amount, currency),
    do: GenServer.call(via_tuple(user), {:withdraw, amount, currency})

  # Callbacks
  def init(user), do: {:ok, %{user: %User{name: user}}}

  def handle_call({:get_balance, currency}, _from, %{user: user} = state),
    do: {:reply, {:ok, get_user_balance(user, currency)}, state}

  def handle_call({:deposit, amount, currency}, _from, %{user: user} = state) do
    updated_user = %User{user | balances: update_user_balance(user, currency, amount)}

    {:reply, {:ok, Float.round(updated_user.balances[currency], 2)},
     %{state | user: updated_user}}
  end

  def handle_call({:withdraw, amount, currency}, _from, %{user: user} = state) do
    case get_user_balance(user, currency) do
      balance when balance < amount ->
        {:reply, {:error, :not_enough_money}, state}

      _balance ->
        updated_user = %User{user | balances: update_user_balance(user, currency, -amount)}

        {:reply, {:ok, Float.round(updated_user.balances[currency], 2)},
         %{state | user: updated_user}}
    end
  end
end

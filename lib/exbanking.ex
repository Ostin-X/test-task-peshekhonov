defmodule ExBanking do
  @moduledoc """
  ExBanking main module to process user creation and balance requests
  """
  alias ExBanking.{CounterAgent, UserSupervisor, UserServer, Utils}

  @spec create_user(user :: String.t()) :: :ok | {:error, :wrong_arguments | :user_already_exists}
  def create_user(name) when is_binary(name) do
    case UserSupervisor.start_user(name) do
      {:ok, _pid} -> :ok
      {:error, {:already_started, _pid}} -> {:error, :user_already_exists}
      error -> error
    end
  end

  def create_user(_), do: {:error, :wrong_arguments}

  @spec get_balance(user :: String.t(), currency :: String.t()) ::
          {:ok, balance :: number}
          | {:error, :wrong_arguments | :user_does_not_exist | :too_many_requests_to_user}
  def get_balance(user, currency) when is_binary(user) and is_binary(currency) do
    Utils.handle_operation(:get_balance, user, currency)
  end

  def get_balance(_, _), do: {:error, :wrong_arguments}

  @spec deposit(user :: String.t(), amount :: number, currency :: String.t()) ::
          {:ok, new_balance :: number}
          | {:error, :wrong_arguments | :user_does_not_exist | :too_many_requests_to_user}
  def deposit(user, amount, currency)
      when is_binary(user) and is_binary(currency) and is_number(amount) and amount > 0 do
    Utils.handle_operation(:deposit, user, currency, amount)
  end

  def deposit(_, _, _), do: {:error, :wrong_arguments}

  @spec withdraw(user :: String.t(), amount :: number, currency :: String.t()) ::
          {:ok, new_balance :: number}
          | {:error,
             :wrong_arguments
             | :user_does_not_exist
             | :not_enough_money
             | :too_many_requests_to_user}
  def withdraw(user, amount, currency)
      when is_binary(user) and is_binary(currency) and is_number(amount) and amount > 0 do
    Utils.handle_operation(:withdraw, user, currency, amount)
  end

  def withdraw(_, _, _), do: {:error, :wrong_arguments}

  @spec send(
          from_user :: String.t(),
          to_user :: String.t(),
          amount :: number,
          currency :: String.t()
        ) ::
          {:ok, from_user_balance :: number, to_user_balance :: number}
          | {:error,
             :wrong_arguments
             | :not_enough_money
             | :sender_does_not_exist
             | :receiver_does_not_exist
             | :too_many_requests_to_sender
             | :too_many_requests_to_receiver}
  def send(from_user, to_user, amount, currency)
      when is_binary(from_user) and is_binary(to_user) and is_binary(currency) and
             is_number(amount) and amount > 0 do
    with {:sender, true} <- {:sender, Utils.user_exists_or_error(from_user)},
         {:receiver, true} <- {:receiver, Utils.user_exists_or_error(to_user)},
         {:sender, :ok} <- {:sender, CounterAgent.increment_or_error(from_user)},
         {:receiver, :ok} <- {:receiver, CounterAgent.increment_or_error(to_user)},
         {:ok, {:ok, from_user_balance}} <-
           {:ok, UserServer.withdraw(from_user, amount, currency)} do
      {:ok, to_user_balance} = UserServer.deposit(to_user, amount, currency)

      {:ok, from_user_balance, to_user_balance}
      |> tap(fn _ -> CounterAgent.decrement(from_user) end)
      |> tap(fn _ -> CounterAgent.decrement(to_user) end)
    else
      error ->
        Utils.replace_user_with_role(error)
        |> tap(fn {_error, message} ->
          case message do
            :too_many_requests_to_receiver ->
              CounterAgent.decrement(from_user)

            :not_enough_money ->
              CounterAgent.decrement(from_user)
              CounterAgent.decrement(to_user)

            _ ->
              nil
          end
        end)
    end
  end

  def send(_, _, _, _), do: {:error, :wrong_arguments}
end

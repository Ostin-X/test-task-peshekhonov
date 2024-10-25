defmodule ExBanking.Utils do
  alias ExBanking.{CounterAgent, UserServer}

  @doc """
  Returns GenServer global name
  """
  @spec via_tuple(String.t()) :: {:global, {:user_server, String.t()}}
  def via_tuple(user), do: {:global, {:user_server, user}}

  @spec get_user_balance(User.t(), String.t()) :: float
  def get_user_balance(user, currency),
    do:
      Map.get(user.balances, currency, 0.0)
      |> Float.round(2)

  @spec update_user_balance(User.t(), String.t(), number) :: %{String.t() => number}
  def update_user_balance(user, currency, amount),
    do: Map.put(user.balances, currency, get_user_balance(user, currency) + amount)

  @spec user_exists_or_error(String.t()) :: true | {:error, :user_does_not_exist}
  def user_exists_or_error(user) do
    case is_pid(GenServer.whereis(via_tuple(user))) do
      true -> true
      false -> {:error, :user_does_not_exist}
    end
  end

  @doc """
  Handles :deposit, :withdraw and :get_balance operations. Accepts :get_balance with amount == :skip, to reroute command to UserServer
  """
  @spec handle_operation(
          operation :: :deposit | :withdraw | :get_balance,
          user :: String.t(),
          currency :: String.t(),
          amount :: number | nil
        ) ::
          {:ok, new_balance :: number}
          | {:error,
             :user_does_not_exist
             | :not_enough_money
             | :too_many_requests_to_user}
  def handle_operation(operation, user, currency, amount \\ nil) do
    with true <- user_exists_or_error(user),
         :ok <- CounterAgent.increment_or_error(user),
         true <- is_number(amount) do
      apply(UserServer, operation, [user, amount, currency])
      |> tap(fn _ -> CounterAgent.decrement(user) end)
    else
      false ->
        apply(UserServer, operation, [user, currency])
        |> tap(fn _ -> CounterAgent.decrement(user) end)

      error ->
        error
    end
  end

  @doc """
  Replaces user with :sender or :receiver role in error messages
  """
  @spec replace_user_with_role(
          {:sender | :receiver | atom,
           {:error, :user_does_not_exist | :too_many_requests_to_user | :not_enough_money}}
        ) ::
          {:error,
           :sender_does_not_exist
           | :receiver_does_not_exist
           | :too_many_requests_to_sender
           | :too_many_requests_to_receiver
           | :not_enough_money}
  def replace_user_with_role({role, error}) do
    case error do
      {:error, :user_does_not_exist} -> {:error, :"#{role}_does_not_exist"}
      {:error, :too_many_requests_to_user} -> {:error, :"too_many_requests_to_#{role}"}
      _ -> error
    end
  end
end

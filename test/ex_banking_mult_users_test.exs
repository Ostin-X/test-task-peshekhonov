defmodule ExBankingMultipleUsersTest do
  use ExUnit.Case, async: true

  import ExBanking

  @timeout 10_000

  setup do
    create_user("alice")
    create_user("bob")
    create_user("charlie")
    :ok

    on_exit(fn ->
      :ok = Application.stop(:ex_banking)
      :ok = Application.start(:ex_banking)
    end)
  end

  test "concurrent deposits for multiple users" do
    tasks =
      Enum.flat_map(1..10, fn _ ->
        [
          Task.async(fn -> deposit("alice", 10, "USD") end),
          Task.async(fn -> deposit("bob", 20, "USD") end)
        ]
      end)

    results = Enum.map(tasks, &Task.await(&1, @timeout))

    alice_bob_deposits =
      Enum.count(results, fn
        {:ok, _balance} -> true
        _ -> false
      end)

    assert alice_bob_deposits == 20

    {:ok, alice_balance} = get_balance("alice", "USD")
    {:ok, bob_balance} = get_balance("bob", "USD")

    assert alice_balance == 100
    assert bob_balance == 200
  end

  test "concurrent withdrawals for multiple users" do
    deposit("alice", 100, "USD")
    deposit("bob", 200, "USD")

    tasks =
      Enum.flat_map(1..10, fn _ ->
        [
          Task.async(fn -> withdraw("alice", 10, "USD") end),
          Task.async(fn -> withdraw("bob", 20, "USD") end)
        ]
      end)

    results = Enum.map(tasks, &Task.await(&1, @timeout))

    alice_bob_withdrawals =
      Enum.count(results, fn
        {:ok, _balance} -> true
        _ -> false
      end)

    assert alice_bob_withdrawals == 20

    {:ok, alice_balance} = get_balance("alice", "USD")
    {:ok, bob_balance} = get_balance("bob", "USD")

    assert alice_balance == 0
    assert bob_balance == 0
  end

  test "concurrent transfers between different users" do
    deposit("alice", 100, "USD")
    deposit("charlie", 100, "USD")

    tasks =
      Enum.flat_map(1..5, fn _ ->
        [
          Task.async(fn -> send("alice", "bob", 20, "USD") end),
          Task.async(fn -> send("charlie", "bob", 10, "USD") end)
        ]
      end)

    results = Enum.map(tasks, &Task.await(&1, @timeout))

    alice_charlie_transfers =
      Enum.count(results, fn
        {:ok, _from_balance, _to_balance} -> true
        _ -> false
      end)

    assert alice_charlie_transfers == 10

    {:ok, alice_balance} = get_balance("alice", "USD")
    {:ok, charlie_balance} = get_balance("charlie", "USD")
    {:ok, bob_balance} = get_balance("bob", "USD")

    assert alice_balance == 0
    assert charlie_balance == 50
    assert bob_balance == 150
  end
end

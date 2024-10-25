defmodule Test do
  def func do
    ExBanking.deposit("alice", 100, "USD")
    func()
  end

  def func2 do
    ExBanking.deposit("bob", 100, "USD")
    func2()
  end
end

#ExBanking.create_user("alice")
#ExBanking.create_user("bob")
#Task.async(fn -> Test.func() end)
#Task.async(fn -> Test.func2() end)

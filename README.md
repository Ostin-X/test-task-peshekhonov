
# ExBanking

ExBanking is an Elixir application designed to handle basic banking operations, such as user creation, balance inquiries,
deposits, withdrawals, and transfers between users.
The application leverages the power of concurrent processes provided by the BEAM VM, ensuring high performance and scalability.

## Table of Contents

- [Installation](#installation)
- [Usage](#usage)
  - [Creating a User](#creating-a-user)
  - [Getting a Balance](#getting-a-balance)
  - [Depositing Money](#depositing-money)
  - [Withdrawing Money](#withdrawing-money)
  - [Sending Money](#sending-money)
- [Design Overview](#design-overview)
  - [Modules](#modules)
- [Contributing](#contributing)
- [License and Disclaimer](#license-and-disclaimer)

## Installation

To use ExBanking, clone the repository and fetch the dependencies:

```sh
git clone https://github.com/yourusername/ex_banking.git
cd ex_banking
mix deps.get
```

## Usage

Run the application:

```sh
mix run --no-halt
```

You can interact with the application using the provided functions:

### Creating a User

```elixir
ExBanking.create_user("Alice")
# => :ok
```

### Getting a Balance

```elixir
ExBanking.get_balance("Alice", "USD")
# => {:ok, 0.0}
```

### Depositing Money

```elixir
ExBanking.deposit("Alice", 100, "USD")
# => {:ok, 100.0}
```

### Withdrawing Money

```elixir
ExBanking.withdraw("Alice", 50, "USD")
# => {:ok, 50.0}
```

### Sending Money

```elixir
ExBanking.create_user("Bob")
ExBanking.send("Alice", "Bob", 25, "USD")
# => {:ok, 25.0, 25.0}
```

## Design Overview

### Modules

- **ExBanking**: Main module that provides the public API for creating users and processing banking operations.
- **ExBanking.Application**: Starts the application and its supervision tree.
- **ExBanking.CounterAgent**: Manages the number of requests per user to prevent overload.
- **ExBanking.User**: Defines the user struct.
- **ExBanking.UserServer**: A GenServer responsible for handling individual user requests and managing balances.
- **ExBanking.UserSupervisor**: A DynamicSupervisor that supervises UserServer processes.
- **ExBanking.Utils**: Utility functions used across the application.

### Concurrency

- Each user is managed by an individual `UserServer` process, allowing concurrent operations.
- `CounterAgent` limits the number of simultaneous operations per user to prevent overloading.

### Fault Tolerance

- Processes are supervised by `UserSupervisor`, ensuring that user processes can be restarted in case of failure.

## Contributing

Contributions are welcome! Please fork the repository and submit pull requests.

## License and Disclaimer

This project is a part of a top-secret, future trillion-dollar system that will rule the world. Mu Ha Ha Ha!

Subject for NDA, DND, NBA, F1, UCI, HMM4 and WotLK.

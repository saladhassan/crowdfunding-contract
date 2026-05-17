# Multi-Campaign Crowdfunding Protocol

A decentralized crowdfunding smart contract built with Solidity and tested using Foundry.

This protocol allows users to create fundraising campaigns, receive ETH donations, withdraw successful funding, and refund contributors if campaigns fail.

---

# Features

* Create multiple crowdfunding campaigns
* Donate ETH to campaigns
* Automatic campaign tracking using unique IDs
* Secure owner withdrawals after successful funding
* Contributor refunds for failed campaigns
* Reentrancy protection and access control
* Fully tested using Foundry

---

# Smart Contract Concepts Used

* Structs
* Enums
* Nested mappings
* Events
* Modifiers
* Payable functions
* Reentrancy guard
* State management

---

# Testing

The project includes tests for:

* Campaign creation
* Donations
* Invalid transactions
* Withdrawals
* Refunds
* Access control
* Deadline validation
* Multi-user accounting

Run tests with:

```bash
forge test -vv
```

---

# Tech Stack

* Solidity ^0.8.20
* Foundry
* forge-std/Test.sol

---

# Project Structure

```text
src/
 └── crowdfunding.sol

 test/
 └── crowdfunding.t.sol
```

---

# Installation

```bash
git clone <your-repository-url>
cd <repository-name>
forge build
forge test
```

---

# Security

This project includes:

* Access control validation
* Reentrancy protection
* Deadline enforcement
* Refund protection
* Double-withdraw prevention

---

# Author

Built by Hassan Salad as part of a smart contract engineering and security learning journey.

---

# License

MIT License

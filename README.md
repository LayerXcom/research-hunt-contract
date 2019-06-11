# Research Hunt SmartContract Project

> Research Hunt SmartContract Project with Truffle with Vyper

## Setup

### 1. Install Vyper
Create a virtual environment and install Vyper according to [Vyper documentation](https://vyper.readthedocs.io/en/v0.1.0-beta.8/installing-vyper.html)

### 2. Start up a local developmenet ethereum node.
Start up Ganache with 9545 port and import private keys to MetaMask.

```
$ truffle develop
```

### 3. Compile and Deploy

```
truffle(develop)> migrate
```

or 

```
truffle(develop)> compile
```

```
truffle(develop)> deploy
```
# @dev Implementation of Base Escrow Contract.
# @author Jun Katagiri (@akinama)

#
# Events
#
Deposited: event({payee: indexed(address), weiAmount: wei_value})
Withdrawn: event({payee: indexed(address), weiAmount: wei_value})
PrimaryTransferred: event({recipient: address})

#
# State Variables
#
# The EOA of this contract
primary: address

# Deposits
deposits: map(address, wei_value)

#
# Public Functions
#
@public
def __init__():
    assert self.primary == ZERO_ADDRESS
    self.primary = msg.sender
    assert not self.primary == ZERO_ADDRESS

@public
def initialize():
    assert self.primary == ZERO_ADDRESS
    self.primary = msg.sender
    assert not self.primary == ZERO_ADDRESS

@public
@constant
def getPrimaryAddress() -> address:
    return self.primary

@public
@constant
def depositsOf(_payee: address) -> wei_value:
    return self.deposits[_payee]

@public
@payable
def deposit(_payee: address):
    assert self.primary == msg.sender
    assert msg.value > 0
    amount: wei_value = msg.value
    self.deposits[_payee] = self.deposits[_payee] + amount
    log.Deposited(_payee, amount)

@public
@payable
def withdraw(_payee: address):
    assert self.primary == msg.sender
    assert self.deposits[_payee] > 0
    payment: wei_value = self.deposits[_payee]
    self.deposits[_payee] = 0
    send(_payee, payment)
    log.Withdrawn(_payee, payment)

@public
@payable
def withdrawAmount(_payee: address, _amount: wei_value):
    assert self.primary == msg.sender
    assert _amount <= self.deposits[_payee]
    payment: wei_value = _amount
    self.deposits[_payee] = self.deposits[_payee] - _amount
    send(_payee, payment)
    log.Withdrawn(_payee, payment)

@public
def transferPrimary(_recipient: address):
    assert self.primary == msg.sender
    log.PrimaryTransferred(_recipient)
    self.primary = _recipient



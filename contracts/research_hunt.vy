# @dev Implementation of Research Hunt Contracts.
# @author Jun Katagiri (@akinama)

#
# Structs
#
struct ResearchRequest:
    owner: address
    deposit: wei_value
    payout: wei_value
    createdAt: timestamp
    applicationEndAt: timestamp
    submissionEndAt: timestamp
    isCompleted: bool

#
# Events
#
RequestCreated: event({owner: indexed(address), weiAmount: wei_value, createdAt: timestamp, applicationEndAt: timestamp, submissionEndAt: timestamp})
Deposited: event({payee: indexed(address), weiAmount: wei_value})
Withdrawn: event({payee: indexed(address), weiAmount: wei_value})
OwnerTransferred: event({transfer: address})

#
# Constants
#
# 14 days
DEFAULT_REFUNDABLE_TIMESPAN: constant(timedelta) = 1209600

#
# State Variables
#
# The EOA of this contract owner
owner: address

# Deposits
deposits: map(address, wei_value)

# Research Hunt Struct Mappings
requests: map(uint256, ResearchRequest)

# Refundable timespan
refundableTimespan: timedelta

#
# Constructor
#
@public
def __init__():
    self.owner = msg.sender
    self.refundableTimespan = DEFAULT_REFUNDABLE_TIMESPAN

#
# Administration Functions
#
@public
def transferOwner(_transfer: address):
    # Guard 1: only owner
    assert self.owner == msg.sender

    # the owner make change to transfer address
    self.owner = _transfer

    # Event
    log.OwnerTransferred(_transfer)

@public
def setRefundableTimespan(_refundableTimespan: timedelta):
    # Guard 1: only owner
    assert self.owner == msg.sender

    # Set refundable timespan (cannot assign by bug)
    # self.refundableTimespan = _refundableTimespan

@public
@constant
def getOwnerAddress() -> address:
    return self.owner

#
# Research Hunt Functions
#
@public
@constant
def depositsOf(_payee: address) -> wei_value:
    return self.deposits[_payee]

@public
@payable
def createResearchRequest(_requestId: uint256, _applicationEndAt: timestamp, _submissionEndAt: timestamp):
    # Guard 1: whether the deposit amount is greater than 0 wei
    assert msg.value > 0

    # Guard 2: whether the timestamps are correctly
    assert block.timestamp < _applicationEndAt and _applicationEndAt < _submissionEndAt

    # Guard 3: whether the request ID has already created
    assert self.requests[_requestId].owner == ZERO_ADDRESS

    # Create research request
    self.requests[_requestId] = ResearchRequest({
        owner: msg.sender,
        deposit: msg.value,
        payout: 0,
        createdAt: block.timestamp,
        applicationEndAt: _applicationEndAt,
        submissionEndAt: _submissionEndAt,
        isCompleted: False
    })

    # Escrow
    self.deposits[msg.sender] = self.deposits[msg.sender] + msg.value

    # Event
    log.RequestCreated(
        self.requests[_requestId].owner,
        self.requests[_requestId].deposit,
        self.requests[_requestId].createdAt,
        self.requests[_requestId].applicationEndAt,
        self.requests[_requestId].submissionEndAt)

@public
@payable
def addDepositToRequest(_requestId: uint256):
    # Guard 1: whether the deposit amount is greater than 0 wei
    assert msg.value > 0

    # Guard 2: whether the request ID is same as sender address
    assert self.requests[_requestId].owner == msg.sender

    # Update the research request deposited amount
    self.requests[_requestId].deposit = self.requests[_requestId].deposit + msg.value

    # Escrow
    self.deposits[msg.sender] = self.deposits[msg.sender] + msg.value

    # Event
    log.Deposited(msg.sender, self.requests[_requestId].deposit)

@public
@payable
def distribute(_requestId: uint256, _receiver: address, _amount: wei_value):
    # Guard 1: whether the distributing amount is greater than 0 wei
    assert _amount > 0

    # Guard 2: whether the address is not sender address
    assert not msg.sender == _receiver

    # Guard 3: whether the current timestamp has gone over the submission end at
    assert block.timestamp > self.requests[_requestId].submissionEndAt

    # Guard 4: whether the request ID is same as sender address
    assert self.requests[_requestId].owner == msg.sender

    # Guard 5: whether the deposited amount is greater than or equal the distributed
    assert _amount <= self.requests[_requestId].deposit

    # Guard 6: whether the total deposited amount is greater than or equal the distributed
    assert _amount <= self.deposits[msg.sender]

    # Update the research request deposited amount
    self.requests[_requestId].deposit = self.requests[_requestId].deposit - _amount

    # Update the research request paid out amount
    self.requests[_requestId].payout = self.requests[_requestId].payout + _amount

    # Send the amount to the receiver address
    send(_receiver, _amount)

    # Event
    log.Withdrawn(msg.sender, self.requests[_requestId].deposit)

@public
@payable
def refund(_requestId: uint256):
    # Guard 1: whether the address is not sender address
    assert not msg.sender == self.requests[_requestId].owner

    # Guard 2: whether the current timestamp has gone over the submission end at
    assert block.timestamp > self.requests[_requestId].submissionEndAt + self.refundableTimespan

    # Update the research request payout
    self.requests[_requestId].payout = self.requests[_requestId].deposit

    # Update the research request completed flag
    self.requests[_requestId].isCompleted = True

    # Send the amount to the receiver address
    send(msg.sender, self.requests[_requestId].payout)

    # Event
    log.Withdrawn(msg.sender, self.requests[_requestId].deposit)

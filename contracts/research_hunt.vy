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

#
# Events
#
RequestCreated: event({owner: indexed(address), weiAmount: wei_value})
Deposited: event({payee: indexed(address), weiAmount: wei_value})
Withdrawn: event({payee: indexed(address), weiAmount: wei_value})
OwnerTransferred: event({transfer: address})

#
# State Variables
#
# The EOA of this contract owner
owner: address

# Deposits
deposits: map(address, wei_value)

# Research Hunt Struct Mappings
requests: map(uint256, ResearchRequest)

#
# Constructor
#
@public
def __init__():
    self.owner = msg.sender

#
# Escrow Functions
#
@public
@constant
def getOwnerAddress() -> address:
    return self.owner

@public
@constant
def depositsOf(_payee: address) -> wei_value:
    return self.deposits[_payee]

@public
def transferOwner(_transfer: address):
    # Guard 1: the sender address should be same as the owner address
    assert self.owner == msg.sender

    # the owner make change to transfer address
    self.owner = _transfer

    # Event
    log.OwnerTransferred(_transfer)

#
# Research Hunt Functions
#
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
        submissionEndAt: _submissionEndAt
    })

    # Escrow
    self.deposits[msg.sender] = self.deposits[msg.sender] + msg.value

    # Event
    log.RequestCreated(msg.sender, msg.value)

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

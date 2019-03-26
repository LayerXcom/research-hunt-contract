# @dev Implementation of Research Hunt Contracts.
# @author Jun Katagiri (@akinama)

#
# Structs
#
struct ResearchRequest:
    owner: address
    deposit: wei_value
    payout: wei_value

#
# External Contracts
#
contract Escrow:
    def initialize(): modifying
    def getPrimaryAddress() -> address: constant
    def depositsOf(_payee: address) -> uint256(wei): constant
    def deposit(_payee: address, _value: wei_value): modifying
    def withdraw(_payee: address): modifying
    def withdrawAmount(_payee: address, _amount: uint256(wei)): modifying
    def transferPrimary(_recipient: address): modifying

#
# Events
#
RequestCreated: event({owner: indexed(address), weiAmount: wei_value})
Deposited: event({payee: indexed(address), weiAmount: wei_value})
Withdrawn: event({payee: indexed(address), weiAmount: wei_value})

#
# Constants
#
RESEARCH_REQUEST_LIST_SIZE: constant(int128) = 65536

#
# State Variables
#
# Escrow External Contract Address
escrow: address

# Research Hunt Struct Mappings
requests: ResearchRequest[RESEARCH_REQUEST_LIST_SIZE]

#
# Public Functions
#
@public
def __init__(_escrowTemplate: address):
    assert not _escrowTemplate == ZERO_ADDRESS
    self.escrow = create_with_code_of(_escrowTemplate)
    Escrow(self.escrow).initialize()

@public
@payable
def createResearchRequest(_requestId: int128):
    assert _requestId < RESEARCH_REQUEST_LIST_SIZE
    assert self.requests[_requestId].owner == ZERO_ADDRESS
    self.requests[_requestId] = ResearchRequest({owner: msg.sender, deposit: msg.value, payout: 0})
    Escrow(self.escrow).deposit(msg.sender, msg.value)
    log.RequestCreated(msg.sender, msg.value)

@public
@payable
def addDepositToRequest(_requestId: int128):
    assert _requestId < RESEARCH_REQUEST_LIST_SIZE
    assert self.requests[_requestId].owner == msg.sender
    self.requests[_requestId].deposit += msg.value
    Escrow(self.escrow).deposit(msg.sender, msg.value)
    log.Deposited(msg.sender, self.requests[_requestId].deposit)

@public
@payable
def distribute(_requestId: int128, _receiver: address, _amount: wei_value):
    assert _requestId < RESEARCH_REQUEST_LIST_SIZE
    assert self.requests[_requestId].owner == msg.sender
    assert _amount <= self.requests[_requestId].deposit
    Escrow(self.escrow).withdrawAmount(msg.sender, _amount)
    self.requests[_requestId].deposit -= _amount
    send(_receiver, _amount)
    log.Withdrawn(msg.sender, _amount)
    log.Withdrawn(msg.sender, self.requests[_requestId].deposit)

@public
@constant
def depositsOf() -> wei_value:
    return Escrow(self.escrow).depositsOf(msg.sender)

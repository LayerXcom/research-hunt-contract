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
    def deposit(_payee: address): modifying
    def withdraw(_payee: address): modifying
    def withdrawAmount(_payee: address, _amount: uint256(wei)): modifying
    def transferPrimary(_recipient: address): modifying

#
# Events
#
RequestCreated: event({owner: indexed(address), count: uint256})
Deposited: event({payee: indexed(address), weiAmount: wei_value})
Withdrawn: event({payee: indexed(address), weiAmount: wei_value})

#
# Constants
#
RESEARCH_REQUEST_LIST_SIZE: constant(uint256) = 2048

#
# State Variables
#
# Escrow External Contract Address
escrow: address

# Research Hunt Struct Mappings
requests: map(address, ResearchRequest[RESEARCH_REQUEST_LIST_SIZE])

currentSizes: map(address, uint256)


#
# Public Functions
#
@public
def __init__(_escrowTemplate: address):
    assert not _escrowTemplate == ZERO_ADDRESS
    self.escrow = create_with_code_of(_escrowTemplate)
    Escrow(self.escrow).initialize()

@public
def createResearchRequest():
    for i in range(RESEARCH_REQUEST_LIST_SIZE):
        if self.requests[msg.sender][i].owner == ZERO_ADDRESS:
            self.currentSizes[msg.sender] += 1
            self.requests[msg.sender][i] = ResearchRequest({owner: msg.sender, deposit: 0, payout: 0})
            log.RequestCreated(msg.sender, self.currentSizes[msg.sender])
            break

@public
@constant
def getResearchRequestsByAddress() -> address:
    return msg.sender

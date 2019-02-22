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
            break

@public
@constant
def getResearchRequestsByAddress() -> address:
    return msg.sender

@public
@constant
def ecrecoverSig(_hash: bytes32, _sig: bytes[65]) -> address:
    """
    @dev Recover signer address from a message by using their signature
    @param _hash bytes32 message, the hash is the signed message. What is recovered is the signer address.
    @param _sig bytes signature, the signature is generated using web3.eth.sign()
    """
    if len(_sig) != 65:
        return ZERO_ADDRESS
    # ref. https://gist.github.com/axic/5b33912c6f61ae6fd96d6c4a47afde6d
    # The signature format is a compact form of:
    # {bytes32 r}{bytes32 s}{uint8 v}
    r: uint256 = extract32(_sig, 0, type=uint256)
    s: uint256 = extract32(_sig, 32, type=uint256)
    v: int128 = convert(slice(_sig, start=64, len=1), int128)
    # Version of signature should be 27 or 28, but 0 and 1 are also possible versions.
    # geth uses [0, 1] and some clients have followed. This might change, see:x
    # https://github.com/ethereum/go-ethereum/issues/2053
    if v < 27:
        v += 27
    if v in [27, 28]:
        return ecrecover(_hash, convert(v, uint256), r, s)
    return ZERO_ADDRESS

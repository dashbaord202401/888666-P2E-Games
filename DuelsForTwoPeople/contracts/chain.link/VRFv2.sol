// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

contract VRFv2 is VRFConsumerBaseV2 {
  VRFCoordinatorV2Interface COORDINATOR;

  event RandomNumberIsReadyForDuel(uint256 duelId, uint256 rundomNumber);

  // configuration for network
  uint64 s_subscriptionId;

  address vrfCoordinator = 0x2Ca8E0C643bDe4C2E08ab1fA0da3401AdAD7734D; //settings for the network
  bytes32 keyHash = 0x79d3d8832d904592c0bf9818b621522c988bb8b0c05cdc3b15aea1b6e8db0c15; //settings for the network
  
  uint32 callbackGasLimit = 100000;
  uint16 requestConfirmations = 3;
  uint32 numWords =  1;

  // storage variables
  mapping(uint256 => RandomNumber) s_duelIdToNumber;
  mapping(uint256 => uint256) s_requestIdToDuelId;

  struct RandomNumber {
    uint256 number;
    bool hasSet;
  }

  constructor(uint64 subscriptionId) VRFConsumerBaseV2(vrfCoordinator) {
    COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
    s_subscriptionId = subscriptionId;
  }

  // Assumes the subscription is funded sufficiently.
  function requestRandomWords(uint256 duelId) external returns (uint256) {
    uint256 requestId = COORDINATOR.requestRandomWords(
      keyHash,
      s_subscriptionId,
      requestConfirmations,
      callbackGasLimit,
      numWords
    );

    s_requestIdToDuelId[requestId] = duelId;

    return requestId; // Return the requestId to the requester.
  }

  function fulfillRandomWords(
      uint256 requestId,
      uint256[] memory randomWords
    ) internal override {
    require(!s_duelIdToNumber[s_requestIdToDuelId[requestId]].hasSet, "The number was set already");

    s_duelIdToNumber[s_requestIdToDuelId[requestId]].number = randomWords[0];
    s_duelIdToNumber[s_requestIdToDuelId[requestId]].hasSet = true;

    emit RandomNumberIsReadyForDuel(s_requestIdToDuelId[requestId], randomWords[0]);
  }

  function getRandomNumberByDuelID(uint256 duelId) external view returns (uint256, bool) {
    return (s_duelIdToNumber[duelId].number, s_duelIdToNumber[duelId].hasSet);
  }
}
//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./CryptStarter.sol";

contract TestCryptStarter is CryptStarter {
    function setCampaignStatus(uint256 _index, CampaignStatus _status) public {
        campaigns[_index].status = _status;
    }
}

pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../library/ECDSA.sol";
import "../library/EIP712.sol";
import "../interface/ISecondLiveBean.sol";

/**
 * @title TokenClaim
 * @author SecondLive Protocol
 *
 * Campaign contract 
    that allows privileged DAOs to initiate campaigns for members to 
    claim SecondLiveNFTs.
 */
contract TaskClaim is EIP712, Ownable, ReentrancyGuard {
    bool private initialized;

    address public signer;

    mapping(uint256 => bool) public isClaimed;

    event UpdateSigner(address signer);

    event EventClaim(
        address _tokenAddress,
        uint256 _dummyId,
        address _mintTo,
        uint256 _beanAmount
    );

    function initialize(address _owner, address _signer) external {
        require(!initialized, "initialize: Already initialized!");
        _transferOwnership(_owner);
        eip712Initialize("SecondLive", "1.0.0");
        signer = _signer;
        initialized = true;
    }

    function claimHash(
        address _tokenAddress,
        uint256 _dummyId,
        address _to,
        uint256 _amount
    ) internal view returns (bytes32) {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256(
                            "Claim(address tokenAddress,uint256 dummyId,address mintTo,uint256 amount)"
                        ),
                        _tokenAddress,
                        _dummyId,
                        _to,
                        _amount
                    )
                )
            );
    }

    function verifySignature(
        bytes32 hash,
        bytes calldata signature
    ) internal view returns (bool) {
        return ECDSA.recover(hash, signature) == signer;
    }

    function setManager(address _signer) external onlyOwner {
        signer = _signer;
        emit UpdateSigner(_signer);
    }

    function claim(
        address _tokenAddress,
        uint256 _dummyId,
        address _mintTo,
        uint256 _amount,
        bytes calldata _signature
    ) external nonReentrant {
        require(!isClaimed[_dummyId], "Already Claimed!");

        require(
            verifySignature(
                claimHash(_tokenAddress, _dummyId, _mintTo, _amount),
                _signature
            ),
            "Invalid signature"
        );
        isClaimed[_dummyId] = true;

        IERC20(_tokenAddress).transfer(msg.sender, _amount);

        emit EventClaim(_tokenAddress, _dummyId, _mintTo, _amount);
    }
}

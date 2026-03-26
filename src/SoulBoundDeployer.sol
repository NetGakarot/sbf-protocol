// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.19;

import "./SoulBoundToken.sol";
import "./DepositPool.sol";
import "./ClaimPool.sol";

/**
 * @title SoulBoundDeployer
 * @notice Atomic deployment and configuration of complete SoulBound Finance system
 * @dev Deploys all contracts, links them, configures tokens, and transfers ownership
 *      in a single transaction. Controller role goes to msg.sender for multisig setup.
 * @custom:security-contact security@soulbound.finance
 */
contract SoulBoundDeployer {
    // Deployment state
    address public sbtContract;
    address public depositPool;
    address payable public claimPool;
    address public protocolTreasury;
    address public gasManager;

    // Metadata
    uint256 public deployedAt;
    string public constant VERSION = "2.0.0";
    uint256 public immutable chainId;

    // Events
    event SystemDeployed(
        address indexed sbt,
        address indexed deposit,
        address indexed claim,
        address protocolTreasury,
        address gasManager,
        uint256 timestamp
    );
    event TokensConfigured(address[] tokens);

    // Errors
    error InvalidAddress();
    error DeploymentFailed();
    error LinkingFailed();
    error HandoffFailed();
    error AlreadyDeployed();

    constructor() {
        chainId = block.chainid;
    }

    /**
     * @notice Deploy complete SoulBound Finance system atomically
     * @param _protocolTreasury Address to receive protocol fees
     * @param _gasManager Address that manages gas fund for DeFi operations
     * @param _eulaHash Initial EULA hash for SBT minting gate
     * @param _tokens ERC-20 token addresses to whitelist (ETH is automatic)
     * @return _sbt SoulBoundToken address
     * @return _deposit DepositPool address
     * @return _claim ClaimPool address
     *
     * @dev Controller role for SBT and DepositPool goes to msg.sender.
     *      Operator role for ClaimPool goes to msg.sender.
     *      Transfer these to a multisig post-deployment.
     */
    function deploySystem(
        address _protocolTreasury,
        address _gasManager,
        bytes32 _eulaHash,
        address[] calldata _tokens
    ) external returns (
        address _sbt,
        address _deposit,
        address _claim
    ) {
        if (sbtContract != address(0)) revert AlreadyDeployed();
        if (_protocolTreasury == address(0) || _gasManager == address(0)) revert InvalidAddress();
        if (_eulaHash == bytes32(0)) revert InvalidAddress();

        protocolTreasury = _protocolTreasury;
        gasManager = _gasManager;
        deployedAt = block.timestamp;

        SoulBoundToken sbt = new SoulBoundToken(address(this));
        if (address(sbt) == address(0)) revert DeploymentFailed();

        DepositPool deposit = new DepositPool(address(sbt), address(this));
        if (address(deposit) == address(0)) revert DeploymentFailed();

        ClaimPool claim = new ClaimPool();
        if (address(claim) == address(0)) revert DeploymentFailed();

        sbtContract = address(sbt);
        depositPool = address(deposit);
        claimPool = payable(address(claim));

        if (!_linkContracts(sbt, deposit, claim, _protocolTreasury, _gasManager, _eulaHash)) {
            revert LinkingFailed();
        }

        for (uint256 i = 0; i < _tokens.length;) {
            if (_tokens[i] != address(0)) {
                deposit.addToken(_tokens[i]);
            }
            unchecked { ++i; }
        }

        if (!_handoffRoles(sbt, deposit, claim, msg.sender)) {
            revert HandoffFailed();
        }

        emit SystemDeployed(
            sbtContract,
            depositPool,
            claimPool,
            _protocolTreasury,
            _gasManager,
            block.timestamp
        );
        emit TokensConfigured(_tokens);

        return (sbtContract, depositPool, claimPool);
    }

    function _linkContracts(
        SoulBoundToken sbt,
        DepositPool deposit,
        ClaimPool claim,
        address _protocolTreasury,
        address _gasManager,
        bytes32 _eulaHash
    ) internal returns (bool) {
        // SBT → DepositPool link
        try sbt.setDepositPool(address(deposit)) {} catch { return false; }

        // Set EULA on SBT
        try sbt.setEulaHash(_eulaHash) {} catch { return false; }

        // DepositPool → ClaimPool + Treasury
        try deposit.setClaimPool(address(claim)) {} catch { return false; }
        try deposit.setProtocolTreasury(_protocolTreasury) {} catch { return false; }

        // ClaimPool configuration
        try claim.setDepositPool(address(deposit)) {} catch { return false; }
        try claim.setGasManager(_gasManager) {} catch { return false; }

        return true;
    }

    function _handoffRoles(
        SoulBoundToken sbt,
        DepositPool deposit,
        ClaimPool claim,
        address newOwner
    ) internal returns (bool) {
        try sbt.transferController(newOwner) {} catch { return false; }
        try deposit.transferController(newOwner) {} catch { return false; }
        try claim.changeOperator(newOwner) {} catch { return false; }

        return true;
    }

    // ─── View Functions ────────────────────────────────────────────────

    function getDeploymentInfo() external view returns (
        address sbt,
        address deposit,
        address claim,
        address treasury,
        address manager,
        uint256 timestamp,
        string memory ver,
        uint256 chain,
        bool isLinked
    ) {
        return (
            sbtContract,
            depositPool,
            claimPool,
            protocolTreasury,
            gasManager,
            deployedAt,
            VERSION,
            chainId,
            _isSystemLinked()
        );
    }

    function _isSystemLinked() internal view returns (bool) {
        if (sbtContract == address(0) || depositPool == address(0) || claimPool == address(0)) {
            return false;
        }

        SoulBoundToken sbt = SoulBoundToken(sbtContract);
        if (sbt.depositPoolContract() != depositPool || !sbt.isInitialized()) return false;

        DepositPool deposit = DepositPool(payable(depositPool));
        (bool depositConfigured,,) = deposit.getConfiguration();
        if (!depositConfigured) return false;

        ClaimPool claim = ClaimPool(payable(claimPool));
        if (claim.depositPool() != depositPool || claim.gasManager() != gasManager) return false;

        return true;
    }

    function validateDeployment() external view returns (
        bool isValid,
        string[] memory issues
    ) {
        string[] memory tempIssues = new string[](10);
        uint256 issueCount = 0;

        if (sbtContract == address(0)) {
            tempIssues[issueCount++] = "SBT not deployed";
        }
        if (depositPool == address(0)) {
            tempIssues[issueCount++] = "DepositPool not deployed";
        }
        if (claimPool == address(0)) {
            tempIssues[issueCount++] = "ClaimPool not deployed";
        }

        if (sbtContract != address(0) && depositPool != address(0)) {
            SoulBoundToken sbt = SoulBoundToken(sbtContract);
            if (sbt.depositPoolContract() != depositPool) {
                tempIssues[issueCount++] = "SBT not linked to DepositPool";
            }
            if (sbt.currentEulaHash() == bytes32(0)) {
                tempIssues[issueCount++] = "EULA hash not set on SBT";
            }
        }

        if (depositPool != address(0)) {
            DepositPool deposit = DepositPool(payable(depositPool));
            (bool configured,,) = deposit.getConfiguration();
            if (!configured) {
                tempIssues[issueCount++] = "DepositPool not fully configured";
            }
        }

        if (claimPool != address(0)) {
            ClaimPool claim = ClaimPool(payable(claimPool));
            if (claim.depositPool() != depositPool) {
                tempIssues[issueCount++] = "ClaimPool not linked to DepositPool";
            }
            if (claim.gasManager() == address(0)) {
                tempIssues[issueCount++] = "ClaimPool gas manager not set";
            }
        }

        string[] memory finalIssues = new string[](issueCount);
        for (uint256 i = 0; i < issueCount; i++) {
            finalIssues[i] = tempIssues[i];
        }

        return (issueCount == 0, finalIssues);
    }

    function getSystemConfiguration() external view returns (
        address[3] memory contracts,
        address[2] memory addresses,
        uint256[2] memory metadata
    ) {
        return (
            [sbtContract, depositPool, claimPool],
            [protocolTreasury, gasManager],
            [deployedAt, chainId]
        );
    }
}

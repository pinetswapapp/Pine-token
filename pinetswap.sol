// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract PinetSwap {

    // ============================================================
    // TOKEN INFORMATION
    // ============================================================

    string public constant name = "PinetSwap";
    string public constant symbol = "PINE";
    uint8 public constant decimals = 18;

    uint256 public constant MAX_SUPPLY = 100_000_000 * 10 ** 18;

    uint256 private _totalSupply;


    // ============================================================
    // ALLOCATIONS
    // ============================================================

    uint256 public constant MARKETING_ALLOCATION =
        10_000_000 * 10 ** 18;

    uint256 public constant LIQUIDITY_ALLOCATION =
        10_000_000 * 10 ** 18;

    uint256 public constant REWARDS_ALLOCATION =
        5_000_000 * 10 ** 18;

    uint256 public constant TEAM_ALLOCATION =
        10_000_000 * 10 ** 18;

    uint256 public constant ECOSYSTEM_ALLOCATION =
        7_000_000 * 10 ** 18;

    uint256 public constant TREASURY_ALLOCATION =
        5_000_000 * 10 ** 18;

    uint256 public constant COMMUNITY_ALLOCATION =
        3_000_000 * 10 ** 18;

    uint256 public constant BURN_RESERVE =
        50_000_000 * 10 ** 18;


    // ============================================================
    // PINE WALLETS
    // ============================================================

    address public constant MARKETING_WALLET =
        0xc414F8d7208228E0F977b1fC8b61b32898788822;

    address public constant LIQUIDITY_WALLET =
        0xb62f0Ffa1daA71e029a45A135cf817d632B27E7a;

    address public constant REWARDS_WALLET =
        0x546f5663522D8F1cbF8F463A94F65384668B797d;

    address public constant TEAM_WALLET =
        0x112d66829EbD8D1941a8070b9E8339a14B541824;

    address public constant ECOSYSTEM_WALLET =
        0xD853B346f7de04C05192602C0a7f8FA486e6eEb8;

    address public constant TREASURY_WALLET =
        0xc5015fD7a277DD73A27Ac5a2d93c989Ad0c403Fa;

    address public constant COMMUNITY_WALLET =
        0x4cad0CEb8bE424855eFBDB4Ef6b637aE0a94aa2A;


    // ============================================================
    // ERC20 STORAGE
    // ============================================================

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256))
        private _allowances;


    // ============================================================
    // TIME LOCKS
    // ============================================================

    uint256 public immutable deploymentTime;

    uint256 public immutable teamUnlockTime;

    uint256 public immutable burnUnlockTime;

    uint256 public immutable reserveCliffTime;

    uint256 public immutable reserveEndTime;


    // ============================================================
    // RELEASE TRACKING
    // ============================================================

    bool public teamReleased;

    bool public burnReserveExecuted;

    uint256 public ecosystemReleased;

    uint256 public treasuryReleased;

    uint256 public communityReleased;


    // ============================================================
    // EVENTS
    // ============================================================

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 value
    );

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    event TeamReleased(
        uint256 amount
    );

    event ReserveReleased(
        uint256 ecosystemAmount,
        uint256 treasuryAmount,
        uint256 communityAmount
    );

    event BurnReserve(
        uint256 amount
    );


    // ============================================================
    // CONSTRUCTOR
    // ============================================================

    constructor() {

        deploymentTime = block.timestamp;

        teamUnlockTime = block.timestamp + 3 * 365 days;

        burnUnlockTime = block.timestamp + 3 * 365 days;

        reserveCliffTime = block.timestamp + 365 days;

        reserveEndTime = block.timestamp + 3 * 365 days;


        // Create the complete 100M PINE supply.
        _totalSupply = MAX_SUPPLY;

        _balances[address(this)] = MAX_SUPPLY;

        emit Transfer(
            address(0),
            address(this),
            MAX_SUPPLY
        );


        // Send the immediately available allocations.

        _sendInitial(
            MARKETING_WALLET,
            MARKETING_ALLOCATION
        );

        _sendInitial(
            LIQUIDITY_WALLET,
            LIQUIDITY_ALLOCATION
        );

        _sendInitial(
            REWARDS_WALLET,
            REWARDS_ALLOCATION
        );
    }


    // ============================================================
    // ERC20
    // ============================================================

    function totalSupply()
        external
        view
        returns (uint256)
    {
        return _totalSupply;
    }


    function balanceOf(address account)
        external
        view
        returns (uint256)
    {
        return _balances[account];
    }


    function allowance(
        address tokenOwner,
        address spender
    )
        external
        view
        returns (uint256)
    {
        return _allowances[tokenOwner][spender];
    }


    function transfer(
        address to,
        uint256 amount
    )
        external
        returns (bool)
    {
        _transfer(
            msg.sender,
            to,
            amount
        );

        return true;
    }


    function approve(
        address spender,
        uint256 amount
    )
        external
        returns (bool)
    {
        require(
            spender != address(0),
            "PINE: zero spender"
        );

        _allowances[msg.sender][spender] = amount;

        emit Approval(
            msg.sender,
            spender,
            amount
        );

        return true;
    }


    function transferFrom(
        address from,
        address to,
        uint256 amount
    )
        external
        returns (bool)
    {
        uint256 allowed =
            _allowances[from][msg.sender];

        require(
            allowed >= amount,
            "PINE: insufficient allowance"
        );

        unchecked {
            _allowances[from][msg.sender] =
                allowed - amount;
        }

        emit Approval(
            from,
            msg.sender,
            _allowances[from][msg.sender]
        );

        _transfer(
            from,
            to,
            amount
        );

        return true;
    }


    // ============================================================
    // HOLDER BURN
    // ============================================================

    function burn(uint256 amount)
        external
    {
        require(
            amount > 0,
            "PINE: zero amount"
        );

        uint256 balance =
            _balances[msg.sender];

        require(
            balance >= amount,
            "PINE: insufficient balance"
        );

        unchecked {
            _balances[msg.sender] =
                balance - amount;

            _totalSupply -= amount;
        }

        emit Transfer(
            msg.sender,
            address(0),
            amount
        );
    }


    // ============================================================
    // 50M PERMANENT BURN
    // ============================================================

    function burnLockedReserve()
        external
    {
        require(
            block.timestamp >= burnUnlockTime,
            "PINE: burn locked"
        );

        require(
            !burnReserveExecuted,
            "PINE: already burned"
        );

        uint256 amount = BURN_RESERVE;

        require(
            _balances[address(this)] >= amount,
            "PINE: insufficient reserve"
        );

        burnReserveExecuted = true;

        unchecked {
            _balances[address(this)] -= amount;

            _totalSupply -= amount;
        }

        emit Transfer(
            address(this),
            address(0),
            amount
        );

        emit BurnReserve(amount);
    }


    // ============================================================
    // TEAM RELEASE
    // ============================================================

    function releaseTeamTokens()
        external
    {
        require(
            block.timestamp >= teamUnlockTime,
            "PINE: team locked"
        );

        require(
            !teamReleased,
            "PINE: already released"
        );

        teamReleased = true;

        _release(
            TEAM_WALLET,
            TEAM_ALLOCATION
        );

        emit TeamReleased(
            TEAM_ALLOCATION
        );
    }


    // ============================================================
    // ECOSYSTEM / TREASURY / COMMUNITY VESTING
    // ============================================================

    function releaseReserveTokens()
        external
    {
        require(
            block.timestamp >= reserveCliffTime,
            "PINE: cliff not reached"
        );


        uint256 ecosystemVested =
            _calculateVested(
                ECOSYSTEM_ALLOCATION
            );

        uint256 treasuryVested =
            _calculateVested(
                TREASURY_ALLOCATION
            );

        uint256 communityVested =
            _calculateVested(
                COMMUNITY_ALLOCATION
            );


        uint256 ecosystemAmount =
            ecosystemVested - ecosystemReleased;

        uint256 treasuryAmount =
            treasuryVested - treasuryReleased;

        uint256 communityAmount =
            communityVested - communityReleased;


        require(
            ecosystemAmount > 0 ||
            treasuryAmount > 0 ||
            communityAmount > 0,
            "PINE: nothing to release"
        );


        if (ecosystemAmount > 0) {

            ecosystemReleased +=
                ecosystemAmount;

            _release(
                ECOSYSTEM_WALLET,
                ecosystemAmount
            );
        }


        if (treasuryAmount > 0) {

            treasuryReleased +=
                treasuryAmount;

            _release(
                TREASURY_WALLET,
                treasuryAmount
            );
        }


        if (communityAmount > 0) {

            communityReleased +=
                communityAmount;

            _release(
                COMMUNITY_WALLET,
                communityAmount
            );
        }


        emit ReserveReleased(
            ecosystemAmount,
            treasuryAmount,
            communityAmount
        );
    }


    // ============================================================
    // VESTING INFORMATION
    // ============================================================

    function vestedAmount(uint256 allocation)
        external
        view
        returns (uint256)
    {
        return _calculateVested(allocation);
    }


    function remainingBurnReserve()
        external
        view
        returns (uint256)
    {
        if (burnReserveExecuted) {
            return 0;
        }

        return BURN_RESERVE;
    }


    function remainingTeamTokens()
        external
        view
        returns (uint256)
    {
        if (teamReleased) {
            return 0;
        }

        return TEAM_ALLOCATION;
    }


    function remainingEcosystemTokens()
        external
        view
        returns (uint256)
    {
        return ECOSYSTEM_ALLOCATION -
            ecosystemReleased;
    }


    function remainingTreasuryTokens()
        external
        view
        returns (uint256)
    {
        return TREASURY_ALLOCATION -
            treasuryReleased;
    }


    function remainingCommunityTokens()
        external
        view
        returns (uint256)
    {
        return COMMUNITY_ALLOCATION -
            communityReleased;
    }


    // ============================================================
    // INTERNAL TRANSFER
    // ============================================================

    function _transfer(
        address from,
        address to,
        uint256 amount
    )
        internal
    {
        require(
            from != address(0),
            "PINE: zero sender"
        );

        require(
            to != address(0),
            "PINE: zero receiver"
        );

        // Prevent the locked contract balance from being
        // transferred through normal ERC20 transfers.
        require(
            from != address(this),
            "PINE: locked balance"
        );


        uint256 balance =
            _balances[from];

        require(
            balance >= amount,
            "PINE: insufficient balance"
        );


        unchecked {
            _balances[from] =
                balance - amount;

            _balances[to] += amount;
        }


        emit Transfer(
            from,
            to,
            amount
        );
    }


    // ============================================================
    // INTERNAL INITIAL TRANSFER
    // ============================================================

    function _sendInitial(
        address to,
        uint256 amount
    )
        private
    {
        require(
            _balances[address(this)] >= amount,
            "PINE: insufficient balance"
        );

        unchecked {
            _balances[address(this)] -= amount;

            _balances[to] += amount;
        }

        emit Transfer(
            address(this),
            to,
            amount
        );
    }


    // ============================================================
    // INTERNAL RELEASE
    // ============================================================

    function _release(
        address to,
        uint256 amount
    )
        private
    {
        require(
            _balances[address(this)] >= amount,
            "PINE: insufficient locked balance"
        );

        unchecked {
            _balances[address(this)] -= amount;

            _balances[to] += amount;
        }

        emit Transfer(
            address(this),
            to,
            amount
        );
    }


    // ============================================================
    // VESTING CALCULATION
    // ============================================================

    function _calculateVested(
        uint256 allocation
    )
        private
        view
        returns (uint256)
    {
        if (block.timestamp < reserveCliffTime) {
            return 0;
        }

        if (block.timestamp >= reserveEndTime) {
            return allocation;
        }


        uint256 elapsed =
            block.timestamp -
            reserveCliffTime;

        uint256 duration =
            reserveEndTime -
            reserveCliffTime;


        return
            (allocation * elapsed) /
            duration;
    }
}

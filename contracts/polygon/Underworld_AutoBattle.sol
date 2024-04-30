// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
// import "@openzeppelin/contracts/utils/math/Math.sol";
import {IKyodaiPoly, IShateiPoly, INeoYen, IPinkie, IUnderworld, IGameOracle} from "../interfaces/Interfaces.sol";
import {IDelegateRegistry} from "../interfaces/IDelegateRegistry.sol";
import {KyodaiLibrary} from "../utils/Libraries.sol";

// TODO delegate wallet to smart wallet when staking to enable seamless web3 game experience
contract Underworld is IUnderworld, OwnableUpgradeable, UUPSUpgradeable {
    using KyodaiLibrary for uint256;

    error UnauthorizedAddress();
    error TokenNotOwned();
    error InvalidTarget();
    error InvalidAction();
    error GameNotStarted();

    event Battle(
        uint256 indexed tokenId,
        uint256 indexed targetId,
        uint256 currentScore
    );
    event Claimed(
        uint256 indexed tokenId,
        uint256 indexed result,
        uint256 yenAmount
    );
    // TODO emit when regenhp, immunity, and bailout
    event UseItem(
        uint256 indexed tokenId,
        uint256 indexed action,
        uint256 indexed tier
    );

    // struct District{
    //   uint16 population;
    //   uint80 influenceA;
    //   uint80 influenceB;
    //   uint80 influenceC;
    // }

    // struct GameStat {
    //   uint24 scores;
    //   uint8 location;
    //   uint32 currentHP;   // or workingDeadline. Dual function, to set the determined working deadline
    //   uint40 lastBattle;  // or startWorking. Dual function, to count neoyen generation if working (location index > 7)
    //   uint40 immunity;
    //   uint32 hp;
    //   uint16 atk;
    //   uint16 def;
    //   uint16 atkSpd;
    //   uint16 critDmg;
    //   uint16 dodgeChance;
    // }

    uint256 public gameStart; // 1 - game not started || 2 - game start
    bytes32 internal entropySpice;
    uint256 public constant PCT_DEN = 10_000; // Probabilities scale, where 10_000 == 100% and 0 == 0%

    // uint96 token alliance
    // uint160 owner address
    mapping(uint256 => uint256) public patriarchs; // token owner and its alliance

    //   uint24 scores,
    //   uint8 location,
    //   uint32 currentHP,  || workingDeadline // dual function, to set the determined working deadline
    //   uint40 lastBattle  || startWorking, // dual function, to count neoyen generation if working (location index > 7)
    //   uint40 immunity,
    //   uint32 hp,
    //   uint16 atk,
    //   uint16 def,
    //   uint16 atkSpd,
    //   uint16 critDmg,
    //   uint16 dodgeChance
    mapping(uint256 => uint256) public gameStats;

    // kinshicho  --> 0
    // ebisu      --> 1
    // roppongi   --> 2
    // kabukicho  --> 3
    // ikebukuro  --> 4
    // ginza      --> 5
    // akihabara  --> 6
    // uint80 Ryuichi
    // uint80 Torahide
    // uint80 Nobu
    // uint16 population
    // alliances influence over districts. Divided by uint80 per alliance per district. The last uint16 reserved for population in district
    mapping(uint256 => uint256) public districts;

    // address kyodaiAddy;      --> 0
    // address shateiAddy;      --> 1
    // address dogtagAddy;      --> 2
    // address yenAddy;         --> 3
    // address gameOracle       --> 4
    // address delegateRegistry --> 5
    mapping(uint256 => address) public officialAddys;

    mapping(uint256 => uint256) public battles;

    // TODO remove this modifier to enable ERC4337 Account Abstraction
    // modifier noCheating() {
    //     require(
    //         msg.sender == tx.origin && !KyodaiLibrary.isContract(msg.sender),
    //         "you're trying to cheat"
    //     );
    //     _;
    // }

    modifier authorizedWallet(uint256 tokenId) {
        address tokenOwner = address(uint160(patriarchs[tokenId]));
        require(
            msg.sender == tokenOwner ||
                IDelegateRegistry(officialAddys[5]).checkDelegateForERC721(
                    msg.sender,
                    tokenOwner,
                    tokenId < 6667 ? officialAddys[0] : officialAddys[1],
                    tokenId,
                    ""
                )
        );
        _;
    }

    //@dev required for UUPS Proxy Pattern
    function _authorizeUpgrade(address) internal override onlyOwner {}

    function init() external initializer {
        __Ownable_init();
        gameStart = 1;
    }

    /// @param _gameStart 1 - game not start || 2 - game start
    function toggleGame(uint256 _gameStart) public onlyOwner {
        gameStart = _gameStart;
    }

    function setNewAddy(uint256 index, address newAddy) public onlyOwner {
        officialAddys[index] = newAddy;
    }

    /// @dev function to unstake from game contract. must be implemented in other game contract
    /// @notice can only be called from kyodai or shatei contract
    function unstake(uint256 tokenId) external override {
        if (
            tokenId < 6667
                ? msg.sender != officialAddys[0]
                : msg.sender != officialAddys[1]
        ) revert UnauthorizedAddress();
        // require(
        //   tokenId < 6667
        //     ? msg.sender == officialAddys[0]
        //     : msg.sender == officialAddys[1],
        //   "unauthorized caller"
        // );

        uint256 tokenStat = gameStats[tokenId];
        uint256 location = uint256(uint8(tokenStat));
        if (location != 0) revert InvalidAction(); // must be out of game to unstake

        delete patriarchs[tokenId];
        uint256 district = districts[getLocation(uint8(tokenStat))];
        districts[getLocation(uint8(tokenStat))] = updateInfluence(
            district,
            (district >> 240 == 0 ? 0 : (district >> 240) - 1),
            0,
            0,
            0
        );
        uint256 mask = ~uint256(255);
        gameStats[tokenId] &= mask;
        _updateEntropy();
    }

    /// @notice stake to this contract to battle or farm $NEOYEN
    /// @notice for first time staking and set action to working, work duration default set to 3 days.
    /// @notice if want to set for more days, set action to unstaked when staking and then doAction to working
    /// @param tokenIds tokens to be staked
    /// @param kyodais kyodais or shateis data (traitHash, level, etc)
    /// @param owner owner of tokens
    /// @param location location district to be staked. 0 - 6 = districts
    /// @param action 0 - unstaked | 1 - working | 2 - battle
    function stakeMany(
        uint256[] calldata tokenIds,
        uint256[] calldata kyodais,
        address owner,
        uint256 location,
        uint256 action
    ) external override {
        if (msg.sender != officialAddys[0] && msg.sender != officialAddys[1])
            revert UnauthorizedAddress();
        // require(
        //   msg.sender == officialAddys[0] || msg.sender == officialAddys[1],
        //   "unauthorized caller"
        // );

        // updateDistrict(location, tokenIds.length);
        uint256 district = districts[location];
        districts[location] = updateInfluence(
            district,
            (district >> 240) + tokenIds.length,
            0,
            0,
            0
        );

        uint256[4] memory _baseStat = [
            uint256(1584564459358683415361718584196), // kyodai
            2297617922023955941846738272956, // druggie
            950741577096208225363872973350, // hacker
            792284043123414317356627788776 // cyborg
        ];

        for (uint256 i = 0; i < tokenIds.length; ) {
            //TODO use getManyKyodai to reduce inter contract calls
            uint256 _kyodai = kyodais[i];
            // (, uint256 traitHash, uint256 _level, ) = kyodais[i].decodeKyodai();
            // uint256 _level = uint256(uint16(_kyodai >> 176));

            // traitHash = uint256(uint8(traitHash));

            uint256 _attr = (
                _baseStat[(tokenIds[i] - 1) / 6666]
                // tokenIds[i] > 6666 ? _baseStat[((tokenIds[i] - 6667) / 6666 )+ 1] : _baseStat[0]
            ) *
                (
                    uint256(uint16(_kyodai >> 176)) < 2260
                        ? uint256(uint16(_kyodai >> 176))
                        : 2259
                );

            _kyodai = uint256(uint8(_kyodai >> 192)); // alliance trait hash
            uint256 _stat = gameStats[tokenIds[i]];
            if (_stat == 0)
                _stat = encodeStat(
                    0,
                    1,
                    uint256(uint32(_attr)),
                    block.timestamp,
                    block.timestamp,
                    0,
                    0,
                    0,
                    0,
                    0,
                    0
                );
            _stat = uint256(uint144(_stat));
            _stat |= _attr << 144;

            _kyodai <<= 160;
            _kyodai |= uint256(uint160(owner));
            patriarchs[tokenIds[i]] = _kyodai;

            _doAction(tokenIds[i], _stat, _kyodai, location, action, 1);

            unchecked {
                ++i;
            }
        }
    }

    function delegateKyodai(
        uint256 tokenId,
        address smartWallet,
        bytes[] calldata data,
        bool enable
    ) external {
        if (address(uint160(patriarchs[tokenId])) != msg.sender)
            revert TokenNotOwned();

        IDelegateRegistry(officialAddys[5]).delegateERC721(
            smartWallet,
            tokenId < 6667 ? officialAddys[0] : officialAddys[1],
            tokenId,
            "",
            enable
        );

        // TODO delete this function and only use multiCall function from frontend to reduce gas and time
        IDelegateRegistry(officialAddys[5]).multicall(data);
    }

    // function updateDistrict(uint256 location, uint256 amount) internal {
    //  uint256 district = districts[location];
    //   districts[location] = updateInfluence(district,(district>>240) + amount, 0, 0, 0);
    // }

    function battle(
        uint256 tokenId,
        uint256 targetId
    ) external authorizedWallet(tokenId) {
        if (gameStart != 2) revert GameNotStarted();
        // require(gameStart, "game not started");

        // if (address(uint160(patriarchs[tokenId])) != msg.sender)
        //     revert TokenNotOwned();
        // require(
        //   address(uint160(patriarchs[tokenId])) == msg.sender,
        //   "token not owned"
        // );

        if (battles[tokenId] != 0) revert InvalidAction(); // check if haven't claim previous battle

        uint256 tokenStat = gameStats[tokenId];
        uint256 targetStat = gameStats[targetId];
        // uint256 tokenLocation = uint256(uint8(tokenStat));
        // uint256 targetLocation = uint256(uint8(targetStat));

        if (uint256(uint8(tokenStat)) < 8) revert InvalidAction();
        // require(
        // uint256(uint8(tokenStat)) > 7,
        //   "token is away"
        // );

        if (getLocation(uint8(tokenStat)) != getLocation(uint8(targetStat)))
            revert InvalidTarget();

        // require(
        //   ((uint256(uint8(tokenStat)) - 1) % 7) ==
        //     ((uint256(uint8(targetStat)) - 1) % 7),
        //   "target is away"
        // );

        uint256 currentScore = uint256(uint24(tokenStat >> 8));
        uint256 targetScore = uint256(uint24(targetStat >> 8));

        // target must have higher score than player or in same tier for emperor upto conqueror
        if (targetScore < currentScore && targetScore < 1500)
            revert InvalidTarget();
        // require(
        //   targetScore > currentScore - 1 || targetScore > 1500,
        //   "target is unqualified"
        // );

        if (uint256(uint40(targetStat >> 104)) > block.timestamp)
            revert InvalidTarget();
        // require(
        //   uint256(uint40(targetStat >> 104)) < block.timestamp,
        //   "target is immune"
        // );

        //TODO update battle cost
        INeoYen(officialAddys[3]).burnAuth(msg.sender, 75 * 1 ether);

        uint256 remainHP = battleResult(tokenStat, targetStat);

        if (remainHP > 0) {
            uint256 winScore = 18 - getRank(currentScore);
            currentScore += winScore;

            targetStat = updateStat(
                targetStat,
                uint256(uint8(targetStat)),
                targetScore < 10 ? 0 : targetScore - 10,
                uint256(uint32(targetStat >> 32)),
                uint256(uint40(targetStat >> 64)),
                block.timestamp + 1 hours
            );

            // update clan influence on district
            if (
                getAlliance(uint256(uint8(tokenStat))) !=
                getAlliance(uint256(uint8(targetStat)))
            ) {
                uint256 oldInfluence = districts[getLocation(uint8(tokenStat))];
                districts[getLocation(uint8(tokenStat))] = updateInfluence(
                    oldInfluence,
                    oldInfluence >> 240,
                    getAlliance(uint256(uint8(tokenStat))),
                    getAlliance(uint256(uint8(targetStat))),
                    winScore
                );
            }

            //targetId, targetscore, battle duration (battle duratioin result times 1 minute),
            uint256 _battle = targetId;
            _battle |= targetScore << 16;
            _battle |= (block.timestamp + 10 minutes) << 40;
            battles[tokenId] = _battle;

            IGameOracle(officialAddys[4]).requestRandom(tokenId);
            // IPinkie(officialAddys[2]).mint(
            //   (
            //     targetId > 6666
            //       ? (targetId - 6667) / 6666
            //       : (_randomize(_rand(), "CYKY0", tokenId) % 3)
            //   ) + getPinkieRank(targetScore),
            //   msg.sender
            // );
        }

        tokenStat = updateStat(
            tokenStat,
            1,
            (currentScore > 16777215 ? 16777215 : currentScore),
            remainHP,
            block.timestamp,
            block.timestamp
        );
        gameStats[tokenId] = tokenStat;
        gameStats[targetId] = targetStat;
        _updateEntropy();
        emit Battle(tokenId, targetId, currentScore);
    }

    function claimBattleResult(uint256 tokenId) external {
        uint256 _battle = battles[tokenId];
        if ((_battle >> 40) > block.timestamp) revert InvalidAction(); // check if battle not done yet

        uint256 _random = _randomize(
            IGameOracle(officialAddys[4]).getRandom(tokenId),
            "N30KY0",
            uint256(entropySpice)
        );
        uint256 tokenStat = gameStats[tokenId];
        uint256 result = calculateRandomResult(
            _random,
            getPinkieChance(uint256(uint24(tokenStat >> 16))),
            6
        );

        /// TODO chance ga dapet pinkie (?)
        if (result != 0) {
            IPinkie(officialAddys[2]).mint(
                (
                    uint256(uint16(_battle)) > 6666
                        ? (uint256(uint16(_battle)) - 6667) / 6666
                        : _randomize(_random, "CYKY0", tokenId) % 3
                ) + ((result * 3) - 2),
                msg.sender
            );
        }
        delete battles[tokenId];

        // battles[tokenId] = battle>>
    }

    function battleResult(
        uint256 tokenStat,
        uint256 targetStat
    ) internal view returns (uint256 remainingHP) {
        uint256 totalHp = uint256(uint32(tokenStat >> 32)) +
            ((uint256(uint32(tokenStat >> 144)) *
                (block.timestamp - uint256(uint40(tokenStat >> 64)))) /
                240 minutes);
        if (totalHp > uint256(uint32(tokenStat >> 144)))
            totalHp = uint256(uint32(tokenStat >> 144));

        uint256 denominator = PCT_DEN; // call constant from storage just 1 time to save gas
        uint256 hpLoss = calculateHPLoss(
            tokenStat,
            targetStat,
            calculateBattle(tokenStat, targetStat, denominator),
            denominator
        );
        remainingHP = totalHp < hpLoss ? 0 : totalHp - hpLoss;
    }

    function calculateHPLoss(
        uint256 tokenStat,
        uint256 targetStat,
        uint256 duration,
        uint256 _PCT_DEN
    ) internal pure returns (uint256 hpLoss) {
        // uint256 targetAtk = uint256(uint16(targetStat >> 176));
        hpLoss =
            (duration *
                ((((uint256(uint16(targetStat >> 176)) *
                    uint256(uint16(targetStat >> 176)) *
                    _PCT_DEN) /
                    (uint256(uint16(targetStat >> 176)) +
                        uint256(uint16(tokenStat >> 192)))) +
                    ((uint256(uint16(targetStat >> 176)) *
                        uint256(uint16(targetStat >> 224)) *
                        _PCT_DEN) /
                        (uint256(uint16(targetStat >> 224)) +
                            uint256(uint32(tokenStat >> 240))))) *
                    uint256(uint16(targetStat >> 208))) *
                uint256(uint32(tokenStat >> 144))) /
            (uint256(uint32(tokenStat >> 144)) *
                (_PCT_DEN +
                    ((uint256(uint32(tokenStat >> 240)) * _PCT_DEN) /
                        (uint256(uint16(targetStat >> 208)) * 10))));
    }

    function calculateBattle(
        uint256 tokenStat,
        uint256 targetStat,
        uint256 _PCT_DEN
    ) internal pure returns (uint256 duration) {
        uint256 tokenAtk = uint256(uint16(tokenStat >> 176));
        duration =
            ((uint256(uint32(targetStat >> 144)) *
                (_PCT_DEN +
                    ((uint256(uint32(targetStat >> 240)) * _PCT_DEN) /
                        (uint256(uint16(tokenStat >> 208)) * 10)))) *
                _PCT_DEN) /
            ((((tokenAtk * tokenAtk * _PCT_DEN) /
                (tokenAtk + uint256(uint16(targetStat >> 192)))) +
                ((tokenAtk * uint256(uint16(tokenStat >> 224)) * _PCT_DEN) /
                    (uint256(uint16(tokenStat >> 224)) +
                        uint256(uint32(targetStat >> 240))))) *
                uint256(uint16(tokenStat >> 208)));
    }

    function regenHp(uint256 tokenId, uint256 pinkieId) external {
        IPinkie(officialAddys[2]).burn(pinkieId, msg.sender, 1);
        uint256 kyodai = gameStats[tokenId];

        // require action is not working for neoyen or unstaked
        if (uint256(uint8(kyodai)) < 8) revert InvalidAction();

        uint256 hp = uint256(uint32(kyodai >> 144));
        uint256 addHp = ((hp * ((pinkieId / 3) + 1) * 2) - 1) / 10;

        gameStats[tokenId] = updateStat(
            kyodai,
            uint256(uint8(kyodai)),
            uint256(uint24(kyodai >> 8)),
            uint256(uint32(kyodai >> 32)) + addHp > hp
                ? hp
                : uint256(uint32(kyodai >> 32)) + addHp,
            uint256(uint40(kyodai >> 64)),
            uint256(uint40(kyodai >> 104))
        );
    }

    function regenImmunity(uint256 tokenId, uint256 pinkieId) external {
        IPinkie(officialAddys[2]).burn(pinkieId, msg.sender, 1);
        uint256 kyodai = gameStats[tokenId];

        gameStats[tokenId] = updateStat(
            kyodai,
            uint256(uint8(kyodai)),
            uint256(uint24(kyodai >> 8)),
            uint256(uint32(kyodai >> 32)),
            uint256(uint40(kyodai >> 64)),
            block.timestamp + (((pinkieId / 3) + 1) * 2 * 1 hours)
        );
    }

    function bailOut(uint256 tokenId, uint256 pinkieId) external {
        IPinkie(officialAddys[2]).burn(pinkieId, msg.sender, 1);
        uint256 kyodai = gameStats[tokenId];
        if (uint256(uint8(kyodai)) != 0) revert InvalidAction();

        gameStats[tokenId] = updateStat(
            kyodai,
            uint256(uint8(kyodai)),
            uint256(uint24(kyodai >> 8)),
            uint256(uint32(kyodai >> 32)),
            uint256(uint40(kyodai >> 64)) -
                (1 days + (((pinkieId / 3) + 1) * 12 * 1 hours)),
            uint256(uint40(kyodai >> 104))
        );
    }

    /// @param tokenId the ID number of token
    /// @param location location district to be staked. 0 - 6
    /// @param action 0 - unstaked | 1 - working | 2 - battle mode
    /// @param workDuration duration to stake for neoyen. input 1 - 5 for 3 to 15 days.
    /// @notice can not be called by kyodai in working mode. if kyodai in working mode want to change action, call claim
    function doAction(
        uint256 tokenId,
        uint256 location,
        uint256 action,
        uint256 workDuration
    ) external {
        (address patriarch, uint256 alliance) = getPatriarch(tokenId);
        if (patriarch != msg.sender) revert TokenNotOwned();
        // require(address(uint160(patriarch)) == msg.sender,"kyodai not owned");
        uint256 tokenStat = gameStats[tokenId];
        uint256 _location = uint256(uint8(tokenStat));

        // check if kyodai is working
        // if(_location<8 && _location!=0) revert InvalidAction();

        //check if still jailed
        if (
            _location == 0 && uint256(uint40(tokenStat >> 64)) > block.timestamp
        ) revert InvalidAction();

        uint256 _result;
        if (_location < 8 && _location != 0)
            _result = _claim(
                tokenId,
                uint8(_location),
                districts[getLocation(uint8(_location))],
                uint256(uint32(tokenStat >> 32)),
                uint256(uint40(tokenStat >> 64))
            );

        if (getLocation(uint8(tokenStat)) != location) {
            uint256 oldDistrict = districts[getLocation(uint8(_location))];
            districts[getLocation(uint8(_location))] = updateInfluence(
                oldDistrict,
                (oldDistrict >> 240 == 0 ? 0 : (oldDistrict >> 240) - 1),
                0,
                0,
                0
            );
            uint256 newDistrict = districts[location];
            districts[location] = updateInfluence(
                newDistrict,
                (newDistrict >> 240) + 1,
                0,
                0,
                0
            );
        }

        if (_location < 8 && _location != 0 && _result > 5) {
            if (_result == 6)
                _doAction(
                    tokenId,
                    updateStat(
                        tokenStat,
                        0,
                        uint256(uint24(tokenStat >> 8)),
                        uint256(uint32(tokenStat >> 32)),
                        block.timestamp + 3 days,
                        uint256(uint40(tokenStat >> 104))
                    ),
                    alliance,
                    0,
                    0,
                    workDuration
                );
        } else {
            _doAction(
                tokenId,
                tokenStat,
                alliance,
                location,
                action,
                workDuration
            );
        }
    }

    /// @notice can only be called by kyodais or shateis at working mode
    /// @notice to claim neoyen and continue working or do other action
    // function claimAndDoAction(uint256 tokenId, uint256 location, uint256 action, uint256 workDuration) external noCheating{
    //     uint256 patriarch = patriarchs[tokenId];
    //     if(address(uint160(patriarch)) != msg.sender) revert TokenNotOwned();

    //     uint256 tokenStat = gameStats[tokenId];
    //     uint256 _location = uint256(uint8(tokenStat));
    //     if(_location==0 || _location >7) revert InvalidAction();

    //     uint256 _result = _claim(tokenId, _location, districts[getLocation(_location)], uint256(uint32(tokenStat>>32)), uint256(uint40(tokenStat>>64)));

    //   if(getLocation(uint256(uint8(tokenStat))) != location){
    //     uint256 oldDistrict = districts[getLocation(_location)];
    //     districts[getLocation(_location)] = updateInfluence(oldDistrict, (oldDistrict>>240 == 0 ?0:(oldDistrict>>240)-1), 0, 0, 0);
    //     uint256 newDistrict = districts[location];
    //     districts[location] = updateInfluence(newDistrict, (newDistrict>>240)+1, 0, 0, 0);
    //     }

    //     if(_result==6){
    //       _doAction(tokenId, updateStat(tokenStat, 0, uint256(uint24(tokenStat>>8)), uint256(uint32(tokenStat>>32)), block.timestamp + 1 days, uint256(uint40(tokenStat>>104))),
    //       patriarch>>160, _location, 0, workDuration);
    //     }else if(_result!=7){
    //       _doAction(tokenId, tokenStat, patriarch>>160, location, action, workDuration);
    //     }
    // }

    /// @notice can not be called by kyodai in working mode. if kyodai in working mode want to change action, call claim
    function doActionMany(
        uint256[] calldata tokenIds,
        uint256 location,
        uint256 action,
        uint256 workDuration
    ) external {
        uint256[7] memory _populationDiff;

        for (uint256 i = 0; i < tokenIds.length; ) {
            (address patriarch, uint256 alliance) = getPatriarch(tokenIds[i]);
            if (patriarch != msg.sender) revert TokenNotOwned();
            uint256 tokenStat = gameStats[tokenIds[i]];
            uint256 _location = uint256(uint8(tokenStat));
            // check if working
            // if(uint256(uint8(tokenStat))<8 && uint256(uint8(tokenStat))!=0) revert InvalidAction();

            //check if still jailed
            if (
                _location == 0 &&
                uint256(uint40(tokenStat >> 64)) > block.timestamp
            ) revert InvalidAction();

            uint256 _result = _claim(
                tokenIds[i],
                uint8(tokenStat),
                districts[getLocation(uint8(tokenStat))],
                uint256(uint32(tokenStat >> 32)),
                uint256(uint40(tokenStat >> 64))
            );

            if (getLocation(uint8(tokenStat)) != location) {
                _populationDiff[getLocation(uint8(tokenStat))] += 1; // out from district
                _populationDiff[location] += 1; // in to district
            }

            // check if result is bigger than 5 so burn result dont go to else function
            if (_location < 8 && _location != 0 && _result > 5) {
                if (_result == 6)
                    _doAction(
                        tokenIds[i],
                        updateStat(
                            tokenStat,
                            0,
                            uint256(uint24(tokenStat >> 8)),
                            uint256(uint32(tokenStat >> 32)),
                            block.timestamp + 3 days,
                            uint256(uint40(tokenStat >> 104))
                        ),
                        alliance,
                        0,
                        0,
                        workDuration
                    );
            } else {
                _doAction(
                    tokenIds[i],
                    tokenStat,
                    alliance,
                    location,
                    action,
                    workDuration
                );
            }
            unchecked {
                ++i;
            }
        }
        // update district population
        for (uint256 i = 0; i < 7; ) {
            uint256 _diff = _populationDiff[i];

            if (i == location) {
                // add new population to district
                uint256 oldDistrict = districts[i];
                districts[i] = updateInfluence(
                    oldDistrict,
                    (oldDistrict >> 240) + _diff,
                    0,
                    0,
                    0
                );
            } else if (_diff != 0) {
                // change district population
                uint256 oldDistrict = districts[i];
                districts[i] = updateInfluence(
                    oldDistrict,
                    (oldDistrict >> 240) < _diff
                        ? 0
                        : (oldDistrict >> 240) - _diff,
                    0,
                    0,
                    0
                );
            }
            unchecked {
                ++i;
            }
        }
    }

    // function claimAndDoActionMany(uint256[] calldata tokenIds, uint256 location, uint256 action, uint256 workDuration) external noCheating{

    //    uint256[7] memory _populationDiff;

    //   for(uint256 i=0;i<tokenIds.length;){
    //   uint256 patriarch = patriarchs[tokenIds[i]];
    //     if(address(uint160(patriarch)) != msg.sender) revert TokenNotOwned();
    //     uint256 tokenStat = gameStats[tokenIds[i]];

    //   // check if not working
    //     //  if(uint256(uint8(tokenStat))==0 || uint256(uint8(tokenStat)) >7) revert InvalidAction();

    //   // claim woeking result
    //     uint256 _result = _claim(tokenIds[i], uint256(uint8(tokenStat)), districts[getLocation(uint256(uint8(tokenStat)))],
    //     uint256(uint32(tokenStat>>32)), uint256(uint40(tokenStat>>64)));

    //     // do action based on result
    //       if(_result==6){
    //       _doAction(tokenIds[i], updateStat(tokenStat, 0, uint256(uint24(tokenStat>>8)), uint256(uint32(tokenStat>>32)), block.timestamp + 1 days, uint256(uint40(tokenStat>>104))),
    //       patriarch>>160, uint256(uint8(tokenStat)), 0, workDuration);
    //     }else if(_result!=7){
    //       _doAction(tokenIds[i], tokenStat, patriarch>>160, location, action, workDuration);
    //     }

    //      // update district population
    //      if(getLocation(uint256(uint8(tokenStat))) != location && _result<6){
    //       _populationDiff[getLocation(uint256(uint8(tokenStat)))]+=1;  // out from district
    //       _populationDiff[location]+=1;          // in to district
    //     }
    //     unchecked{
    //       ++i;
    //     }
    //   }
    //      // update district population
    //    for(uint256 i=0;i<7;){
    //     uint256 _diff = _populationDiff[i];

    //     if(i==location){
    //       // add new population to district
    //         uint256 oldDistrict =  districts[i];
    //         districts[i] = updateInfluence(oldDistrict, (oldDistrict>>240) + _diff , 0, 0, 0);
    //     }else if(_diff!=0){
    //         // change district population
    //         uint256 oldDistrict =  districts[i];
    //         districts[i] = updateInfluence(oldDistrict,  (oldDistrict>>240) < _diff? 0: (oldDistrict>>240) - _diff, 0, 0, 0);
    //     }

    //     unchecked{
    //       ++i;
    //     }
    //   }
    // }

    function _claim(
        uint256 tokenId,
        uint8 location,
        uint256 district,
        uint256 duration,
        uint256 startTime
    ) internal returns (uint256 result) {
        if (gameStart != 2) revert GameNotStarted();
        uint256 _location = getLocation(location);
        uint256 overtime = duration < (block.timestamp - startTime)
            ? (block.timestamp - startTime) - duration
            : duration - (block.timestamp - startTime);
        result = calculateRandomResult(
            _randomize(
                IGameOracle(officialAddys[4]).getRandom(tokenId),
                "N30Y3N",
                uint256(entropySpice)
            ),
            calculateChances(
                overtime,
                getChances(tokenId, _location, duration)
            ),
            8
        );
        // uint256 tokenStat = gameStats[tokenId];
        uint256 multiplier;
        uint256 patriarch = patriarchs[tokenId];

        if (result < 5) {
            // 0.3x to jackpot result
            if (result == 3) multiplier = 100;
            else if (result == 4) multiplier = 30;
            else if (result == 2) multiplier = 300;
            else if (result == 1) multiplier = 600;
            else if (result == 0) multiplier = 1000;
        } else {
            // fumble result
            if (
                patriarch >> 160 != getDominatingAlliance(districts[_location])
            ) {
                // burn token
                if (result == 7) {
                    tokenId < 6667
                        ? IKyodaiPoly(officialAddys[0]).burnAuth(tokenId)
                        : IShateiPoly(officialAddys[1]).burnAuth(tokenId);
                    delete patriarchs[tokenId];
                    delete gameStats[tokenId];
                }
            }
        }

        if (multiplier != 0) {
            INeoYen(officialAddys[3]).mint(
                address(uint160(patriarch)),
                getNeoYenShares(
                    duration,
                    multiplier,
                    _location,
                    uint256(uint16(district >> 240))
                )
            );
        } // mint neoyen
    }

    function _doAction(
        uint256 tokenId,
        uint256 tokenStat,
        uint256 alliance,
        uint256 location,
        uint256 action,
        uint256 workDuration
    ) internal {
        if (
            uint256(uint8(tokenStat)) == 0 &&
            uint256(uint40(tokenStat >> 64)) > block.timestamp
        ) revert InvalidAction(); // still jailed
        uint256 _location;
        if (action == 1) {
            // working mode
            require(workDuration < 6 && workDuration != 0, "invalid duration");
            _location = location + 1;
            IGameOracle(officialAddys[4]).requestRandom(tokenId);
        }
        if (action == 2) {
            // battle mode
            _location = (alliance * 7) + location + 7;
        }
        gameStats[tokenId] = updateStat(
            tokenStat,
            _location,
            uint256(uint24(tokenStat >> 8)),
            action == 1
                ? workDuration * 3 days
                : uint256(uint32(tokenStat >> 32)),
            block.timestamp,
            uint256(uint40(tokenStat >> 104))
        );
    }

    function getRank(uint256 score) internal pure returns (uint256) {
        if (score < 60) return 0;
        if (score > 59 && score < 140) return 1;
        if (score > 139 && score < 240) return 2;
        if (score > 239 && score < 360) return 3;
        if (score > 359 && score < 500) return 4;
        if (score > 499 && score < 660) return 5;
        if (score > 659 && score < 840) return 6;
        if (score > 839 && score < 1040) return 7;
        if (score > 1039 && score < 1260) return 8;
        if (score > 1259 && score < 1500) return 9;
        if (score > 1499) return 10;
        revert();
    }

    // function getPinkieRank(uint256 score) internal pure returns (uint256) {
    //   if (score < 240) return 1;
    //   if (score > 239 && score < 660) return 4;
    //   if (score > 659 && score < 1040) return 7;
    //   if (score > 1039 && score < 1500) return 10;
    //   if (score > 1499) return 13;
    //   revert();
    // }

    function getPinkieChance(uint256 score) internal pure returns (uint256) {
        if (score > 59 && score < 140) return 4295294980000;
        if (score > 139 && score < 240) return 6442745860000;
        if (score > 239 && score < 360) return 56301438140419000;
        if (score > 359 && score < 500) return 140746078617602500;
        if (score > 499 && score < 660) return 1844927743440257026000;
        if (score > 659 && score < 840) return 120896271732500862107650000;
        if (score > 839 && score < 1040) return 241794387998664304984066000;
        if (score > 1039 && score < 1260) return 604481357395826111971330000;
        if (score > 1259 && score < 1500) return 967172016001062166102018000;
        if (score > 1499) return 1813434846985819772715010000;
        revert();
    }

    function getChances(
        uint256 tokenId,
        uint256 location,
        uint256 days_
    ) internal pure returns (uint256) {
        // returns result chances based on duration staked 3, 6, 9, 12, 15 days
        // stored in uint256 divided per uint32

        bool bonus = ((tokenId - 1) / 6666) + 3 == location;

        if (days_ == 3 days)
            return
                bonus
                    ? 604518251306179124186317000
                    : 725418211993417734645350500;
        if (days_ == 6 days)
            return
                bonus
                    ? 155772471700414538287996034664366325
                    : 155772471821308964867570039244718225;
        if (days_ == 9 days)
            return
                bonus
                    ? 389431217958340225892890197153415481
                    : 389431218079226351310967292915744981;
        if (days_ == 12 days)
            return
                bonus
                    ? 700976160150132799856524018109514131
                    : 700976160271007857059271902114480431;
        if (days_ == 15 days)
            return
                bonus
                    ? 1090407298275792260178897497532662275
                    : 1090407298396653482112483866840924575;
        revert();
    }

    function getNeoYenShares(
        uint256 duration,
        uint256 multiplier,
        uint256 location,
        uint256 population
    ) internal pure returns (uint256) {
        uint256 pool;
        if (location == 0) pool = 6666;
        if (location == 1) pool = 16666;
        if (location == 2) pool = 33333;
        if (location == 3) pool = 55555;
        if (location > 3) pool = 66666;

        return (pool * duration * multiplier * 1 ether) / (population * 86400);
    }

    function getDominatingAlliance(
        uint256 influence
    ) public pure returns (uint256 alliance) {
        alliance = uint256(uint80(influence)) >
            uint256(uint80(influence >> (80))) &&
            uint256(uint80(influence)) > uint256(uint80(influence >> (160)))
            ? 0
            : (
                uint256(uint80(influence >> (80))) >
                    uint256(uint80(influence >> (160)))
                    ? 1
                    : 2
            );
    }

    function calculateRandomResult(
        uint256 random,
        uint256 chances,
        uint256 length
    ) internal pure returns (uint256 result) {
        random %= PCT_DEN;
        uint256 currentLowerBound;

        for (uint256 i = 0; i < length; ) {
            uint256 thisPercentage = uint256(uint16(chances >> (i * 16)));
            if (
                random >= currentLowerBound &&
                random < currentLowerBound + thisPercentage
            ) return i;
            currentLowerBound = currentLowerBound + thisPercentage;

            unchecked {
                ++i;
            }
        }
        revert();
    }

    function calculateChances(
        uint256 overtime,
        uint256 chances
    ) internal pure returns (uint256 _chances) {
        overtime = overtime > 3 days ? 3 days : overtime;
        uint256 interval = 90000;

        // TODO fix chances calculation to prevent underflow operations
        _chances = uint256(uint16(chances)) - ((overtime * 30) / interval);
        _chances |=
            (uint256(uint16(chances >> 16)) - ((overtime * 60) / interval)) <<
            16;
        _chances |=
            (uint256(uint16(chances >> 32)) - ((overtime * 360) / interval)) <<
            32;
        _chances |=
            (uint256(uint16(chances >> 48)) - ((overtime * 1050) / interval)) <<
            48;

        _chances |=
            (uint256(uint16(chances >> 64)) + ((overtime * 360) / interval)) <<
            64;
        _chances |=
            (uint256(uint16(chances >> 80)) + ((overtime * 600) / interval)) <<
            80;
        _chances |=
            (uint256(uint16(chances >> 96)) + ((overtime * 450) / interval)) <<
            96;
        _chances |=
            (uint256(uint16(chances >> 112)) + ((overtime * 90) / interval)) <<
            112;
    }

    function updateStat(
        uint256 oldStat,
        uint256 location,
        uint256 scores,
        uint256 currentHP,
        uint256 lastBattle,
        uint256 immunity
    ) internal pure returns (uint256 newStat) {
        newStat = encodeStat(
            location,
            scores,
            currentHP,
            lastBattle,
            immunity,
            0,
            0,
            0,
            0,
            0,
            0
        );
        newStat |= (oldStat >> 144) << 144;
    }

    function encodeStat(
        uint256 location,
        uint256 scores,
        uint256 currentHP, // dual function, act as work duration if working
        uint256 lastBattle, // dual function, act as start working time to count neoyen generation if working (location index > 7)
        uint256 immunity,
        uint256 hp,
        uint256 atk,
        uint256 def,
        uint256 atkSpd,
        uint256 critDmg,
        uint256 dodgeChance
    ) internal pure returns (uint256 _stat) {
        _stat = location;
        _stat |= scores << 8;
        _stat |= currentHP << 32;
        _stat |= lastBattle << 64;
        _stat |= immunity << 104;
        _stat |= hp << 144;
        _stat |= atk << 176;
        _stat |= def << 192;
        _stat |= atkSpd << 208;
        _stat |= critDmg << 224;
        _stat |= dodgeChance << 240;
    }

    function updateInfluence(
        uint256 oldInfluence,
        uint256 newPopulation,
        uint256 winClan,
        uint256 loseClan,
        uint256 score
    ) internal pure returns (uint256 influence) {
        influence = newPopulation << 240;

        uint256 influenceScore = uint256(uint80(oldInfluence));
        influence |= (
            0 == loseClan
                ? influenceScore - score
                : 0 == winClan
                    ? influenceScore + score
                    : influenceScore
        );

        influenceScore = uint256(uint80(oldInfluence >> (80)));
        influence |=
            (
                1 == loseClan
                    ? influenceScore - score
                    : 1 == winClan
                        ? influenceScore + score
                        : influenceScore
            ) <<
            (80);

        influenceScore = uint256(uint80(oldInfluence >> (160)));
        influence |=
            (
                2 == loseClan
                    ? influenceScore - score
                    : 2 == winClan
                        ? influenceScore + score
                        : influenceScore
            ) <<
            (160);
    }

    function getLocation(uint8 location) internal pure returns (uint256) {
        if (location == 0) return location;
        return (location - 1) % 7;
    }

    function getPatriarch(
        uint256 tokenId
    ) public view returns (address _patriarch, uint256 _alliance) {
        _alliance = patriarchs[tokenId];
        _patriarch = address(uint160(_alliance));
        _alliance >>= 160;
    }

    /// @notice can only be called for kyodai in battle mode
    function getAlliance(uint256 location) internal pure returns (uint256) {
        if (location < 8) revert();
        return (location - 8) / 7;
    }

    //   uint24 scores,
    //   uint8 location,
    //   uint32 currentHP,  || workingDeadline // dual function, to set the determined working deadline
    //   uint40 lastBattle  || startWorking, // dual function, to count neoyen generation if working (location index > 7)
    //   uint40 immunity,
    //   uint32 hp,
    //   uint16 atk,
    //   uint16 def,
    //   uint16 atkSpd,
    //   uint16 critDmg,
    //   uint16 dodgeChance
    /// @dev TODO for checking on development only. Remove before deploying to production
    function getGameStats(
        uint256 tokenId
    )
        public
        view
        returns (
            uint24, // scores,
            uint256, //location,
            uint256, // action,
            uint256, //alliance,
            uint32, // currentHP,
            uint40, //lastBattle,
            uint40 // immunity,
        )
    // uint32, // hp,
    // uint16, // atk,
    // uint16, //def,
    // uint16, //atkSpd,
    // uint16, //critDmg,
    // uint16 //dodge
    {
        uint256 stat = gameStats[tokenId];
        uint256 _location = uint256(uint8(stat));
        return (
            uint24(stat >> 24),
            getLocation(uint8(_location)),
            _location > 7
                ? 2
                : _location == 0
                    ? 0
                    : 1,
            _location < 8 ? 0 : getAlliance(_location),
            uint32(stat >> 32),
            uint40(stat >> 64),
            uint40(stat >> 104)
            // uint32(stat >> 144),
            // uint16(stat >> 176),
            // uint16(stat >> 192),
            // uint16(stat >> 208),
            // uint16(stat >> 224),
            // uint16(stat >> 240)
        );
    }

    function _randomize(
        uint256 rand,
        string memory val,
        uint256 spicy
    ) internal pure returns (uint256) {
        return uint256(keccak256(abi.encode(rand, val, spicy)));
    }

    function _rand() internal view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        msg.sender,
                        block.timestamp,
                        block.basefee,
                        block.timestamp,
                        entropySpice
                    )
                )
            );
    }

    function _updateEntropy() internal {
        entropySpice = keccak256(
            abi.encodePacked(
                tx.origin,
                block.coinbase,
                block.timestamp,
                block.prevrandao
            )
        );
    }

    uint256[42] private __gap;
}

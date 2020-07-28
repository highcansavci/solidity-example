pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "https://github.com/0xcert/ethereum-erc721/blob/master/src/contracts/tokens/erc721.sol";
import "./Ownable.sol";

contract Meow is Ownable, ERC721{
    
    struct Location {
        int64 locX;
        int64 locY;
    }
    
    struct Cat {
        uint256 catId;
        string name;
        uint64 foodAmount;
        Location loc;
    }
    
    struct Food {
        uint256 foodId;
        uint64 amount;
        Location foodLoc;
    }
    
    
    mapping(address => uint8) CatCount;
    mapping(uint256 => address) CatToAddress;
    mapping(address => Cat) AddressToCat;
    mapping(address => uint256) AddressToFoodStashAmount;
    mapping(uint256 => address) FoodAddressMap;
    mapping(uint256 => Food) FoodMap;
    mapping(uint256 => address) FoodApprovals;
    
    event CatAddition(address _from, Cat _newCat);
    event CatAddition(address _from, uint256 _catId, string _name, uint64 _foodAmt, Location _loc);
    event CatAddition(address _from, uint256 _catId, string _name, uint64 _foodAmt, int64 _locX, int64 _locY);
    event FoodAddition(uint256 _foodId, uint64 _amount, Location _foodLoc);
    event FoodAddition(uint256 _foodId, uint64 _amount, int64 _locX, int64 _locY);

    modifier noCatBefore(address _address) {
        require(CatCount[msg.sender] == 0);
        _;
    }
    
    function _generateRandomCatId(string memory _str) private view returns (uint256) {
        return uint(keccak256(abi.encodePacked(_str, now)));
    }
    
    function _findRandomIndex(address _from, address _to, uint64 _length) private view returns(uint64) {
        return uint64(uint256(keccak256(abi.encodePacked(_from, _to, now)))) % _length;
    }
    
    function addCat(Cat memory _ourCat) public noCatBefore(msg.sender) {
        CatToAddress[_ourCat.catId] = msg.sender;
        CatCount[msg.sender]++;
        AddressToCat[msg.sender] = _ourCat;
        emit CatAddition(msg.sender, _ourCat);
    }
    
    function addCat(string memory _name, uint64 _foodAmount, Location memory _loc) public noCatBefore(msg.sender) {
        uint256 _catId = _generateRandomCatId(_name);
        Cat memory _newCat = Cat({catId: _catId, name: _name, foodAmount: _foodAmount, loc: _loc});
        CatToAddress[_catId] = msg.sender;
        CatCount[msg.sender]++;
        AddressToCat[msg.sender] = _newCat;
        emit CatAddition(msg.sender, _catId, _name, _foodAmount, _loc);
    }
    
    function addCat(string memory _name, uint64 _foodAmount, int64 _locX, int64 _locY) public noCatBefore(msg.sender) {
        uint256 _catId = _generateRandomCatId(_name);
        Location memory _newLoc = Location({locX: _locX, locY: _locY});
        Cat memory _newCat = Cat({catId: _catId, name: _name, foodAmount: _foodAmount, loc: _newLoc});
        CatToAddress[_catId] = msg.sender;
        CatCount[msg.sender]++;
        AddressToCat[msg.sender] = _newCat;
        emit CatAddition(msg.sender, _catId, _name, _foodAmount, _locX, _locY);
    }
    
    function addFood(uint64 _foodAmt, Location calldata _loc) external onlyOwner {
        uint256 _foodId = uint256(keccak256(abi.encodePacked(_foodAmt, now)));
        Food memory food = Food({foodId: _foodId, amount: _foodAmt, foodLoc: _loc});
        FoodMap[_foodId] = food;
        FoodAddressMap[_foodId] = msg.sender;
        AddressToFoodStashAmount[msg.sender]++;
        emit FoodAddition(_foodId, _foodAmt, _loc);
    }
    
    function addFood(uint64 _foodAmt, int64 _locX, int64 _locY) external onlyOwner {
        uint256 _foodId = uint256(keccak256(abi.encodePacked(_foodAmt, now)));
        Location memory _loc = Location({locX: _locX, locY: _locY});
        Food memory food = Food({foodId: _foodId, amount: _foodAmt, foodLoc: _loc});
        FoodMap[_foodId] = food;
        FoodAddressMap[_foodId] = msg.sender;
        AddressToFoodStashAmount[msg.sender]++;
        emit FoodAddition(_foodId, _foodAmt, _loc);
    }
    
    function getCatName(address _address) public view returns(string memory) {
        return AddressToCat[_address].name;
    }
    
    function getCatFoodAmount(address _address) public view returns(uint64) {
        return AddressToCat[_address].foodAmount;
    }
    
    function getCatLocation(address _address) public view returns(Location memory) {
        return AddressToCat[_address].loc;
    }
    
    function getFoodAmount(uint256 _foodId) external view returns(uint64) {
        return FoodMap[_foodId].amount;
    }
    
    function getFoodLocation(uint256 _foodId) external view returns(Location memory) {
        return FoodMap[_foodId].foodLoc;
    }
    
    function _transfer(address _from, address _to, uint256 _tokenId) private {
        require(AddressToFoodStashAmount[_from] > 0);
        AddressToCat[_from].loc = FoodMap[_tokenId].foodLoc;
        AddressToCat[_to].loc = FoodMap[_tokenId].foodLoc;
        AddressToCat[_from].foodAmount += FoodMap[_tokenId].amount / 2;
        AddressToCat[_to].foodAmount += FoodMap[_tokenId].amount - FoodMap[_tokenId].amount / 2;
        delete FoodAddressMap[_tokenId];
        delete FoodMap[_tokenId];
        delete FoodApprovals[_tokenId];
        AddressToFoodStashAmount[msg.sender]--;
        emit Transfer(_from, _to, _tokenId);
    }
    
    function balanceOf(address _owner) external view override returns (uint256) {
        return AddressToFoodStashAmount[_owner];
    }
    
    function ownerOf(uint256 _tokenId) external view override returns (address) {
        return FoodAddressMap[_tokenId];
    }
    
    function getApproved(uint256 _tokenId) external view override returns (address) {
        return FoodApprovals[_tokenId];
    }
    
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata _data) external override {
        
    }
    
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external override {
        require (FoodAddressMap[_tokenId] == msg.sender || FoodApprovals[_tokenId] == msg.sender);
        _transfer(_from, _to, _tokenId);
    }
    
    function setApprovalForAll(address _operator, bool _approved) external override {
        
    }
    
    function isApprovedForAll(address _owner, address _operator) external view override returns (bool) {
        
    }
    
    
  
    function transferFrom(address _from, address _to, uint256 _tokenId) external override {
        require (FoodAddressMap[_tokenId] == msg.sender || FoodApprovals[_tokenId] == msg.sender);
        _transfer(_from, _to, _tokenId);
    }

    function approve(address _approved, uint256 _tokenId) external override {
        require(FoodApprovals[_tokenId] == msg.sender);
        FoodApprovals[_tokenId] = _approved;
        emit Approval(msg.sender, _approved, _tokenId);
    }
}

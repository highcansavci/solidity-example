pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "https://github.com/0xcert/ethereum-erc721/blob/master/src/contracts/tokens/erc721.sol";
import "./Ownable.sol";

contract Meow is Ownable, ERC721{
    
     // The point in the Cartesian coordinates.
    struct Location {
        int64 locX;
        int64 locY;
    }
    
     // Information of a cat.
    struct Cat {
        // Attribute of the ID of the cat.
        uint256 catId;
        // Attribute of the name of the cat.
        string name;
        // Attribute of the amount of meal the cat has.
        uint64 foodAmount;
        // Attribute of the location of the cat.
        Location loc;
    }
    
    // Information of a food stash.
    struct Food {
        // Attribute of the ID of the food stash.
        uint256 foodId;
        // Attribute of the amount of meal the food stash has.
        uint64 amount;
        // Attribute of the location of the food.
        Location foodLoc;
    }
    
    // the address of the Ethereum account => the amount of cats
    mapping(address => uint8) CatCount;
    // catID => the address of the Ethereum account
    mapping(uint256 => address) CatToAddress;
    // the address of the Ethereum account => the cat
    mapping(address => Cat) AddressToCat;
    // the address of the Ethereum account => the amount of food stash
    mapping(address => uint256) AddressToFoodStashAmount;
    // foodID => the address of the Ethereum account
    mapping(uint256 => address) FoodAddressMap;
    // foodID => the Food
    mapping(uint256 => Food) FoodMap;
    // foodID => the address of the Ethereum account
    mapping(uint256 => address) FoodApprovals;
    
    // The events when we add the cat to the address of an Ethereum account
    event CatAddition(address _from, Cat _newCat);
    event CatAddition(address _from, uint256 _catId, string _name, uint64 _foodAmt, Location _loc);
    event CatAddition(address _from, uint256 _catId, string _name, uint64 _foodAmt, int64 _locX, int64 _locY);
    // The events when we add the food to the field
    event FoodAddition(uint256 _foodId, uint64 _amount, Location _foodLoc);
    event FoodAddition(uint256 _foodId, uint64 _amount, int64 _locX, int64 _locY);
    // The events when we complete the transfer
    event Transfer(address _from, address _to, uint256 _tokenId);
    // The event when getting the approval of transfering the food to the specific receiver
    event Approval(address _from, address _to, uint256 _tokenId);
    
    // Checking if whether the user has a cat or not
    modifier noCatBefore(address _address) {
        require(CatCount[msg.sender] == 0);
        _;
    }
    
    // Generates random cat ID
    function _generateRandomCatId(string memory _str) private view returns (uint256) {
        return uint(keccak256(abi.encodePacked(_str, now)));
    }
    
    // Generates random index
    function _findRandomIndex(address _from, address _to, uint64 _length) private view returns(uint64) {
        return uint64(uint256(keccak256(abi.encodePacked(_from, _to, now)))) % _length;
    }
    
    // Adds a cat to the address of the Ethereum account
    function addCat(Cat memory _ourCat) public noCatBefore(msg.sender) {
        CatToAddress[_ourCat.catId] = msg.sender;
        CatCount[msg.sender]++;
        AddressToCat[msg.sender] = _ourCat;
        // Invokes the cat addition event
        emit CatAddition(msg.sender, _ourCat);
    }
    
    function addCat(string memory _name, uint64 _foodAmount, Location memory _loc) public noCatBefore(msg.sender) {
        uint256 _catId = _generateRandomCatId(_name);
        Cat memory _newCat = Cat({catId: _catId, name: _name, foodAmount: _foodAmount, loc: _loc});
        CatToAddress[_catId] = msg.sender;
        CatCount[msg.sender]++;
        AddressToCat[msg.sender] = _newCat;
        // Invokes the cat addition event
        emit CatAddition(msg.sender, _catId, _name, _foodAmount, _loc);
    }
    
    function addCat(string memory _name, uint64 _foodAmount, int64 _locX, int64 _locY) public noCatBefore(msg.sender) {
        uint256 _catId = _generateRandomCatId(_name);
        Location memory _newLoc = Location({locX: _locX, locY: _locY});
        Cat memory _newCat = Cat({catId: _catId, name: _name, foodAmount: _foodAmount, loc: _newLoc});
        CatToAddress[_catId] = msg.sender;
        CatCount[msg.sender]++;
        AddressToCat[msg.sender] = _newCat;
        // Invokes the cat addition event
        emit CatAddition(msg.sender, _catId, _name, _foodAmount, _locX, _locY);
    }
    
    // Adds the food to the address of the Ethereum account
    function addFood(uint64 _foodAmt, Location calldata _loc) external onlyOwner {
        uint256 _foodId = uint256(keccak256(abi.encodePacked(_foodAmt, now)));
        Food memory food = Food({foodId: _foodId, amount: _foodAmt, foodLoc: _loc});
        FoodMap[_foodId] = food;
        FoodAddressMap[_foodId] = msg.sender;
        AddressToFoodStashAmount[msg.sender]++;
        // Invokes the food addition event
        emit FoodAddition(_foodId, _foodAmt, _loc);
    }
    
    function addFood(uint64 _foodAmt, int64 _locX, int64 _locY) external onlyOwner {
        uint256 _foodId = uint256(keccak256(abi.encodePacked(_foodAmt, now)));
        Location memory _loc = Location({locX: _locX, locY: _locY});
        Food memory food = Food({foodId: _foodId, amount: _foodAmt, foodLoc: _loc});
        FoodMap[_foodId] = food;
        FoodAddressMap[_foodId] = msg.sender;
        AddressToFoodStashAmount[msg.sender]++;
        // Invokes the food addition event
        emit FoodAddition(_foodId, _foodAmt, _loc);
    }
    
    // Getters and setters of the smart contract
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
    
    // Generate the transfer action
    function _transfer(address _from, address _to, uint256 _tokenId) private {
        // Check whether the sender has to have at least one food stash.
        require(AddressToFoodStashAmount[_from] > 0);
        // The cats of the sender and the receiver meet at the location of the food stash.
        AddressToCat[_from].loc = FoodMap[_tokenId].foodLoc;
        AddressToCat[_to].loc = FoodMap[_tokenId].foodLoc;
        // The amount of food they have will increase by the half amount of food in the food stash.
        AddressToCat[_from].foodAmount += FoodMap[_tokenId].amount / 2;
        AddressToCat[_to].foodAmount += FoodMap[_tokenId].amount - FoodMap[_tokenId].amount / 2;
        // The opened food stash will be deleted from the memory.
        delete FoodAddressMap[_tokenId];
        delete FoodMap[_tokenId];
        delete FoodApprovals[_tokenId];
        // The sender’s amount of food stash will decrease by one.
        AddressToFoodStashAmount[msg.sender]--;
        // Generating the event Transfer.
        emit Transfer(_from, _to, _tokenId);
    }
    
    // Get the amount of food stash of the owner address
    function balanceOf(address _owner) external view override returns (uint256) {
        return AddressToFoodStashAmount[_owner];
    }
    
    // Get the owner address of the food stash
    function ownerOf(uint256 _tokenId) external view override returns (address) {
        return FoodAddressMap[_tokenId];
    }
    
    // Get the approval of the shared food stash from the owner
    function getApproved(uint256 _tokenId) external view override returns (address) {
        return FoodApprovals[_tokenId];
    }
    
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata _data) external override {
        
    }
    
    // Safely transfer the contents of food stash 
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external override {
        // The sender must own the food stash and he must approve transfering the stash to the specific receiver
        require (FoodAddressMap[_tokenId] == msg.sender || FoodApprovals[_tokenId] == msg.sender);
        // Start the process of transfer
        _transfer(_from, _to, _tokenId);
    }
    
    function setApprovalForAll(address _operator, bool _approved) external override {
        
    }
    
    function isApprovedForAll(address _owner, address _operator) external view override returns (bool) {
        
    }
    
    // Transfer the contents of food stash 
    function transferFrom(address _from, address _to, uint256 _tokenId) external override {
        // The sender must own the food stash and he must approve transfering the stash to the specific receiver
        require (FoodAddressMap[_tokenId] == msg.sender || FoodApprovals[_tokenId] == msg.sender);
        // Start the process of transfer
        _transfer(_from, _to, _tokenId);
    }
    
    // Approve the purchase of food stash
    function approve(address _approved, uint256 _tokenId) external override {
        // The owner of the food stash must approve transfering the stash to the approved receiver
        require(FoodApprovals[_tokenId] == msg.sender);
        // Approve the new owner of the existing food stash
        FoodApprovals[_tokenId] = _approved;
        // Generating the event Approval
        emit Approval(msg.sender, _approved, _tokenId);
    }
}

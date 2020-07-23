pragma solidity >=0.4.0 <0.7.0;
pragma experimental ABIEncoderV2;
import "https://github.com/witnet/elliptic-curve-solidity/blob/master/contracts/EllipticCurve.sol";

contract KeySharing {
    
    // Elliptic Curve: y ** 2 = x ** 3 + 7 (secp256k1)
    uint256 public constant GlobalX = 0x79BE667EF9DCBBAC55A06295CE870B07029BFCDB2DCE28D959F2815B16F81798;
    uint256 public constant GlobalY = 0x483ADA7726A3C4655DA4FBFC0E1108A8FD17B448A68554199C47D08FFB10D4B8;
    uint256 public constant AA = 0;
    uint256 public constant BB = 7;
    uint256 public constant PP = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F;
    // Enumerate the cat is hungry or not.
    enum HungryStatus{Full, Hungry}
  
    // The point in the elliptic curve.
    struct GXY {
        uint256 GX;
        uint256 GY;
    }
    
    // Information of a cat.
    struct Cat {
        string name;
        // Attribute of daily age.
        uint16 ageDaily;
        // Attribute of the amount of meal.
        uint16 amountMeal;
        // Attribute of the amount of food a cat eats
        uint16 amountAte;
        // Survival of the cat.
        uint16 durability;
        GXY coords;
        HungryStatus status;
    }
    
    // catId => Specific Cat
    mapping(uint32 => Cat) CatMap;
    // catId => Private Key of the Cat
    mapping(uint32 => uint256) PrivKeyMap;
    // catId => Point of the Cat in the Elliptic Curve
    mapping(uint32 => GXY) OtherPubKeyMap;
    
    function addCat(uint32 _catId, string memory _name, uint16 _ageDaily, uint16 _amountMeal, uint16 _amountAte, uint16 _durability, GXY memory _coords) public {
        // Lifespan: 15 years * 365 days
        require(_ageDaily < 5475);
        CatMap[_catId] = Cat({name:_name, ageDaily:_ageDaily, amountMeal:_amountMeal, amountAte:_amountAte, durability: _durability, coords:_coords, status: HungryStatus.Hungry});
    }
    
    function getMealAmount(uint32 _catId) public view returns(uint16) {
        return CatMap[_catId].amountMeal;
    }
    
    function getMealNeeded(uint32 _catId) public view returns(uint16) {
        return CatMap[_catId].amountAte;
    }
    
    function getName(uint32 _catId) public view returns(string memory) {
        return CatMap[_catId].name;
    }
    
    function getAge(uint32 _catId) public view returns(uint16) {
        return CatMap[_catId].ageDaily;
    }
    
    function calculateHunger(uint32 _catId) public {
        CatMap[_catId].amountAte = (CatMap[_catId].ageDaily - 5475) ** 2 / 250;
    }
    
    // Searching for the food.
    function findMeal(uint32 _catId, uint16 _addMeal) public {
        CatMap[_catId].amountMeal += _addMeal;
        // Increase the surviving point of the cat.
        CatMap[_catId].durability += 1;
    }
    
    // Eating and surviving process of the cat.
    function eatMeal(uint32 _catId) public {
        Cat memory kitty = CatMap[_catId];
        // Check if the kitty is hungry.
        require(kitty.status == HungryStatus.Hungry);
        // Eat the meal.
        kitty.amountMeal -= kitty.amountAte;
        kitty.status = HungryStatus.Full;
        // Sleep and increase your daily age.
        kitty.ageDaily += 1;
        // Be hungry again.
        kitty.status = HungryStatus.Hungry;
        calculateHunger(_catId);
    }
    
    function generateCommonPoint(uint32 _catId, uint32 _otherCatId) public view {
        Cat memory first_kitty = CatMap[_catId];
        Cat memory second_kitty = CatMap[_otherCatId];
        first_kitty.coords.GX = GlobalX;
        first_kitty.coords.GY = GlobalY;
        second_kitty.coords.GX = GlobalX;
        second_kitty.coords.GY = GlobalY;
    }
    
    // Deriving the public key of the cat.
    function derivePubKey(uint32 _catId) public view returns(GXY memory) {
        Cat memory kitty = CatMap[_catId];
        uint256 qx;
        uint256 qy;
        // Get the private key.
        uint256 privKey = PrivKeyMap[_catId];
        // Checking if the private key is not 0.
        require(privKey != 0);
        // Checking if the point of the cat is on the elliptic curve.
        require(EllipticCurve.isOnCurve(kitty.coords.GX, kitty.coords.GY, AA, BB, PP));
        // Perform elliptic curve multiplication.
        (qx, qy) = EllipticCurve.ecMul(privKey, kitty.coords.GX, kitty.coords.GY, AA, PP);
        // Get the resulting coords.
        GXY memory _coords = GXY({GX: qx, GY: qy});
        return _coords;
    }
    
    function generatePrivKey(uint32 _catId) public view returns(uint256) {
        uint16 age = CatMap[_catId].ageDaily;
        uint16 durable = CatMap[_catId].durability;
        return uint256(keccak256(abi.encode(age ** durable)));
    }
    
    function exchangeKeys(uint32 _catId, uint32 _otherCatId) public {
        // Calculate the public keys and exchange the keys.
        OtherPubKeyMap[_otherCatId] = derivePubKey(_catId);
        OtherPubKeyMap[_catId] = derivePubKey(_otherCatId);
    }
    
    function twoKittensSharing(uint32 _catId, uint32 _otherCatId) public {
        // Perform the scenario.
        Cat memory first_kitten = CatMap[_catId];
        Cat memory second_kitten = CatMap[_otherCatId];
        uint16 sharedFood;
        uint256 first_gx;
        uint256 first_gy;
        uint256 second_gx;
        uint256 second_gy;
        
        // If the both kittens are broke, then they share the place of the food.
        if(first_kitten.amountMeal < first_kitten.amountAte || second_kitten.amountMeal < second_kitten.amountAte) {
            uint256 first_pk = generatePrivKey(_catId);
            uint256 second_pk = generatePrivKey(_otherCatId);
            PrivKeyMap[_catId] = first_pk;
            PrivKeyMap[_otherCatId] = second_pk;
            generateCommonPoint(_catId, _otherCatId);
            exchangeKeys(_catId, _otherCatId);
            (first_gx, first_gy) = EllipticCurve.ecMul(first_pk, OtherPubKeyMap[_catId].GX, OtherPubKeyMap[_catId].GY, AA, PP);
            (second_gx, second_gy) = EllipticCurve.ecMul(second_pk, OtherPubKeyMap[_otherCatId].GX, OtherPubKeyMap[_otherCatId].GY, AA, PP);
            // They must obtain the shared key to continue.
            require(first_gx == second_gx && first_gy == second_gy);
            findMeal(_catId, 10000);
            findMeal(_otherCatId, 10000);
            // Generate the new private key for both kittens.
            PrivKeyMap[_catId] = generatePrivKey(_catId);
            PrivKeyMap[_otherCatId] = generatePrivKey(_otherCatId);
            
        }
        
        // They share the food if the amount of food is enough for at least one kitten.
        else if(first_kitten.amountMeal < first_kitten.amountAte && second_kitten.amountMeal > second_kitten.amountAte) {
            sharedFood = second_kitten.amountMeal / 2;
            second_kitten.amountMeal -= sharedFood;
            first_kitten.amountMeal += sharedFood;
        }
        else if(first_kitten.amountMeal > first_kitten.amountAte && second_kitten.amountMeal < second_kitten.amountAte) {
            sharedFood = first_kitten.amountMeal / 2;
            first_kitten.amountMeal -= sharedFood;
            second_kitten.amountMeal += sharedFood;
        }
        eatMeal(_catId);
        eatMeal(_otherCatId);
    }
}

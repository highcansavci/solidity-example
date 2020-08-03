pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "https://github.com/witnet/elliptic-curve-solidity/blob/master/contracts/EllipticCurve.sol";

contract Pedersen {
    
    struct ECurve {
        uint256 eca;
        uint256 ecb;
        uint256 prime;
    }
    
    struct GPoint {
        uint256 gx;
        uint256 gy;
    } 
    
    mapping(address => ECurve) ECurveMap;
    modifier isOnCurve(uint256 _gx, uint256 _gy, address _address) {
        require(EllipticCurve.isOnCurve(_gx, _gy, ECurveMap[msg.sender].eca, ECurveMap[msg.sender].ecb, ECurveMap[msg.sender].prime));
        _;
    }
    
    function setupEC(uint256 _eca, uint256 _ecb, uint256 _prime) public  {
        ECurve memory _ec = ECurve({eca:_eca, ecb:_ecb, prime: _prime});
        ECurveMap[msg.sender] = _ec;
    }
    
    function generateRandom() internal view returns(uint256)  {
        return uint256(keccak256(abi.encodePacked(ECurveMap[msg.sender].eca, ECurveMap[msg.sender].ecb, ECurveMap[msg.sender].prime, now)));
    }
    
    function generateH(uint256 _gx, uint256 _gy) public view isOnCurve(_gx, _gy, msg.sender) returns(uint256, uint256)  {
        return EllipticCurve.ecMul(generateRandom(), _gx, _gy, ECurveMap[msg.sender].eca, ECurveMap[msg.sender].prime);
    }
    
    function generateHKnown(uint256 _r, uint256 _gx, uint256 _gy) public view isOnCurve(_gx, _gy, msg.sender) returns(uint256, uint256)  {
        return EllipticCurve.ecMul(_r, _gx, _gy, ECurveMap[msg.sender].eca, ECurveMap[msg.sender].prime);
    }
    
    //   add two known values with blinding factors
    //   and compute the committed value
    //   add rX + rY (blinding factor private keys)
    //   add vX + vY (hidden values)
    function addPrivately(GPoint memory _g,  GPoint memory _H, uint256 _rx, uint256 _ry, uint256 _vx, uint256 _vy) public view isOnCurve(_g.gx, _g.gy, msg.sender) returns(uint256, uint256) {
        GPoint memory _rz;
        GPoint memory _rk;
        (_rz.gx, _rz.gy)=  EllipticCurve.ecMul(_rx + _ry, _g.gx, _g.gy, ECurveMap[msg.sender].eca, ECurveMap[msg.sender].prime);
        (_rk.gx, _rk.gy) =  EllipticCurve.ecMul(_vx + _vy, _H.gx, _H.gy, ECurveMap[msg.sender].eca, ECurveMap[msg.sender].prime);
        return EllipticCurve.ecAdd(_rz.gx, _rz.gy, _rk.gx, _rk.gy, ECurveMap[msg.sender].eca, ECurveMap[msg.sender].prime);
    }
    
    //   subtract two known values with blinding factors
    //   and compute the committed value
    //   add rX - rY (blinding factor private keys)
    //   add vX - vY (hidden values)
    function subPrivately(GPoint memory _g,  GPoint memory _H, uint256 _rx, uint256 _ry, uint256 _vx, uint256 _vy) public view isOnCurve(_g.gx, _g.gy, msg.sender) returns(uint256, uint256) {
        GPoint memory _rz;
        GPoint memory _rk;
        (_rz.gx, _rz.gy)=  EllipticCurve.ecMul(_rx - _ry, _g.gx, _g.gy, ECurveMap[msg.sender].eca, ECurveMap[msg.sender].prime);
        (_rk.gx, _rk.gy) =  EllipticCurve.ecMul(_vx - _vy, _H.gx, _H.gy, ECurveMap[msg.sender].eca, ECurveMap[msg.sender].prime);
        return EllipticCurve.ecAdd(_rz.gx, _rz.gy, _rk.gx, _rk.gy, ECurveMap[msg.sender].eca, ECurveMap[msg.sender].prime);
    }
    
    //   commit to a value _value
    //   _r - private Key used as blinding factor
    //   H - the point on the curve generated from shared point g
    function commitTo(uint256 _gx, uint256 _gy, uint256 _Hx, uint256 _Hy, uint256 _r, uint256 _value) public view isOnCurve(_gx, _gy, msg.sender) returns(uint256, uint256) {
        (uint256 rz_x, uint256 rz_y) =  EllipticCurve.ecMul(_r, _gx, _gy, ECurveMap[msg.sender].eca, ECurveMap[msg.sender].prime);
        (uint256 rk_x, uint256 rk_y) =  EllipticCurve.ecMul(_value, _Hx, _Hy, ECurveMap[msg.sender].eca, ECurveMap[msg.sender].prime);
        return EllipticCurve.ecAdd(rz_x, rz_y, rk_x, rk_y, ECurveMap[msg.sender].eca, ECurveMap[msg.sender].prime);
    }
    
    function verify(uint256 _gx, uint256 _gy, uint256 _Hx, uint256 _Hy, uint256 _commitX, uint256 _commitY, uint256 _r, uint256 _value) public view isOnCurve(_gx, _gy, msg.sender) returns(bool) {
        (uint256 c_x, uint256 c_y) = commitTo(_gx, _gy, _Hx, _Hy, _r, _value);
        return c_x == _commitX && c_y == _commitY;
    }
}

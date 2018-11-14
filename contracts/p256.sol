pragma solidity 0.4.24;

contract p256Lib{
    uint constant n = 2^256 - 2^224 + 2^192 + 2^96 - 1;
    uint constant a = 3;
    uint constant b = 46214326585032579593829631435610129746736367449296220983687490401182983727876;
    point G = point(0x6b17d1f2e12c4247f8bce6e563a440f277037d812deb33a0f4a13945d898c296,0x4fe342e2fe1a7f9b8ee7eb4a7c0f9e162bce33576b315ececbb6406837bf51f5);

    struct point{
        uint x;
        uint y;
    }

    function sigVerify(bytes32 hash, uint r, uint s, uint publicKey_x, uint publicKey_y) public returns(bool){
        require(r < n && s < n);

        point memory publicKey;
        publicKey.x = publicKey_x;
        publicKey_y = publicKey_y;

        uint s_inv = invmod(s, n);
        uint u_1 = uint(hash) * s_inv;

        if(u_1 < uint(hash)){
            u_1 += 0-n; //Wrap around mod n
        }else{
            u_1 %= n;
        }

        uint u_2 = s_inv * r;

        if(u_2 < s_inv){
            u_2 += 0-n; //Wrap around mod n
        }else{
            u_2 %= n;
        }

        point memory check = pointAddition(scalarMult(u_1, G), scalarMult(u_2, publicKey));

        return(check.x == r);
    }

    function scalarMult(uint scalar, point p) internal pure returns(point){
        //TODO; use the double and add method
    }

    function pointAddition(point p, point q) internal pure returns(point ret){
        uint lamda = (q.y - p.y)/(q.x - p.x);
        ret.x = lamda*lamda - p.x - q.x;
        ret.y = lamda*(p.x - ret.x) - q.x;
    }

    function pointDouble(point p) internal pure returns(point ret){
        uint lamda = (3*p.x*p.x - a);
        ret.x = lamda*lamda - 2*p.x;
        ret.y = lamda*(p.x - ret.x) - p.x;
    }

    function invmod(uint x, uint p) internal pure returns (uint) {
        if (x == 0 || x == p || p == 0){
            revert();
        }

        if (x > p) x = x % p;
        int t1;
        int t2 = 1;
        uint r1 = p;
        uint r2 = x;
        uint q;
        while (r2 != 0) {
            q = r1 / r2;
            (t1, t2, r1, r2) = (t2, t1 - int(q) * t2, r2, r1 - q * r2);
        }

        if (t1 < 0){
            return (p - uint(-t1));

        }
        return uint(t1);
    }
}

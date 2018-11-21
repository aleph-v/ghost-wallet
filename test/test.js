let Curve = artifacts.require("p256Lib");

contract('Curve Test', (accounts) => {
  describe('Should validate signature example', async () => {
    it('Return True', async () => {
      let p256 = await Curve.new();
      await p256.verify("0xa41a41a12a799548211c410c65d8133afde34d28bdd542e4b680cf2899c8a8c4","0x2b42f576d07f4165ff65d1f3b1500f81e44c316f1f0b3ef57325b69aca46104f","0xdc42c2122d6392cd3e3a993a89502a8198c1886fe69d262c4b329bdb6b63faf1","0xb7e08afdfe94bad3f1dc8c734798ba1c62b3a0ad1e9ea2a38201cd0889bc7a19","0x3603f747959dbf7a4bb226e41928729063adc7ae43529e61b563bbc606cc5e09").then( (resp) =>{
        console.log(resp.receipt.gasUsed);
      });
    })
  })
})

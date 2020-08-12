const BN = web3.utils.BN

function keccakParentOf (left, right) {
  return new BN(
    web3.utils.hexToNumberString(
      web3.utils.soliditySha3(
        web3.eth.abi.encodeParameters(['uint256', 'uint256'], [left, right])
      )
    )
  )
}

const keccakPreHashed = [
  new BN(
    web3.utils.hexToNumberString(
      '0x0000000000000000000000000000000000000000000000000000000000000000'
    )
  ),
  new BN(
    web3.utils.hexToNumberString(
      '0xad3228b676f7d3cd4284a5443f17f1962b36e491b30a40b2405849e597ba5fb5'
    )
  ),
  new BN(
    web3.utils.hexToNumberString(
      '0xb4c11951957c6f8f642c4af61cd6b24640fec6dc7fc607ee8206a99e92410d30'
    )
  ),
  new BN(
    web3.utils.hexToNumberString(
      '0x21ddb9a356815c3fac1026b6dec5df3124afbadb485c9ba5a3e3398a04b7ba85'
    )
  ),
  new BN(
    web3.utils.hexToNumberString(
      '0xe58769b32a1beaf1ea27375a44095a0d1fb664ce2dd358e7fcbfb78c26a19344'
    )
  ),
  new BN(
    web3.utils.hexToNumberString(
      '0xeb01ebfc9ed27500cd4dfc979272d1f0913cc9f66540d7e8005811109e1cf2d'
    )
  ),
  new BN(
    web3.utils.hexToNumberString(
      '0x887c22bd8750d34016ac3c66b5ff102dacdd73f6b014e710b51e8022af9a1968'
    )
  ),
  new BN(
    web3.utils.hexToNumberString(
      '0xffd70157e48063fc33c97a050f7f640233bf646cc98d9524c6b92bcf3ab56f83'
    )
  ),
  new BN(
    web3.utils.hexToNumberString(
      '0x9867cc5f7f196b93bae1e27e6320742445d290f2263827498b54fec539f756af'
    )
  ),
  new BN(
    web3.utils.hexToNumberString(
      '0xcefad4e508c098b9a7e1d8feb19955fb02ba9675585078710969d3440f5054e0'
    )
  ),
  new BN(
    web3.utils.hexToNumberString(
      '0xf9dc3e7fe016e050eff260334f18a5d4fe391d82092319f5964f2e2eb7c1c3a5'
    )
  ),
  new BN(
    web3.utils.hexToNumberString(
      '0xf8b13a49e282f609c317a833fb8d976d11517c571d1221a265d25af778ecf892'
    )
  ),
  new BN(
    web3.utils.hexToNumberString(
      '0x3490c6ceeb450aecdc82e28293031d10c7d73bf85e57bf041a97360aa2c5d99c'
    )
  ),
  new BN(
    web3.utils.hexToNumberString(
      '0xc1df82d9c4b87413eae2ef048f94b4d3554cea73d92b0f7af96e0271c691e2bb'
    )
  ),
  new BN(
    web3.utils.hexToNumberString(
      '0x5c67add7c6caf302256adedf7ab114da0acfe870d449a3a489f781d659e8becc'
    )
  ),
  new BN(
    web3.utils.hexToNumberString(
      '0xda7bce9f4e8618b6bd2f4132ce798cdc7a60e7e1460a7299e3c6342a579626d2'
    )
  ),
  new BN(
    web3.utils.hexToNumberString(
      '0x2733e50f526ec2fa19a22b31e8ed50f23cd1fdf94c9154ed3a7609a2f1ff981f'
    )
  ),
  new BN(
    web3.utils.hexToNumberString(
      '0xe1d3b5c807b281e4683cc6d6315cf95b9ade8641defcb32372f1c126e398ef7a'
    )
  ),
  new BN(
    web3.utils.hexToNumberString(
      '0x5a2dce0a8a7f68bb74560f8f71837c2c2ebbcbf7fffb42ae1896f13f7c7479a0'
    )
  ),
  new BN(
    web3.utils.hexToNumberString(
      '0xb46a28b6f55540f89444f63de0378e3d121be09e06cc9ded1c20e65876d36aa0'
    )
  ),
  new BN(
    web3.utils.hexToNumberString(
      '0xc65e9645644786b620e2dd2ad648ddfcbf4a7e5b1a3a4ecfe7f64667a3f0b7e2'
    )
  ),
  new BN(
    web3.utils.hexToNumberString(
      '0xf4418588ed35a2458cffeb39b93d26f18d2ab13bdce6aee58e7b99359ec2dfd9'
    )
  ),
  new BN(
    web3.utils.hexToNumberString(
      '0x5a9c16dc00d6ef18b7933a6f8dc65ccb55667138776f7dea101070dc8796e377'
    )
  ),
  new BN(
    web3.utils.hexToNumberString(
      '0x4df84f40ae0c8229d0d6069e5c8f39a7c299677a09d367fc7b05e3bc380ee652'
    )
  ),
  new BN(
    web3.utils.hexToNumberString(
      '0xcdc72595f74c7b1043d0e1ffbab734648c838dfb0527d971b602bc216c9619ef'
    )
  ),
  new BN(
    web3.utils.hexToNumberString(
      '0xabf5ac974a1ed57f4050aa510dd9c74f508277b39d7973bb2dfccc5eeb0618d'
    )
  ),
  new BN(
    web3.utils.hexToNumberString(
      '0xb8cd74046ff337f0a7bf2c8e03e10f642c1886798d71806ab1e888d9e5ee87d0'
    )
  ),
  new BN(
    web3.utils.hexToNumberString(
      '0x838c5655cb21c6cb83313b5a631175dff4963772cce9108188b34ac87c81c41e'
    )
  ),
  new BN(
    web3.utils.hexToNumberString(
      '0x662ee4dd2dd7b2bc707961b1e646c4047669dcb6584f0d8d770daf5d7e7deb2e'
    )
  ),
  new BN(
    web3.utils.hexToNumberString(
      '0x388ab20e2573d171a88108e79d820e98f26c0b84aa8b2f4aa4968dbb818ea322'
    )
  ),
  new BN(
    web3.utils.hexToNumberString(
      '0x93237c50ba75ee485f4c22adf2f741400bdf8d6a9cc7df7ecae576221665d735'
    )
  ),
  new BN(
    web3.utils.hexToNumberString(
      '0x8448818bb4ae4562849e949e17ac16e0be16688e156b5cf15e098c627c0056a9'
    )
  ),
  new BN(
    web3.utils.hexToNumberString(
      '0x27ae5ba08d7291c96c8cbddcc148bf48a6d68c7974b94356f53754ef6171d757'
    )
  ),
  new BN(
    web3.utils.hexToNumberString(
      '0xbf558bebd2ceec7f3c5dce04a4782f88c2c6036ae78ee206d0bc5289d20461a2'
    )
  ),
  new BN(
    web3.utils.hexToNumberString(
      '0xe21908c2968c0699040a6fd866a577a99a9d2ec88745c815fd4a472c789244da'
    )
  ),
  new BN(
    web3.utils.hexToNumberString(
      '0xae824d72ddc272aab68a8c3022e36f10454437c1886f3ff9927b64f232df414f'
    )
  ),
  new BN(
    web3.utils.hexToNumberString(
      '0x27e429a4bef3083bc31a671d046ea5c1f5b8c3094d72868d9dfdc12c7334ac5f'
    )
  ),
  new BN(
    web3.utils.hexToNumberString(
      '0x743cc5c365a9a6a15c1f240ac25880c7a9d1de290696cb766074a1d83d927816'
    )
  ),
  new BN(
    web3.utils.hexToNumberString(
      '0x4adcf616c3bfabf63999a01966c998b7bb572774035a63ead49da73b5987f347'
    )
  ),
  new BN(
    web3.utils.hexToNumberString(
      '0x75786645d0c5dd7c04a2f8a75dcae085213652f5bce3ea8b9b9bedd1cab3c5e9'
    )
  ),
  new BN(
    web3.utils.hexToNumberString(
      '0xb88b152c9b8a7b79637d35911848b0c41e7cc7cca2ab4fe9a15f9c38bb4bb939'
    )
  ),
  new BN(
    web3.utils.hexToNumberString(
      '0xc4e2d8ce834ffd7a6cd85d7113d4521abb857774845c4291e6f6d010d97e318'
    )
  ),
  new BN(
    web3.utils.hexToNumberString(
      '0x5bc799d83e3bb31501b3da786680df30fbc18eb41cbce611e8c0e9c72f69571c'
    )
  ),
  new BN(
    web3.utils.hexToNumberString(
      '0xa10d3ef857d04d9c03ead7c6317d797a090fa1271ad9c7addfbcb412e9643d4f'
    )
  ),
  new BN(
    web3.utils.hexToNumberString(
      '0xb33b1809c42623f474055fa9400a2027a7a885c8dfa4efe20666b4ee27d7529c'
    )
  ),
  new BN(
    web3.utils.hexToNumberString(
      '0x134d7f28d53f175f6bf4b62faa2110d5b76f0f770c15e628181c1fcc18f970a9'
    )
  ),
  new BN(
    web3.utils.hexToNumberString(
      '0xc34d24b2fc8c50ca9c07a7156ef4e5ff4bdf002eda0b11c1d359d0b59a546807'
    )
  ),
  new BN(
    web3.utils.hexToNumberString(
      '0x4dbb9db631457879b27e0dfdbe50158fd9cf9b4cf77605c4ac4c95bd65fc9f6'
    )
  ),
  new BN(
    web3.utils.hexToNumberString(
      '0xf9295a686647cb999090819cda700820c282c613cedcd218540bbc6f37b01c65'
    )
  ),
  new BN(
    web3.utils.hexToNumberString(
      '0x67c4a1ea624f092a3a5cca2d6f0f0db231972fce627f0ecca0dee60f17551c5f'
    )
  ),
  new BN(
    web3.utils.hexToNumberString(
      '0x8fdaeb5ab560b2ceb781cdb339361a0fbee1b9dffad59115138c8d6a70dda9cc'
    )
  ),
  new BN(
    web3.utils.hexToNumberString(
      '0xc1bf0bbdd7fee15764845db875f6432559ff8dbc9055324431bc34e5b93d15da'
    )
  ),
  new BN(
    web3.utils.hexToNumberString(
      '0x307317849eccd90c0c7b98870b9317c15a5959dcfb84c76dcc908c4fe6ba9212'
    )
  ),
  new BN(
    web3.utils.hexToNumberString(
      '0x6339bf06e458f6646df5e83ba7c3d35bc263b3222c8e9040068847749ca8e8f9'
    )
  ),
  new BN(
    web3.utils.hexToNumberString(
      '0x5045e4342aeb521eb3a5587ec268ed3aa6faf32b62b0bc41a9d549521f406fc3'
    )
  ),
  new BN(
    web3.utils.hexToNumberString(
      '0x8601d83cdd34b5f7b8df63e7b9a16519d35473d0b89c317beed3d3d9424b253'
    )
  ),
  new BN(
    web3.utils.hexToNumberString(
      '0x84e35c5d92171376cae5c86300822d729cd3a8479583bef09527027dba5f1126'
    )
  ),
  new BN(
    web3.utils.hexToNumberString(
      '0x3c5cbbeb3834b7a5c1cba9aa5fee0c95ec3f17a33ec3d8047fff799187f5ae20'
    )
  ),
  new BN(
    web3.utils.hexToNumberString(
      '0x40bbe913c226c34c9fbe4389dd728984257a816892b3cae3e43191dd291f0eb5'
    )
  ),
  new BN(
    web3.utils.hexToNumberString(
      '0x14af5385bcbb1e4738bbae8106046e6e2fca42875aa5c000c582587742bcc748'
    )
  ),
  new BN(
    web3.utils.hexToNumberString(
      '0x72f29656803c2f4be177b1b8dd2a5137892b080b022100fde4e96d93ef8c96ff'
    )
  ),
  new BN(
    web3.utils.hexToNumberString(
      '0xd06f27061c734d7825b46865d00aa900e5cc3a3672080e527171e1171aa5038a'
    )
  ),
  new BN(
    web3.utils.hexToNumberString(
      '0x28203985b5f2d87709171678169739f957d2745f4bfa5cc91e2b4bd9bf483b40'
    )
  ),
  new BN(
    web3.utils.hexToNumberString(
      '0xa162946e56158bac0673e6dd3bdfdc1e4a0e7744a120fdb640050c8d7abe1c6'
    )
  ),
  new BN(
    web3.utils.hexToNumberString(
      '0xe2c3ed4052eeb1d60514b4c38ece8d73a27f37fa5b36dcbf338e70de95798caa'
    )
  ),
  new BN(
    web3.utils.hexToNumberString(
      '0x926bf520e7f453db475da42b994d9447de1f93ee91502a64748e371ed0d1207e'
    )
  ),
  new BN(
    web3.utils.hexToNumberString(
      '0x7516de2f5995cfafacfd70e1a2067241740388d324343a1eb5e71a10f6bb3298'
    )
  ),
  new BN(
    web3.utils.hexToNumberString(
      '0xea5466fc04d601ab583158b9c6626cfbb66640d7dc229afaa59fd52ff415180b'
    )
  ),
  new BN(
    web3.utils.hexToNumberString(
      '0x806f45e88b008f79b47585bdf322be73560cb09d6cac65534e8764bae68a607e'
    )
  ),
  new BN(
    web3.utils.hexToNumberString(
      '0x8456107723bf83d4a67be05860c6730f8540e49ca0f515344ca83a076c622ff5'
    )
  ),
  new BN(
    web3.utils.hexToNumberString(
      '0x9837f794827f98f048587b3f2d2b67817b34821097cc60069dd15d62ee52273d'
    )
  ),
  new BN(
    web3.utils.hexToNumberString(
      '0xcfbd2781f72955df5e33fc4b304fc362fb1637974575f166768f56da09b1fc9'
    )
  ),
  new BN(
    web3.utils.hexToNumberString(
      '0x98fdc3f9b823005b507065b58c622aac45efeda41706775668b37a230d8aff9e'
    )
  ),
  new BN(
    web3.utils.hexToNumberString(
      '0xdf0b5e5db8973fa136e3fba2faabd16677494266a1bdc6b0a8dd7aa187b560b2'
    )
  ),
  new BN(
    web3.utils.hexToNumberString(
      '0xe67efc7167068b5ca5fddeecd68727dce6b03962f356df86edf32581c5e2f142'
    )
  ),
  new BN(
    web3.utils.hexToNumberString(
      '0xac692525a14b469fa4c0069eff411001aac6c42d3438f043eb9c3115ec79b546'
    )
  ),
  new BN(
    web3.utils.hexToNumberString(
      '0x420f9e2a54121eef63530c80909eaed61fffacb8af31074df795e8d16d9d77c0'
    )
  ),
  new BN(
    web3.utils.hexToNumberString(
      '0x572b220bc6da4cc990acf6cb2e3c8a426408cb90c1298e3869cd55660625b2c3'
    )
  ),
  new BN(
    web3.utils.hexToNumberString(
      '0x3c2dd835b3f37d72592ee76ebced8b1a15310b824a0d62409263f1594da52171'
    )
  ),
  new BN(
    web3.utils.hexToNumberString(
      '0x10d9f6bbcc5fcd9cf7a8fcd37a14dc7d719fadbc7f75f98ebebb0719397c50c1'
    )
  ),
  new BN(
    web3.utils.hexToNumberString(
      '0x3324b6af8c3c1a134906345824ea56115ff5d46e863394edec5b4e6089e99d95'
    )
  ),
  new BN(
    web3.utils.hexToNumberString(
      '0xd70c6460f498b10eb3a4e739e18f8ed10110d89fb35de350c1e07ff7a300f9fb'
    )
  ),
  new BN(
    web3.utils.hexToNumberString(
      '0x21dfaa8164b31e8d7c6dc1e1d29344001be3ca30c6446b8903f5476553d94c63'
    )
  ),
  new BN(
    web3.utils.hexToNumberString(
      '0xd1064e0c1618c57517fc16a4c2f360cd9089464794d8d907c85d0a286a02da6'
    )
  ),
  new BN(
    web3.utils.hexToNumberString(
      '0x3c29cc1006a2062d4ac52af124a42a0d937f120260434eb3b234c74fde8256cc'
    )
  ),
  new BN(
    web3.utils.hexToNumberString(
      '0xba6bd22d33b9fe2010eecc7663983e56d39a9b3a6ef9ba7ad252ad47bb3268c4'
    )
  ),
  new BN(
    web3.utils.hexToNumberString(
      '0xe5aed5fd2336862ff33e1648d0fa058520dbe003049dfe2433d6f9e3305aa08d'
    )
  ),
  new BN(
    web3.utils.hexToNumberString(
      '0x7275275a0ea97bde92cd92fdd57d472b4db985d2814951c88373f3bbdca84131'
    )
  ),
  new BN(
    web3.utils.hexToNumberString(
      '0x17e6b3aa581f972e331445b8c661894178ae8852201c8df34706d1dfb6c92f75'
    )
  ),
  new BN(
    web3.utils.hexToNumberString(
      '0xaeac70a85397030d84193a54a6e596750e6ab3926b530c127a17c9e24b20b8ce'
    )
  ),
  new BN(
    web3.utils.hexToNumberString(
      '0xbc12436ba2b2cee8586cc4714522d1866fa0e949bde42ad7d9645cdd8fe58ba0'
    )
  ),
  new BN(
    web3.utils.hexToNumberString(
      '0x49c40fe4834a5e78ff1a24b37b6e40119f520de73a0cb51479d91d73cdebab8f'
    )
  ),
  new BN(
    web3.utils.hexToNumberString(
      '0xd8df824c861814311dfc864f00253ace3f6745cbc9562806186f74ac957857c1'
    )
  ),
  new BN(
    web3.utils.hexToNumberString(
      '0xdbf0c1a5316e43762e4a4ea443b9458e97e8a6e7991421bb2eb1f8f346804d2b'
    )
  ),
  new BN(
    web3.utils.hexToNumberString(
      '0xa94c80c79017fd7ff0e134c5bdee69867a580cd0aff9f1d67f36a9785c02e920'
    )
  ),
  new BN(
    web3.utils.hexToNumberString(
      '0x966e6f6d7f644467cfe28dc9f9db78d5a025ad5117fc5641184724590e7654e4'
    )
  ),
  new BN(
    web3.utils.hexToNumberString(
      '0x929bdd7feee9229494a3eafcc2eeea3a5f51db20f26fdb8a9d13344534d8f1fb'
    )
  ),
  new BN(
    web3.utils.hexToNumberString(
      '0x81b24f93bde1395b538944e740855d144d996fcebaab447637fb47a7e2b74e20'
    )
  ),
  new BN(
    web3.utils.hexToNumberString(
      '0x4fa584f5a852d22ed2a1834964da6d267e7bca3d9f3a9513c6c077fec5a9501'
    )
  ),
  new BN(
    web3.utils.hexToNumberString(
      '0x847eb542c8078dae0f4195c0fc6f00341851f26f58963efc59e51c42bfe63bfc'
    )
  ),
  new BN(
    web3.utils.hexToNumberString(
      '0x1c541f19d04dfaec842b7d790b185904de53503ea4cc6f78fd3f17549082a6ad'
    )
  ),
  new BN(
    web3.utils.hexToNumberString(
      '0x1038dde7a37f37bab144466ee29afed96179e9f324aea58d4fe991036f1e2bee'
    )
  ),
  new BN(
    web3.utils.hexToNumberString(
      '0x7ab4e529bcc484ecfab23aee965ac0c34da462d314b34271a5d54768399d7582'
    )
  ),
  new BN(
    web3.utils.hexToNumberString(
      '0x58c31c137dc3fc670a6a08bea893f6340e80ad7d5f744c90d87f6fac83ff4410'
    )
  ),
  new BN(
    web3.utils.hexToNumberString(
      '0x1c6457dfbed1d1982b4303e9c8f2aa8efc3b36a0b73b24007503da3936b9643b'
    )
  ),
  new BN(
    web3.utils.hexToNumberString(
      '0xaf04efc3d21fa0dbd3d0969859f456be53bc855d667153e96a1077c258f5c47c'
    )
  ),
  new BN(
    web3.utils.hexToNumberString(
      '0xf64f3afe4825e212efd8d5a09b38c24907154b962e87c13494453fe84360f5af'
    )
  ),
  new BN(
    web3.utils.hexToNumberString(
      '0x2215baa129243bb2489b96eb079f9fc52ffc5a75fe44e4dc5525480b08cec100'
    )
  ),
  new BN(
    web3.utils.hexToNumberString(
      '0xc016d66a19e8c03a88c7d2deb1c2266264d0def276668c1530e0b4d0797f5bbd'
    )
  ),
  new BN(
    web3.utils.hexToNumberString(
      '0x21537b0813609408495d2da79242fd95350051c055b282e880251dc7ef2c8604'
    )
  ),
  new BN(
    web3.utils.hexToNumberString(
      '0xce0e1a1ebd2dbf3788e4629d9edbe23d0320595cb4a2259968bd183fcfe784f4'
    )
  ),
  new BN(
    web3.utils.hexToNumberString(
      '0x4e31c84801b7c30a7f6a117b9409ae826a2d8ad0856e90e5325c02a171fd406c'
    )
  ),
  new BN(
    web3.utils.hexToNumberString(
      '0xf50bbdf427e8002383ef989df23898c8fa2ffd6cfbcda75d9c0f388b97b18a37'
    )
  ),
  new BN(
    web3.utils.hexToNumberString(
      '0xcdeba8b83fb1b00ad0ea7a73d33d5bfc63abbd0209a3a25fc1c6f612fccd4b9e'
    )
  ),
  new BN(
    web3.utils.hexToNumberString(
      '0xec750d05b6ca921b7dbfc5c80e427c89d2a0746ffe884391445eb58700548374'
    )
  ),
  new BN(
    web3.utils.hexToNumberString(
      '0x86d55a186b3d9778b312e59bf6883902072e078e05387853e6a9daae02fa0cc3'
    )
  ),
  new BN(
    web3.utils.hexToNumberString(
      '0x393908f0cf05a59f17147046a51de9e3378b8988b777f97cd48fbbd76b4d302f'
    )
  ),
  new BN(
    web3.utils.hexToNumberString(
      '0xbbe6e8eeeca8137f1bffc740264e3f51078373a74aad94bb7e06318d0470fc17'
    )
  ),
  new BN(
    web3.utils.hexToNumberString(
      '0xaf787d9946676534a6ae3b9052a019e2ec315ea1067c0ccfbe02d93c286c9082'
    )
  ),
  new BN(
    web3.utils.hexToNumberString(
      '0x8a9cd7b8b7fb4f8bc6892dd9862063dd8049c7a2ba1869e917ac4058c4fafa89'
    )
  ),
  new BN(
    web3.utils.hexToNumberString(
      '0x962bf93a871bae8ecca539235fd64e11d25ff2892c6b5696984247ca1a06ea6f'
    )
  ),
  new BN(
    web3.utils.hexToNumberString(
      '0xa61932131d5b86a81122ca2d99d9e8ca85a8823d383e4dd529ce6167b39b1b7a'
    )
  ),
  new BN(
    web3.utils.hexToNumberString(
      '0xffd5897716f91d481cb2fae38c1a715048d24f49b4830ed6e0f38df400aca73'
    )
  ),
  new BN(
    web3.utils.hexToNumberString(
      '0x80c0f853e1e11595f38eb9ce932e81decad7806b6ce626e64664c63d0161300f'
    )
  ),
  new BN(
    web3.utils.hexToNumberString(
      '0xfe89d1594b8077eda30ce89ce37de5d40326d13fa59af5b65b056d637086493e'
    )
  ),
  new BN(
    web3.utils.hexToNumberString(
      '0x94aa8010138ccd8527712e6ba00df632f1cb3a26f8bb1a0148394b4da26b9389'
    )
  ),
  new BN(
    web3.utils.hexToNumberString(
      '0xb5770e44a24cf2e9c028441c87df80f9cdd26899f2a95d149ae42422491261cf'
    )
  ),
  new BN(
    web3.utils.hexToNumberString(
      '0xccb2e65c2b007fc48a929459b9e55c7cae243a1768db34f563c2f900d9a4a8ad'
    )
  ),
  new BN(
    web3.utils.hexToNumberString(
      '0x302898c897fe6821c3034bd415821ea249af1158aa1e01223e9f2f7bdabe2a91'
    )
  ),
  new BN(
    web3.utils.hexToNumberString(
      '0xe2e77f6be80bc97c465771de809cd1d51d18b0c683396f667dc345a80a013d2f'
    )
  ),
  new BN(
    web3.utils.hexToNumberString(
      '0xf23cc0a657d3ee03226073d99c4bf36f87579727aa1dde29be3b56081c923ecf'
    )
  ),
  new BN(
    web3.utils.hexToNumberString(
      '0x3722d7964d96ed3cae69957ac1b17c98ea779c761a4fb85854324839a45adc49'
    )
  ),
  new BN(
    web3.utils.hexToNumberString(
      '0x9dc68abbb997d022d6856ace0a1ac4658c6a50c2d49f0364122de47b674b6987'
    )
  ),
  new BN(
    web3.utils.hexToNumberString(
      '0x1b6e7c1bb16fcbd954fb343570f8af720ef19c99a4fd9e25385e55adf44c5479'
    )
  ),
  new BN(
    web3.utils.hexToNumberString(
      '0xe0d3d80775c56a2c2f851a5d85947481174365da46141c42392743675d6ecd3a'
    )
  ),
  new BN(
    web3.utils.hexToNumberString(
      '0xb5249b4847705e8d30ab13298e63fe8235be99b919a8227e483ef09061897d5c'
    )
  ),
  new BN(
    web3.utils.hexToNumberString(
      '0x2e85cd2718f3c51347a437a639cd8bda8012a03116bfce7bc2527a1b4bcbe3e'
    )
  ),
  new BN(
    web3.utils.hexToNumberString(
      '0xd35124787675617fe78a0d0dc3edb867fe65b9e5ab21bcd397cd8cce804add64'
    )
  ),
  new BN(
    web3.utils.hexToNumberString(
      '0xc776a4515d2ad878e0efca9b85d835f72d8b4993f9d811d6b166ab5bb9fc8aea'
    )
  ),
  new BN(
    web3.utils.hexToNumberString(
      '0xb7410701f8479f08f86a2e0b4479244ff3dd5387d58a703f9a015fa4d200d89a'
    )
  ),
  new BN(
    web3.utils.hexToNumberString(
      '0x8b22cab77687d11e22a9a8a1435d8472151e02a58f76dfc43b72b251d171b88e'
    )
  ),
  new BN(
    web3.utils.hexToNumberString(
      '0xdd401defb6e37b2cf2a4ac58cb3243b951e4961cee4533bded902fc7a4d8e13c'
    )
  ),
  new BN(
    web3.utils.hexToNumberString(
      '0xeb9b3ef37f57873243293af6b915c758f5d554efeec10b4aa6b3ddd4950d2e4c'
    )
  ),
  new BN(
    web3.utils.hexToNumberString(
      '0x1ee5f653417fecfabb729e87549d52fa9c57d04f7aaa5227f751aa80b8dc8cf7'
    )
  ),
  new BN(
    web3.utils.hexToNumberString(
      '0x724122379fae39a109c8fa30ff3eb5dd2ee9a1a845fd9d2535acd55657410bee'
    )
  ),
  new BN(
    web3.utils.hexToNumberString(
      '0xdb2eea906c679da20dfaaff3ee92905f9aafa3a7b5a2c01f1f685e362b58acb6'
    )
  ),
  new BN(
    web3.utils.hexToNumberString(
      '0xe6d4940f6ffabfb754cd67588efd188645caef892949bd5d668258018b56a166'
    )
  ),
  new BN(
    web3.utils.hexToNumberString(
      '0x7e636ee3d2914157a39963c308e93a492ea86cb782d96e47773775f544cbbed9'
    )
  ),
  new BN(
    web3.utils.hexToNumberString(
      '0x75921e88680163d20f21b0c5ff61d1b97bdbc6d5c69e746090c2bc6cc27d03ed'
    )
  ),
  new BN(
    web3.utils.hexToNumberString(
      '0x6e961332a631a45900d5c2111360dcff5631b58c0fc3d3ef8e2d57fed5ca15aa'
    )
  ),
  new BN(
    web3.utils.hexToNumberString(
      '0x2cceb4b84ce151df2873c66c6e18c38739a46d06b75541af46768215b6d50de9'
    )
  ),
  new BN(
    web3.utils.hexToNumberString(
      '0xa81341fe8aee600370cc4852b1008aaa846e58ba6356c096e2df04cd976f8e46'
    )
  ),
  new BN(
    web3.utils.hexToNumberString(
      '0x615afdde2756b92ae1012be3e0393856457c9def83fcf93bebc67f6e9d8ac16c'
    )
  ),
  new BN(
    web3.utils.hexToNumberString(
      '0x2566e509d27fe0c00ef2c3f76571a1de60050d20956554ccee77800c18862848'
    )
  ),
  new BN(
    web3.utils.hexToNumberString(
      '0x83a8a736815726b51d74b5e17aa40cd190dc8df1fea1d003a63d383befb78c54'
    )
  ),
  new BN(
    web3.utils.hexToNumberString(
      '0x3fd9e153ba4a11b304729c10f1aadb2c1ce9107dfcbc116a6386bb232af67d51'
    )
  ),
  new BN(
    web3.utils.hexToNumberString(
      '0x48709af2d94bc10e73010cfbe7c4f6d0c2bab4ae8b47e4550a61395406c45de6'
    )
  ),
  new BN(
    web3.utils.hexToNumberString(
      '0xc57c3276264b9553da224c0d1a17b68b3c56a4b15662d36e10a35c69b17667ce'
    )
  ),
  new BN(
    web3.utils.hexToNumberString(
      '0x23d988b412458381a1e7cc4694c7965079160b1475402094e36c5efcb5e2f909'
    )
  ),
  new BN(
    web3.utils.hexToNumberString(
      '0x9dc157ba005a4ddffe637c6acfdfbf00dd6a841bb68b071b10e780aa40cf85f'
    )
  ),
  new BN(
    web3.utils.hexToNumberString(
      '0x8263f9ed50c782f009a566c2b39d8190060b943a72eb5a293295de5781eb3f97'
    )
  )
]

class BalanceTree {
  constructor (deep) {
    this.deep = deep
    this.root = new Node(keccakPreHashed[deep - 1], deep - 1, deep)
  }

  /// get key return a tuple of value and sibling to proof
  getProof (key) {
    return this.root.getProof(key, this.deep)
  }

  update (key, value) {
    return this.root.update(key, value)
  }
}

/// this.left this.right child node of this node
///
class Node {
  constructor (root, deep, treeDeep) {
    this.root = root
    this.deep = deep
    this.treeDeep = treeDeep
  }
  leftHash () {
    if (this.left == undefined) {
      return keccakPreHashed[this.deep - 1]
    }
    return new BN(this.left.root)
  }

  rightHash () {
    if (this.right == undefined) {
      return keccakPreHashed[this.deep - 1]
    }
    return new BN(this.right.root)
  }

  getProof (key) {
    // no child
    if (this.deep == 0) {
      return [this.root, []]
    }

    // let isLeft = ((key >> (this.deep - 1)) & 1) == 0
    let isLeft = key.ushrn(this.deep - 1).uand(new BN(1)).eq(new BN(0))

    let value, siblings
    if (isLeft) {
      if (this.left == undefined) {
        // return an array of preHash zero nodes
        siblings = []
        if (this.deep > 1) {
          // create deep - 1 sibling to proof this child
          for (let i = 0; i < this.deep - 1; i++) {
            siblings.push(new BN(keccakPreHashed[i]))
          }
        }
        value = new BN(0)
      } else [value, siblings] = this.left.getProof(key)
      siblings.push(this.rightHash())
    } else {
      if (this.right == undefined) {
        // return an array of preHash zero nodes
        siblings = []
        if (this.deep > 1) {
          // create deep - 1 sibling to proof this child
          for (let i = 0; i < this.deep - 1; i++) {
            siblings.push(new BN(keccakPreHashed[i]))
          }
        }
        value = new BN(0)
      } else [value, siblings] = this.right.getProof(key)

      siblings.push(this.leftHash())
    }

    // console.log('siblings', siblings.length, siblings[siblings.length - 1])
    return [value, siblings]
  }

  update (key, value) {
    if (this.deep == 0) {
      this.root = value
      return
    }

    // let isLeft = ((key >> (this.deep - 1)) & 1) == 0
    let isLeft = key.ushrn(this.deep - 1).uand(new BN(1)).eq(new BN(0))
    if (isLeft) {
      if (this.left == undefined) {
        let childDeep = this.deep - 1
        this.left = new Node(
          keccakPreHashed[childDeep],
          childDeep,
          this.treeDeep
        )
      }

      this.left.update(key, value)
      this.root = keccakParentOf(this.leftHash(), this.rightHash())
    } else {
      if (this.right == undefined) {
        let childDeep = this.deep - 1
        this.right = new Node(
          keccakPreHashed[childDeep],
          childDeep,
          this.treeDeep
        )
      }

      this.right.update(key, value)
      this.root = keccakParentOf(this.leftHash(), this.rightHash())
    }
  }
}

/// key value is BN
function merkleRoot (key, value, siblings) {
  let root = value
  for (let i = 0; i < siblings.length; i++) {
    // console.log(key);
    // key & 1 ==0
    if (key.uand(new BN(1)).eq(new BN(0))) {
      // right sibling
      root = keccakParentOf(root, siblings[i])
    } else {
      // left sibling
      root = keccakParentOf(siblings[i], root)
    }
    // key >>= 1
    key = key.ushrn(1)
  }
  return root
}

module.exports = { keccakParentOf, keccakPreHashed, merkleRoot, BalanceTree }

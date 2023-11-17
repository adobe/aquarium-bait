# Rosetta role

The role uses pre-downloaded (from Apple servers by the attached script `get_catalog_pkgs.py`)
packages of RosettaUpdateAuto.pkg and allows to install rosetta without internet connection. It's
useful, because the usual mechanism of `softwareupdate --install-rosetta` would not allow you to
easily set proxy.

How this works:
1. Collect the distributions by running `./get_catalog_pkgs.py` - it will create rosetta dir
2. Place the dists, 2 ways:
  - Upload the directory to your preferred artifact storage and set overrides for `rosetta_url_prefix`
  - Put the downloaded files locally in `playbooks/files/mac` without rosetta directory
3. Run he role and it will download the dist needed for your specific MacOS version and install it

## Tasks

* Install Rosetta

## Additional info

Optionally you can override `rosetta_packages` variable with your own downloaded distributions to
be ensure you're not installing something bad. The stdout of `get_catalog_pkgs.py` could be put
there. Rosetta role verifies the signature of pkg, but this sum check could add predictability.

```yml
rosetta_packages:
  20A5374g:
    - rel: rosetta/RosettaUpdateAuto_20A5374g.pkg
      mtd: rosetta/RosettaUpdateAuto_20A5374g.meta
      sum: sha256:d1759e019f228216847b85de57d1d7809e726e0b8c15651562acb6bc671cd323
  20A5374i:
    - rel: rosetta/RosettaUpdateAuto_20A5374i.pkg
      mtd: rosetta/RosettaUpdateAuto_20A5374i.meta
      sum: sha256:58ad7866e7e87274c4759cb86c76bc3a340d64f546ed7714e4ba4ea0d85ee645
  20A5384c:
    - rel: rosetta/RosettaUpdateAuto_20A5384c.pkg
      mtd: rosetta/RosettaUpdateAuto_20A5384c.meta
      sum: sha256:a08973096186c021c2547135189d0f62a9eb2ba608295d0c990e3d161783320b
  20A5395g:
    - rel: rosetta/RosettaUpdateAuto_20A5395g.pkg
      mtd: rosetta/RosettaUpdateAuto_20A5395g.meta
      sum: sha256:f2d15fcf15f32e14f5129c3da83f93cb86c107cd8ccc7463dcff68fa18c2a9ca
  20B5012d:
    - rel: rosetta/RosettaUpdateAuto_20B5012d.pkg
      mtd: rosetta/RosettaUpdateAuto_20B5012d.meta
      sum: sha256:85f897f33e7e0d64215bdaeee1442330327ab0f2b810e4cd4d295f634f9060c6
  20B28:
    - rel: rosetta/RosettaUpdateAuto_20B28.pkg
      mtd: rosetta/RosettaUpdateAuto_20B28.meta
      sum: sha256:b5bb037de61a062a53c8a4e564baddba41ff3100362e1f7d3bf117daa63b8c1e
  20B5022a:
    - rel: rosetta/RosettaUpdateAuto_20B5022a.pkg
      mtd: rosetta/RosettaUpdateAuto_20B5022a.meta
      sum: sha256:2c920e9c2a55b7943eb1b94151e26bc321995e4e211479304a87b9d0d3c7ecf3
  20B29:
    - rel: rosetta/RosettaUpdateAuto_20B29.pkg
      mtd: rosetta/RosettaUpdateAuto_20B29.meta
      sum: sha256:811e1382057db0fb58c04d0118468e7833ba2cab3ebb8804af65bd0b9d7bba49
  20A2411:
    - rel: rosetta/RosettaUpdateAuto_20A2411.pkg
      mtd: rosetta/RosettaUpdateAuto_20A2411.meta
      sum: sha256:a94c11af7349a897dd6d058857eb69c53672b0b33b4751e0059668ad5a1fc307
  20C5048k:
    - rel: rosetta/RosettaUpdateAuto_20C5048k.pkg
      mtd: rosetta/RosettaUpdateAuto_20C5048k.meta
      sum: sha256:4dbe05300be8af74eb37d475c3fc597340ded94ffef29ddb97bcdd820707f696
  20B50:
    - rel: rosetta/RosettaUpdateAuto_20B50.pkg
      mtd: rosetta/RosettaUpdateAuto_20B50.meta
      sum: sha256:74b9af5b514ad41750392c4ba4f25ef8cd8afb3af9e12d964ea7e4fba36d3e41
  20C5048l:
    - rel: rosetta/RosettaUpdateAuto_20C5048l.pkg
      mtd: rosetta/RosettaUpdateAuto_20C5048l.meta
      sum: sha256:c829d246e4ff34da5876d287db0515d3be3307733592d3bac8afcea7f06616e9
  20C5061b:
    - rel: rosetta/RosettaUpdateAuto_20C5061b.pkg
      mtd: rosetta/RosettaUpdateAuto_20C5061b.meta
      sum: sha256:9a265f88b4251a353d744056206b586e170900ae237232f05b92646dd5c5d4a6
  20C69:
    - rel: rosetta/RosettaUpdateAuto_20C69.pkg
      mtd: rosetta/RosettaUpdateAuto_20C69.meta
      sum: sha256:8ed94c7d56ca0ac4d14c97ece802860e6eb79acb5ff1cf4d1b9467836f1fea22
  20D5029f:
    - rel: rosetta/RosettaUpdateAuto_20D5029f.pkg
      mtd: rosetta/RosettaUpdateAuto_20D5029f.meta
      sum: sha256:9cabeaaa4d646d2acbbcd6e3a4dae6b9ced84099f0fc9eb71cf5c36033e66af9
  20D5042d:
    - rel: rosetta/RosettaUpdateAuto_20D5042d.pkg
      mtd: rosetta/RosettaUpdateAuto_20D5042d.meta
      sum: sha256:641523400e66228978c32015fc9e6697908267dc391f7a1c44f6dcb696b87219
  20D53:
    - rel: rosetta/RosettaUpdateAuto_20D53.pkg
      mtd: rosetta/RosettaUpdateAuto_20D53.meta
      sum: sha256:c37047c6180a03c4b79b0be6a961f5edf32ce0cbe4c551bb2f31dbf02bd7ce7b
  20D62:
    - rel: rosetta/RosettaUpdateAuto_20D62.pkg
      mtd: rosetta/RosettaUpdateAuto_20D62.meta
      sum: sha256:7aeb76d15980fdfcc33e96d87a196c2a72f6a128a9ef59ca5928849b678012e4
  20D64:
    - rel: rosetta/RosettaUpdateAuto_20D64.pkg
      mtd: rosetta/RosettaUpdateAuto_20D64.meta
      sum: sha256:4079935a65385c6da8063e0c35a48419c03618bab8111ee35198c4baa1d7c81b
  20E5172i:
    - rel: rosetta/RosettaUpdateAuto_20E5172i.pkg
      mtd: rosetta/RosettaUpdateAuto_20E5172i.meta
      sum: sha256:0f01fb7d075cfad68a0765d52784222c105f14b50deab5f811980b79273a92da
  20D74:
    - rel: rosetta/RosettaUpdateAuto_20D74.pkg
      mtd: rosetta/RosettaUpdateAuto_20D74.meta
      sum: sha256:9c1ad95d90c4bb47b34c87d58b418d7cda35657d34e55f1de7cb014e61aaad66
  20D75:
    - rel: rosetta/RosettaUpdateAuto_20D75.pkg
      mtd: rosetta/RosettaUpdateAuto_20D75.meta
      sum: sha256:798b0595e649baf93985445d5ca5b801590a34e4a922cf84c56acabdb1bc125d
  20E5186d:
    - rel: rosetta/RosettaUpdateAuto_20E5186d.pkg
      mtd: rosetta/RosettaUpdateAuto_20E5186d.meta
      sum: sha256:bbd9adc7ccba7f7dab627a9492560ea2fbd90ad7b319f229873eb43fb8a72be5
  20E5186e:
    - rel: rosetta/RosettaUpdateAuto_20E5186e.pkg
      mtd: rosetta/RosettaUpdateAuto_20E5186e.meta
      sum: sha256:e8359483baf8f035987da7d4106b9cdf63002f7e85fee54acade54a3e0a0492e
  20D80:
    - rel: rosetta/RosettaUpdateAuto_20D80.pkg
      mtd: rosetta/RosettaUpdateAuto_20D80.meta
      sum: sha256:ae75a33e5878dfb2d65d1b250d420e217ab3ce44d08b010f54fafc88ddee411a
  20E5196f:
    - rel: rosetta/RosettaUpdateAuto_20E5196f.pkg
      mtd: rosetta/RosettaUpdateAuto_20E5196f.meta
      sum: sha256:66eebb6c2961e7d48d7e17bdacdb7423d6096737564185206da8464ffad20cd0
  20D91:
    - rel: rosetta/RosettaUpdateAuto_20D91.pkg
      mtd: rosetta/RosettaUpdateAuto_20D91.meta
      sum: sha256:52b01057009d4ed0026cf7e6676e15d7f2bbb9d51b5ffbaccb2a063041e5d735
  20E5210c:
    - rel: rosetta/RosettaUpdateAuto_20E5210c.pkg
      mtd: rosetta/RosettaUpdateAuto_20E5210c.meta
      sum: sha256:88a152509205f38b8e914b0b36f5a80986420d39eafa2b64a87c0840cead8434
  20E5217a:
    - rel: rosetta/RosettaUpdateAuto_20E5217a.pkg
      mtd: rosetta/RosettaUpdateAuto_20E5217a.meta
      sum: sha256:6df9a1d0a98c0eeacbf727cabc61c6f00c4651629325cb75a5725cd21c37dad7
  20E5224a:
    - rel: rosetta/RosettaUpdateAuto_20E5224a.pkg
      mtd: rosetta/RosettaUpdateAuto_20E5224a.meta
      sum: sha256:f4163074998adc051c79d93d3e4b8febb79f7dd98b3c2a456164f63ce98ec773
  20E5229a:
    - rel: rosetta/RosettaUpdateAuto_20E5229a.pkg
      mtd: rosetta/RosettaUpdateAuto_20E5229a.meta
      sum: sha256:01376c82ffb4721c4d0cb82b039bd905fe4e7e7d357b30032ae2c4bc563af94c
  20E5231a:
    - rel: rosetta/RosettaUpdateAuto_20E5231a.pkg
      mtd: rosetta/RosettaUpdateAuto_20E5231a.meta
      sum: sha256:c1b9089bb2bcf77deb6a3c4991a22356274c80ed9b1d52437c7a694b3fc2fabd
  20E232:
    - rel: rosetta/RosettaUpdateAuto_20E232.pkg
      mtd: rosetta/RosettaUpdateAuto_20E232.meta
      sum: sha256:ad82dc7338e8fafae1f5ab0171c9bbd1ce765d95abee9f587b64a087265d26f3
  20F5046g:
    - rel: rosetta/RosettaUpdateAuto_20F5046g.pkg
      mtd: rosetta/RosettaUpdateAuto_20F5046g.meta
      sum: sha256:4832007e9ef26df61627f657b49921765c7090d26c8ce99b9c06ca152d924ea5
  20E217:
    - rel: rosetta/RosettaUpdateAuto_20E217.pkg
      mtd: rosetta/RosettaUpdateAuto_20E217.meta
      sum: sha256:fd06357e43a64524d79f52850e50657c15018e063410b9f33c443628d275895d
  20E241:
    - rel: rosetta/RosettaUpdateAuto_20E241.pkg
      mtd: rosetta/RosettaUpdateAuto_20E241.meta
      sum: sha256:8540f5522421eb79e8f32da84c48a26a9e25ae963c8f56cff49a23a3b6e17380
  20F5055c:
    - rel: rosetta/RosettaUpdateAuto_20F5055c.pkg
      mtd: rosetta/RosettaUpdateAuto_20F5055c.meta
      sum: sha256:a6a3b55d1af261c22554141ad1381d70b715db95bb6ad923d753488f2bf6365c
  20F5065a:
    - rel: rosetta/RosettaUpdateAuto_20F5065a.pkg
      mtd: rosetta/RosettaUpdateAuto_20F5065a.meta
      sum: sha256:70d223a6d2365139ca83e455a268cea30882e1f7f84c6768540c2d663a68c9c0
  20F71:
    - rel: rosetta/RosettaUpdateAuto_20F71.pkg
      mtd: rosetta/RosettaUpdateAuto_20F71.meta
      sum: sha256:2d1c850886923cfca91cc5556b6335bd7b4c6700ff72f94f12c9814c0a817ec7
  20G5023d:
    - rel: rosetta/RosettaUpdateAuto_20G5023d.pkg
      mtd: rosetta/RosettaUpdateAuto_20G5023d.meta
      sum: sha256:eb5eb768508694f37a7ac690e74eb10ae5dfea530a73c7e0239cffe249c62c87
  20G5033c:
    - rel: rosetta/RosettaUpdateAuto_20G5033c.pkg
      mtd: rosetta/RosettaUpdateAuto_20G5033c.meta
      sum: sha256:808e195aa57b7e4abba3e439a1b8cb3cda00aeaceb84e2806defd9a67e5ff12a
  21A5248p:
    - rel: rosetta/RosettaUpdateAuto_21A5248p.pkg
      mtd: rosetta/RosettaUpdateAuto_21A5248p.meta
      sum: sha256:fb3d3e4d8fbe7a36af64a3e0b115bac60d9a547c75fe005b16d9bc883da79514
  20G5042c:
    - rel: rosetta/RosettaUpdateAuto_20G5042c.pkg
      mtd: rosetta/RosettaUpdateAuto_20G5042c.meta
      sum: sha256:c0a52dfdd9cc253f2280edee22b630346e1675ef56b805518442e4d4ab869dd8
  21A5268h:
    - rel: rosetta/RosettaUpdateAuto_21A5268h.pkg
      mtd: rosetta/RosettaUpdateAuto_21A5268h.meta
      sum: sha256:ec0a48a7b7360387e3284264ea6e0952a373cdb30628d14723a3f11433061aa8
  20G5052c:
    - rel: rosetta/RosettaUpdateAuto_20G5052c.pkg
      mtd: rosetta/RosettaUpdateAuto_20G5052c.meta
      sum: sha256:99fe465af4bd5672d9a7e666aff373e66d9d5754e2ca2c05b2948c1231e18126
  20G5065a:
    - rel: rosetta/RosettaUpdateAuto_20G5065a.pkg
      mtd: rosetta/RosettaUpdateAuto_20G5065a.meta
      sum: sha256:f2fe8ce8ffe612a75b35309105ada6eb49e1b226181a678ab8f456bf4a43a1fc
  21A5284e:
    - rel: rosetta/RosettaUpdateAuto_21A5284e.pkg
      mtd: rosetta/RosettaUpdateAuto_21A5284e.meta
      sum: sha256:cb4c282be45dfa1952f3cbd4b843e7b13d6ab9dc9a6ba81213cf276db906d056
  20G71:
    - rel: rosetta/RosettaUpdateAuto_20G71.pkg
      mtd: rosetta/RosettaUpdateAuto_20G71.meta
      sum: sha256:96ef3781a87a1ea25f1823db81f5ac3ed6051648e6e2e8053d0e6c71b9e070b0
  20G70:
    - rel: rosetta/RosettaUpdateAuto_20G70.pkg
      mtd: rosetta/RosettaUpdateAuto_20G70.meta
      sum: sha256:0cf2824611032092dde4a3fc3ab48829b15ea4bb07b63ce5d070fa21c51e7bd5
  20G80:
    - rel: rosetta/RosettaUpdateAuto_20G80.pkg
      mtd: rosetta/RosettaUpdateAuto_20G80.meta
      sum: sha256:02eca839f6bb8895ee96aef6816a8a19a8045f47714a8427c76fdee91fedeb43
  21A5294g:
    - rel: rosetta/RosettaUpdateAuto_21A5294g.pkg
      mtd: rosetta/RosettaUpdateAuto_21A5294g.meta
      sum: sha256:c2011618979d6fe93ace63c042cbd87e083ccd73e24bb04f97d3eff52e9c83a4
  20G95:
    - rel: rosetta/RosettaUpdateAuto_20G95.pkg
      mtd: rosetta/RosettaUpdateAuto_20G95.meta
      sum: sha256:929db26a723ec26e6e698d584fe069829d33b1b8e319ec7765e7e4cd9ff212ed
  21A5304g:
    - rel: rosetta/RosettaUpdateAuto_21A5304g.pkg
      mtd: rosetta/RosettaUpdateAuto_21A5304g.meta
      sum: sha256:9c88868f18e9bc0ee4159df47d8fd0eb6b60e1818d95de7b55c38bb60199d560
  21A5506j:
    - rel: rosetta/RosettaUpdateAuto_21A5506j.pkg
      mtd: rosetta/RosettaUpdateAuto_21A5506j.meta
      sum: sha256:b4c6fc2abc023660a8d0786d9275da63692846a470de80ce99ed32e57cc4951f
  20G165:
    - rel: rosetta/RosettaUpdateAuto_20G165.pkg
      mtd: rosetta/RosettaUpdateAuto_20G165.meta
      sum: sha256:5a67b3943112965bcd646330b27d3d0a28400a21f1b03cdc82f9d66a5a8cc16a
  21A5522h:
    - rel: rosetta/RosettaUpdateAuto_21A5522h.pkg
      mtd: rosetta/RosettaUpdateAuto_21A5522h.meta
      sum: sha256:93a0ff6da7848eada4002cf7b9396076eefb18c7ea559979c25a13f573c24355
  21A5534d:
    - rel: rosetta/RosettaUpdateAuto_21A5534d.pkg
      mtd: rosetta/RosettaUpdateAuto_21A5534d.meta
      sum: sha256:69e4f3f51b004ada865e73a1374b8986d5c0cac97a46c253fce689358a72e7ec
  20G211:
    - rel: rosetta/RosettaUpdateAuto_20G211.pkg
      mtd: rosetta/RosettaUpdateAuto_20G211.meta
      sum: sha256:9057c53a7749d6967ad2936e3b6efc2e15931cfeb34dd071a013d867062b77c6
  21A5543b:
    - rel: rosetta/RosettaUpdateAuto_21A5543b.pkg
      mtd: rosetta/RosettaUpdateAuto_21A5543b.meta
      sum: sha256:25203192c05b06d45d98efbd597f41b3e86ef6089d2ef7ef8f6f493e7c47d82c
  20G214:
    - rel: rosetta/RosettaUpdateAuto_20G214.pkg
      mtd: rosetta/RosettaUpdateAuto_20G214.meta
      sum: sha256:122b5953cf29a1e6ac03e56ece6bcb68cbf709d224e19427b0eb5e1946b54ee9
  21A5552a:
    - rel: rosetta/RosettaUpdateAuto_21A5552a.pkg
      mtd: rosetta/RosettaUpdateAuto_21A5552a.meta
      sum: sha256:81407f0afd08ca53489d736cec67601d37ddf476e0a8c222584478980542ec98
  20G219:
    - rel: rosetta/RosettaUpdateAuto_20G219.pkg
      mtd: rosetta/RosettaUpdateAuto_20G219.meta
      sum: sha256:aaddf8ebccd91f45b1f0cc6b0bb6e8e28a14a0e0a1e65814e08140db2d3c7ad3
  20G221:
    - rel: rosetta/RosettaUpdateAuto_20G221.pkg
      mtd: rosetta/RosettaUpdateAuto_20G221.meta
      sum: sha256:8ca52b8a88929c38995b5182488237cc78d713d5b70aa0a0eee7102de6d7d2e0
  21A558:
    - rel: rosetta/RosettaUpdateAuto_21A558.pkg
      mtd: rosetta/RosettaUpdateAuto_21A558.meta
      sum: sha256:b30d307d620de5ad80015ddee386e512f921017d069fd5f31a2de2b3d8d4832c
  21A344:
    - rel: rosetta/RosettaUpdateAuto_21A344.pkg
      mtd: rosetta/RosettaUpdateAuto_21A344.meta
      sum: sha256:6cefa752179fb99f033a76247f5fb12bd028e47f7f39694b1ff370a19ec51d35
  21A559:
    - rel: rosetta/RosettaUpdateAuto_21A559.pkg
      mtd: rosetta/RosettaUpdateAuto_21A559.meta
      sum: sha256:d4f9e9008497a5d8f7bdd9c57351cbc742897d4bccb84ecd1228b0197de78dc4
  20G224:
    - rel: rosetta/RosettaUpdateAuto_20G224.pkg
      mtd: rosetta/RosettaUpdateAuto_20G224.meta
      sum: sha256:329b4d08a24eee772db7ed5b12a55d8453f8f9992bff256001ffa8cfe1826a67
  21C5021h:
    - rel: rosetta/RosettaUpdateAuto_21C5021h.pkg
      mtd: rosetta/RosettaUpdateAuto_21C5021h.meta
      sum: sha256:00183bfedb85e5261ec34af099519b2d6eb57c5f77fc7b1eb8d9e4e0b31a5d1e
  21C5031d:
    - rel: rosetta/RosettaUpdateAuto_21C5031d.pkg
      mtd: rosetta/RosettaUpdateAuto_21C5031d.meta
      sum: sha256:863bbc186bdb131f9614b24643691ed7aaca8116200b8fe2319cd567faf1a961
  20G303:
    - rel: rosetta/RosettaUpdateAuto_20G303.pkg
      mtd: rosetta/RosettaUpdateAuto_20G303.meta
      sum: sha256:7ef4717bda2aed8470ced9dc1e3352419007e01591b376f10e25048fb64796e3
  21C5039b:
    - rel: rosetta/RosettaUpdateAuto_21C5039b.pkg
      mtd: rosetta/RosettaUpdateAuto_21C5039b.meta
      sum: sha256:6b06e3499ccff1cfaf8050c7d39725e7c865a626a6aee6ce41ff08ddade4a154
  20G306:
    - rel: rosetta/RosettaUpdateAuto_20G306.pkg
      mtd: rosetta/RosettaUpdateAuto_20G306.meta
      sum: sha256:ec1fbc520756b697b8c56c20c539de521e7d1c6a7df11a8810ce34054604bac6
  20G311:
    - rel: rosetta/RosettaUpdateAuto_20G311.pkg
      mtd: rosetta/RosettaUpdateAuto_20G311.meta
      sum: sha256:25a0e58cf5cfe86d4b8ded6b59c412c1853963baea38626a8e5627aca5349123
  21C5045a:
    - rel: rosetta/RosettaUpdateAuto_21C5045a.pkg
      mtd: rosetta/RosettaUpdateAuto_21C5045a.meta
      sum: sha256:19c5bcd5cb6ec4430d0611e36fe6b2e0e2b990b67e751eaee41dba3536bcbe0b
  21C51:
    - rel: rosetta/RosettaUpdateAuto_21C51.pkg
      mtd: rosetta/RosettaUpdateAuto_21C51.meta
      sum: sha256:ec279157c62ace0e0003dd83106e423d8e50cc2c3bb5812c61668f729c563373
  20G313:
    - rel: rosetta/RosettaUpdateAuto_20G313.pkg
      mtd: rosetta/RosettaUpdateAuto_20G313.meta
      sum: sha256:d456af6953bf64a8fbb65f9cbdc6277859345d3657b6fd17f6d672bbd817e458
  21C52:
    - rel: rosetta/RosettaUpdateAuto_21C52.pkg
      mtd: rosetta/RosettaUpdateAuto_21C52.meta
      sum: sha256:547a3c25db2cc3070ae086a99d807f52b4612262416f66f012db01003694295a
  20G314:
    - rel: rosetta/RosettaUpdateAuto_20G314.pkg
      mtd: rosetta/RosettaUpdateAuto_20G314.meta
      sum: sha256:f35845a702b3a3ba2fc9f800bbf279f04c13ba0d42f970935e6d89557a6de5e2
  21D5025f:
    - rel: rosetta/RosettaUpdateAuto_21D5025f.pkg
      mtd: rosetta/RosettaUpdateAuto_21D5025f.meta
      sum: sha256:fcf75db5c857eb04d4c89b8cdc7dc0119daf4cfe441f3e9cc6d30202aac3adb5
  20G405:
    - rel: rosetta/RosettaUpdateAuto_20G405.pkg
      mtd: rosetta/RosettaUpdateAuto_20G405.meta
      sum: sha256:b1b55d54addf06183ad3b685d7dec69aa79bd90e9440d083b2f9d9ad40403152
  20G409:
    - rel: rosetta/RosettaUpdateAuto_20G409.pkg
      mtd: rosetta/RosettaUpdateAuto_20G409.meta
      sum: sha256:f508e634ea15407156e73f476afc08b53cccfc1f8a8b725b53c2c60ffbdb71cc
  21D5039d:
    - rel: rosetta/RosettaUpdateAuto_21D5039d.pkg
      mtd: rosetta/RosettaUpdateAuto_21D5039d.meta
      sum: sha256:1a3afe09f052fe1083ccf953fb1dad6d117afda3034b7f06b13110702ce077bd
  20G413:
    - rel: rosetta/RosettaUpdateAuto_20G413.pkg
      mtd: rosetta/RosettaUpdateAuto_20G413.meta
      sum: sha256:13bac417506e1fbf6b913ca6f9c2d0877f2b423611ea3f5e10cfe6991b63605e
  21D48:
    - rel: rosetta/RosettaUpdateAuto_21D48.pkg
      mtd: rosetta/RosettaUpdateAuto_21D48.meta
      sum: sha256:b937496faf2b59a745d490b7f68d6671ada483f6aa4b29f13d96158efbb9be38
  21D49:
    - rel: rosetta/RosettaUpdateAuto_21D49.pkg
      mtd: rosetta/RosettaUpdateAuto_21D49.meta
      sum: sha256:2f6b30ea6b0c06b6c524b6c559ab6e8e8bff950b217f9f4126ece548419f9c1b
  20G415:
    - rel: rosetta/RosettaUpdateAuto_20G415.pkg
      mtd: rosetta/RosettaUpdateAuto_20G415.meta
      sum: sha256:47034bab1dcd87eb46fdad2c92ca9fdb21177dbb166df54a799a4feafa9ae054
  20G507:
    - rel: rosetta/RosettaUpdateAuto_20G507.pkg
      mtd: rosetta/RosettaUpdateAuto_20G507.meta
      sum: sha256:2285cbe90ce9ca4059c1da52d4af57219d4cbd22d6aa6bb552acebe6002eec59
  21E5196i:
    - rel: rosetta/RosettaUpdateAuto_21E5196i.pkg
      mtd: rosetta/RosettaUpdateAuto_21E5196i.meta
      sum: sha256:79535a5669be7c22932302a12ebe3207884f4b6cce0fbac675bb4fafd5de897b
  21E5206e:
    - rel: rosetta/RosettaUpdateAuto_21E5206e.pkg
      mtd: rosetta/RosettaUpdateAuto_21E5206e.meta
      sum: sha256:8cb280bd4862e4f9f374cd3ccb666d6f360ccd001ba30a87b16041edb4604679
  21D62:
    - rel: rosetta/RosettaUpdateAuto_21D62.pkg
      mtd: rosetta/RosettaUpdateAuto_21D62.meta
      sum: sha256:fd5b93abae988d131d59887cfaf2fec61abc74b7dcc96c9e55eacc7f1fb4bac6
  20G417:
    - rel: rosetta/RosettaUpdateAuto_20G417.pkg
      mtd: rosetta/RosettaUpdateAuto_20G417.meta
      sum: sha256:b24ef41c3735db19fd1a3d92bf651e183ae2472c1593f6ad23fda65e032896cb
  21E5212f:
    - rel: rosetta/RosettaUpdateAuto_21E5212f.pkg
      mtd: rosetta/RosettaUpdateAuto_21E5212f.meta
      sum: sha256:9a4299df7cc8493953b70baea59645486ea04e84c04a37ee147f35c243d70f7c
  20G517:
    - rel: rosetta/RosettaUpdateAuto_20G517.pkg
      mtd: rosetta/RosettaUpdateAuto_20G517.meta
      sum: sha256:76f15741317ff12aa4418630c4bdfbb4c23b3590ed382c395b6cf7ffefb421c4
  21E5222a:
    - rel: rosetta/RosettaUpdateAuto_21E5222a.pkg
      mtd: rosetta/RosettaUpdateAuto_21E5222a.meta
      sum: sha256:e67f9e594b514e219d7ccee28e9eefefe6548f3a7e768a94769ad95dc83eef9c
  20G521:
    - rel: rosetta/RosettaUpdateAuto_20G521.pkg
      mtd: rosetta/RosettaUpdateAuto_20G521.meta
      sum: sha256:2202b0618011e6e3e838344cfda123835bcfe40c8b7a54a3cc0ea0f0bed8ad4c
  21E5227a:
    - rel: rosetta/RosettaUpdateAuto_21E5227a.pkg
      mtd: rosetta/RosettaUpdateAuto_21E5227a.meta
      sum: sha256:db55437370abf5a651e1c374bf3811cdaaf209b9a8bb3bfa9c9170eecd29895f
  20G525:
    - rel: rosetta/RosettaUpdateAuto_20G525.pkg
      mtd: rosetta/RosettaUpdateAuto_20G525.meta
      sum: sha256:93ea369d880f7d332d122aa3720eb67440ed226009d6910e5a08aaab7055b65d
  21E230:
    - rel: rosetta/RosettaUpdateAuto_21E230.pkg
      mtd: rosetta/RosettaUpdateAuto_21E230.meta
      sum: sha256:212201b2b6ce8166463161bf0d9a73693b4999239e944714964b83cadded29c0
  20G526:
    - rel: rosetta/RosettaUpdateAuto_20G526.pkg
      mtd: rosetta/RosettaUpdateAuto_20G526.meta
      sum: sha256:8ec0d45d7016a2d9d5edb49b9f5a36c07a317273a737f6212f640241b672bec3
  21D2048:
    - rel: rosetta/RosettaUpdateAuto_21D2048.pkg
      mtd: rosetta/RosettaUpdateAuto_21D2048.meta
      sum: sha256:d9762e65aa831f6f5b0e778f65de199d9da1cd30ce609baa078ae8031dd113a8
  20G527:
    - rel: rosetta/RosettaUpdateAuto_20G527.pkg
      mtd: rosetta/RosettaUpdateAuto_20G527.meta
      sum: sha256:5262bb0f0a17b4284b63c7109158d4acc2fa741331bb685dad80e88889e23fc6
  21E258:
    - rel: rosetta/RosettaUpdateAuto_21E258.pkg
      mtd: rosetta/RosettaUpdateAuto_21E258.meta
      sum: sha256:a38b0ed94f78e9aba5e1fa2b138e281a6779ac417f86b0011373cce29a3ae5c0
  21F5048e:
    - rel: rosetta/RosettaUpdateAuto_21F5048e.pkg
      mtd: rosetta/RosettaUpdateAuto_21F5048e.meta
      sum: sha256:dd52b7397c1e7a6e9ee07db5b4feab205ddf73931f3c3de3ea70071ea097fd02
  20G604:
    - rel: rosetta/RosettaUpdateAuto_20G604.pkg
      mtd: rosetta/RosettaUpdateAuto_20G604.meta
      sum: sha256:f8c7a56ef50b555183f391987df28e9971e9694a7f9da094f755f6b10baa00a2
  21F5058e:
    - rel: rosetta/RosettaUpdateAuto_21F5058e.pkg
      mtd: rosetta/RosettaUpdateAuto_21F5058e.meta
      sum: sha256:2c960f2ab5e6bac203f2876cf4bb36e764abf4b0921ea591026290541fba21e9
  20G608:
    - rel: rosetta/RosettaUpdateAuto_20G608.pkg
      mtd: rosetta/RosettaUpdateAuto_20G608.meta
      sum: sha256:ade05e989e0b85e6ce32f03aec3c14f35d9b2312ee3dbbc00eb21d314f439989
  21F5063e:
    - rel: rosetta/RosettaUpdateAuto_21F5063e.pkg
      mtd: rosetta/RosettaUpdateAuto_21F5063e.meta
      sum: sha256:c1004fe575ea776fa2479243d5df56db38eaa3158c5edaa1b7557fd83bb591ec
  20G614:
    - rel: rosetta/RosettaUpdateAuto_20G614.pkg
      mtd: rosetta/RosettaUpdateAuto_20G614.meta
      sum: sha256:5e2e5975ec4dcbbedf2bf518f0cf0ea3bc6ca9baf5fdcd0913bc95b63ba70f89
  21F5071b:
    - rel: rosetta/RosettaUpdateAuto_21F5071b.pkg
      mtd: rosetta/RosettaUpdateAuto_21F5071b.meta
      sum: sha256:3f4b4a7af3738e20621147aeb6d80031e01631cb54c59f7befc28d2822e8c68a
  20G618:
    - rel: rosetta/RosettaUpdateAuto_20G618.pkg
      mtd: rosetta/RosettaUpdateAuto_20G618.meta
      sum: sha256:3adef54d229277561838391f036ac6e04de5049c115c125af6ca0571ba0b7648
  21F79:
    - rel: rosetta/RosettaUpdateAuto_21F79.pkg
      mtd: rosetta/RosettaUpdateAuto_21F79.meta
      sum: sha256:72a082cd83654e3324df2099d5d28357482c038d5d6c3ad44de5b5c3307622f2
  20G623:
    - rel: rosetta/RosettaUpdateAuto_20G623.pkg
      mtd: rosetta/RosettaUpdateAuto_20G623.meta
      sum: sha256:7f3b4c1f14ef832eebb65200f4d6d7dc6049febc452f37107e4a96780c8a78fc
  20G624:
    - rel: rosetta/RosettaUpdateAuto_20G624.pkg
      mtd: rosetta/RosettaUpdateAuto_20G624.meta
      sum: sha256:d0033c2f3fb9d06d8ed9c96895f2ec0e3fc5f091490a1425791b62555c2a5003
  21G5027d:
    - rel: rosetta/RosettaUpdateAuto_21G5027d.pkg
      mtd: rosetta/RosettaUpdateAuto_21G5027d.meta
      sum: sha256:6b0db8e1a120eed7932f940e7056d5daa3c213cb8c8e56d4f5a8e6880dce50ec
  20G704:
    - rel: rosetta/RosettaUpdateAuto_20G704.pkg
      mtd: rosetta/RosettaUpdateAuto_20G704.meta
      sum: sha256:9fa4cc99061179f7df948b14e039a8a305746a23335a2c44da23ca89ce510a16
  21G5037d:
    - rel: rosetta/RosettaUpdateAuto_21G5037d.pkg
      mtd: rosetta/RosettaUpdateAuto_21G5037d.meta
      sum: sha256:0bb203d485581c4e22175e244695de66eb153157f3a52957a8193d660e7b0eac
  20G710:
    - rel: rosetta/RosettaUpdateAuto_20G710.pkg
      mtd: rosetta/RosettaUpdateAuto_20G710.meta
      sum: sha256:5b3ce6dd67052b443f9ea9e85b569f41140aa431c27cf35e47528c896151f7e6
  22A5266r:
    - rel: rosetta/RosettaUpdateAuto_22A5266r.pkg
      mtd: rosetta/RosettaUpdateAuto_22A5266r.meta
      sum: sha256:4e6ab4f37700795bdfc6b01b775ff17ff0d69498a688666c8efc069c5b99a674
  20G630:
    - rel: rosetta/RosettaUpdateAuto_20G630.pkg
      mtd: rosetta/RosettaUpdateAuto_20G630.meta
      sum: sha256:42d595a47950ee174b18a64e5550129cb8ba7f519d0e746d4820e9ae89e8c7bd
  21F2081:
    - rel: rosetta/RosettaUpdateAuto_21F2081.pkg
      mtd: rosetta/RosettaUpdateAuto_21F2081.meta
      sum: sha256:bde24b1b2ead65a7af534bff82536fe1e08a45c7f0cb254db0d88ea356f3d193
  21G5046c:
    - rel: rosetta/RosettaUpdateAuto_21G5046c.pkg
      mtd: rosetta/RosettaUpdateAuto_21G5046c.meta
      sum: sha256:0ba5bfcf7a8007713acafbb0679223e305e4f8d3a559712aa1d034e9d1479b0f
  20G715:
    - rel: rosetta/RosettaUpdateAuto_20G715.pkg
      mtd: rosetta/RosettaUpdateAuto_20G715.meta
      sum: sha256:007ff3f79b459329139ad1a2da17d7b440ff802af8ba1344455a332a08cb1de0
  21F2092:
    - rel: rosetta/RosettaUpdateAuto_21F2092.pkg
      mtd: rosetta/RosettaUpdateAuto_21F2092.meta
      sum: sha256:4d3422a228c486f481f4245eea283ebf431cfa4f9544029635defdabb7a9d4f9
  22A5286j:
    - rel: rosetta/RosettaUpdateAuto_22A5286j.pkg
      mtd: rosetta/RosettaUpdateAuto_22A5286j.meta
      sum: sha256:772ed5f69b3b77bb89ea7f531e68fde458879bf269db21ae2da01308559c36ea
  21G5056b:
    - rel: rosetta/RosettaUpdateAuto_21G5056b.pkg
      mtd: rosetta/RosettaUpdateAuto_21G5056b.meta
      sum: sha256:1c6fcce5500f6f4533b4083593d066274052ec168c7f62d61d0a59e3e3eac80f
  20G720:
    - rel: rosetta/RosettaUpdateAuto_20G720.pkg
      mtd: rosetta/RosettaUpdateAuto_20G720.meta
      sum: sha256:035bb19e282c0c39141713cc97d1f4f7d08d203a921620818acfca95336c806f
  21G5063a:
    - rel: rosetta/RosettaUpdateAuto_21G5063a.pkg
      mtd: rosetta/RosettaUpdateAuto_21G5063a.meta
      sum: sha256:9e492e0e42937b970a58d93b82dd96e573165a97909ed2df1094ccc588dccedd
  20G725:
    - rel: rosetta/RosettaUpdateAuto_20G725.pkg
      mtd: rosetta/RosettaUpdateAuto_20G725.meta
      sum: sha256:4e0c7ecfea40f9029cee18fc5ff404188ea570196d489e65bf69e0bd1bb076d8
  22A5295h:
    - rel: rosetta/RosettaUpdateAuto_22A5295h.pkg
      mtd: rosetta/RosettaUpdateAuto_22A5295h.meta
      sum: sha256:39dfeb95532c2a3636a36176ed2584cdd544bf73d3847a7fdb31eac84a619414
  22A5295i:
    - rel: rosetta/RosettaUpdateAuto_22A5295i.pkg
      mtd: rosetta/RosettaUpdateAuto_22A5295i.meta
      sum: sha256:a990300a732ad6b603b21e6c7900f2d9e8b56f0d8dd7f22d784e4e9efa79ad1d
  21G69:
    - rel: rosetta/RosettaUpdateAuto_21G69.pkg
      mtd: rosetta/RosettaUpdateAuto_21G69.meta
      sum: sha256:5852f716be60a3fdb42c7a9736e6c6c5098df4d37047ca0690549cd5682f62b4
  20G728:
    - rel: rosetta/RosettaUpdateAuto_20G728.pkg
      mtd: rosetta/RosettaUpdateAuto_20G728.meta
      sum: sha256:3e040ac1860ef940c37d3fed334395b4660756a60f10a242e9a95065099fea8e
  21G72:
    - rel: rosetta/RosettaUpdateAuto_21G72.pkg
      mtd: rosetta/RosettaUpdateAuto_21G72.meta
      sum: sha256:af6f2f6d1551251e5036c9596b90990d3590d43fc48b36d001ece0316ab3c357
  20G730:
    - rel: rosetta/RosettaUpdateAuto_20G730.pkg
      mtd: rosetta/RosettaUpdateAuto_20G730.meta
      sum: sha256:02b402a34ae6d1fc29a3b7c3f67caeec84fda4fe50fbc48fd98db22ed143b4be
  22A5311f:
    - rel: rosetta/RosettaUpdateAuto_22A5311f.pkg
      mtd: rosetta/RosettaUpdateAuto_22A5311f.meta
      sum: sha256:da06580a734492b92f8830dc54c1a3051468366df528a3a59893a90a42287ed1
  22A5321d:
    - rel: rosetta/RosettaUpdateAuto_22A5321d.pkg
      mtd: rosetta/RosettaUpdateAuto_22A5321d.meta
      sum: sha256:039754ad6ce88a19a96f19cf9b1baa0da8cb457fe310b2ce1e1147b42d35a997
  21G83:
    - rel: rosetta/RosettaUpdateAuto_21G83.pkg
      mtd: rosetta/RosettaUpdateAuto_21G83.meta
      sum: sha256:720bf412d37d7ae521f205ee71739cb71c2f767eb3e56d56a484d33c93aa2ea4
  22A5331f:
    - rel: rosetta/RosettaUpdateAuto_22A5331f.pkg
      mtd: rosetta/RosettaUpdateAuto_22A5331f.meta
      sum: sha256:e74e348e7148fd0e5473eb5915109987471a4fbcdd1b6b0ec14f75cdda85fd5e
  21G115:
    - rel: rosetta/RosettaUpdateAuto_21G115.pkg
      mtd: rosetta/RosettaUpdateAuto_21G115.meta
      sum: sha256:46348a40319b53d0d51744de3392ef79526986f06f15a8832bc96ebee64fe895
  20G817:
    - rel: rosetta/RosettaUpdateAuto_20G817.pkg
      mtd: rosetta/RosettaUpdateAuto_20G817.meta
      sum: sha256:2bbde161aae7c1f7940d0c1c8f265d1aa425cbf9919ce3523dc2d36738b690bc
  22A5342f:
    - rel: rosetta/RosettaUpdateAuto_22A5342f.pkg
      mtd: rosetta/RosettaUpdateAuto_22A5342f.meta
      sum: sha256:bdf7c2264bbb58cd86f9229915e0fbecd29bd0e676d75f0ab821db116b0620dc
  22A5352e:
    - rel: rosetta/RosettaUpdateAuto_22A5352e.pkg
      mtd: rosetta/RosettaUpdateAuto_22A5352e.meta
      sum: sha256:622231da0283947503a04a8a715edb081266d8905344b0385b6c58717740c82c
  22A5358e:
    - rel: rosetta/RosettaUpdateAuto_22A5358e.pkg
      mtd: rosetta/RosettaUpdateAuto_22A5358e.meta
      sum: sha256:f5363044ebdc92aaf16e999835ac5f1cae1b7ea4d5e7ca0db61b850319cf3b1b
  20G908:
    - rel: rosetta/RosettaUpdateAuto_20G908.pkg
      mtd: rosetta/RosettaUpdateAuto_20G908.meta
      sum: sha256:fd9705db9b54c6eb9f226fa06cfbb105aff0e5f007d53f24440342ccf603cab5
  21G207:
    - rel: rosetta/RosettaUpdateAuto_21G207.pkg
      mtd: rosetta/RosettaUpdateAuto_21G207.meta
      sum: sha256:d8d1bf8542af75f7f7acb5eeedc9e0eca685f4e51a50764e411710942a14650e
  22A5365d:
    - rel: rosetta/RosettaUpdateAuto_22A5365d.pkg
      mtd: rosetta/RosettaUpdateAuto_22A5365d.meta
      sum: sha256:b25864ed6f2a6ae584529c31a8dea3595f57cec204e3a4c9417c1684f6a443a2
  21G211:
    - rel: rosetta/RosettaUpdateAuto_21G211.pkg
      mtd: rosetta/RosettaUpdateAuto_21G211.meta
      sum: sha256:b965148a7b9aa55cb0ebd7ecb9bac8d880ea186263a199811c5ca02c02503441
  20G912:
    - rel: rosetta/RosettaUpdateAuto_20G912.pkg
      mtd: rosetta/RosettaUpdateAuto_20G912.meta
      sum: sha256:e668f675a9de6aafae54572ccc093cd9c1f1775568ebab57bc6eb43d7cb7a654
  22A5373b:
    - rel: rosetta/RosettaUpdateAuto_22A5373b.pkg
      mtd: rosetta/RosettaUpdateAuto_22A5373b.meta
      sum: sha256:3d21c7f6e0a51305020422f1737e12098b3e8917012027874fdf1f137881f262
  21G215:
    - rel: rosetta/RosettaUpdateAuto_21G215.pkg
      mtd: rosetta/RosettaUpdateAuto_21G215.meta
      sum: sha256:50f90f3f89170f999bdb74d73151f6ce141fceab7b9fa55b601c1dfeb968777a
  20G916:
    - rel: rosetta/RosettaUpdateAuto_20G916.pkg
      mtd: rosetta/RosettaUpdateAuto_20G916.meta
      sum: sha256:97e2e41d41b2acb6f2bd6813972e0715d15f325c0e1388c99ef3f7d2e91d00aa
  22A379:
    - rel: rosetta/RosettaUpdateAuto_22A379.pkg
      mtd: rosetta/RosettaUpdateAuto_22A379.meta
      sum: sha256:58d15cf587532ad53ef8aeb64316740ddbb4fa21132dba79c549a4b3876baae4
  21G217:
    - rel: rosetta/RosettaUpdateAuto_21G217.pkg
      mtd: rosetta/RosettaUpdateAuto_21G217.meta
      sum: sha256:ba526051239509139ce5990a7998cd95486dcc002687648dc2fcd8055e6e52d1
  20G918:
    - rel: rosetta/RosettaUpdateAuto_20G918.pkg
      mtd: rosetta/RosettaUpdateAuto_20G918.meta
      sum: sha256:9b9bd82134acb138fb15f27bff12aa47fbe475d9813e716a5647ae1857ebf625
  22A380:
    - rel: rosetta/RosettaUpdateAuto_22A380.pkg
      mtd: rosetta/RosettaUpdateAuto_22A380.meta
      sum: sha256:2456f3e78d93086de88de98799010cd34d2037bec8ef48b200f35fdc7d110168
  22C5033e:
    - rel: rosetta/RosettaUpdateAuto_22C5033e.pkg
      mtd: rosetta/RosettaUpdateAuto_22C5033e.meta
      sum: sha256:102f006f85aaca410a051d5343adb60387fa451f41f397ebc0d47cdcc82a4f2b
  22C5044e:
    - rel: rosetta/RosettaUpdateAuto_22C5044e.pkg
      mtd: rosetta/RosettaUpdateAuto_22C5044e.meta
      sum: sha256:835078001dd1fc5008bebd66746b04b64479f3e62ce794ec197b05ec587dfa8d
  21G309:
    - rel: rosetta/RosettaUpdateAuto_21G309.pkg
      mtd: rosetta/RosettaUpdateAuto_21G309.meta
      sum: sha256:3122258cf12b04010b6cbf05204d0a2323595ddafb5a1541bde9556647d39b9e
  20G1008:
    - rel: rosetta/RosettaUpdateAuto_20G1008.pkg
      mtd: rosetta/RosettaUpdateAuto_20G1008.meta
      sum: sha256:bc49759a3e6444cbcdb78e747b21b5c896e239307f9c8c70d0eae4f185d12e3c
  22A400:
    - rel: rosetta/RosettaUpdateAuto_22A400.pkg
      mtd: rosetta/RosettaUpdateAuto_22A400.meta
      sum: sha256:ccc422fa2be9412dac93d68cf79d1be3ec7a302b5841ee3cf7208373b8160b8d
  22C5050e:
    - rel: rosetta/RosettaUpdateAuto_22C5050e.pkg
      mtd: rosetta/RosettaUpdateAuto_22C5050e.meta
      sum: sha256:8a3d4af94de8499ca51cbb59bb36ff337af8ef0b5ea743dab7586aff3c0b501c
  21G312:
    - rel: rosetta/RosettaUpdateAuto_21G312.pkg
      mtd: rosetta/RosettaUpdateAuto_21G312.meta
      sum: sha256:7eef029b0b8a7c18501e242a62ca8587a64ccc58ed973175cf0c628ce59e6c35
  20G1011:
    - rel: rosetta/RosettaUpdateAuto_20G1011.pkg
      mtd: rosetta/RosettaUpdateAuto_20G1011.meta
      sum: sha256:a17115019c3fdb9dde68976afbc8a3c2267d0bccd68affdf7fc3a40909960557
  22C5059b:
    - rel: rosetta/RosettaUpdateAuto_22C5059b.pkg
      mtd: rosetta/RosettaUpdateAuto_22C5059b.meta
      sum: sha256:61a6a70dabfdceddafff9938ec90fac2f20869b12628c9ddbb5a1fd3fc8f00be
  21G317:
    - rel: rosetta/RosettaUpdateAuto_21G317.pkg
      mtd: rosetta/RosettaUpdateAuto_21G317.meta
      sum: sha256:681bbe7723626aacef9d55ed9e480c7432eb34a125755388fd31c7d5bb8c76a4
  22C65:
    - rel: rosetta/RosettaUpdateAuto_22C65.pkg
      mtd: rosetta/RosettaUpdateAuto_22C65.meta
      sum: sha256:1539bc643e22dbef705df96876d823bf0b5b8abac378bc46395659fb07521cb0
  21G320:
    - rel: rosetta/RosettaUpdateAuto_21G320.pkg
      mtd: rosetta/RosettaUpdateAuto_21G320.meta
      sum: sha256:f61d588b029510f85b5bbad624c467486634ed1f6bcffa2af84b250a9fa0b9ff
  20G1020:
    - rel: rosetta/RosettaUpdateAuto_20G1020.pkg
      mtd: rosetta/RosettaUpdateAuto_20G1020.meta
      sum: sha256:825ef3df2ab32a479429136892d62516a683cd3f7c02d4ddb0f5f58b0a6eb9ba
  22D5027d:
    - rel: rosetta/RosettaUpdateAuto_22D5027d.pkg
      mtd: rosetta/RosettaUpdateAuto_22D5027d.meta
      sum: sha256:222691bb0b3d82dae6fb46c236d453b0d47ef70c73d3eae7e73fbc1fd321929b
  21G403:
    - rel: rosetta/RosettaUpdateAuto_21G403.pkg
      mtd: rosetta/RosettaUpdateAuto_21G403.meta
      sum: sha256:dc30c5a92443d72363552a5d323c7c5800e2881c21322d715bc7ca3f378e6aa3
  20G1102:
    - rel: rosetta/RosettaUpdateAuto_20G1102.pkg
      mtd: rosetta/RosettaUpdateAuto_20G1102.meta
      sum: sha256:20c488d2b8b195736b49a2269bd1bcdcc9fc7d83d5f5dcb86bef528fd7b0ca5e
  22D5038i:
    - rel: rosetta/RosettaUpdateAuto_22D5038i.pkg
      mtd: rosetta/RosettaUpdateAuto_22D5038i.meta
      sum: sha256:4f7349c6bb11e003e1dff26770790e21893f2b2629b3ba47bb809bcf399fa469
  21G417:
    - rel: rosetta/RosettaUpdateAuto_21G417.pkg
      mtd: rosetta/RosettaUpdateAuto_21G417.meta
      sum: sha256:78b6085e6ac901fc9981648f6353c4d9e0ffbaccde85a1fe49507a97ea862f96
  20G1113:
    - rel: rosetta/RosettaUpdateAuto_20G1113.pkg
      mtd: rosetta/RosettaUpdateAuto_20G1113.meta
      sum: sha256:5936e5f9cefca685bf05c7f0d9c17e90c01ef7f58b280f02841405401b334fbf
  22D49:
    - rel: rosetta/RosettaUpdateAuto_22D49.pkg
      mtd: rosetta/RosettaUpdateAuto_22D49.meta
      sum: sha256:3dfbd57e926854eb44f77ad7d89f5c774adb607482e7ca661651e3d0a3009fe8
  21G419:
    - rel: rosetta/RosettaUpdateAuto_21G419.pkg
      mtd: rosetta/RosettaUpdateAuto_21G419.meta
      sum: sha256:7439d7d4c40b6372ecd840b385ef12068f5210a516fae9a69c6913c6643eb16c
  20G1116:
    - rel: rosetta/RosettaUpdateAuto_20G1116.pkg
      mtd: rosetta/RosettaUpdateAuto_20G1116.meta
      sum: sha256:764adbba88d0a15e15f42dff5644c06adaf5a8301fb449710ca14cac4d94e332
  22A8381:
    - rel: rosetta/RosettaUpdateAuto_22A8381.pkg
      mtd: rosetta/RosettaUpdateAuto_22A8381.meta
      sum: sha256:4ce1bb82a6ed9d2709a3eb49a3df8edbaff6f90197d7792034b19189eefc1db0
  22A8380:
    - rel: rosetta/RosettaUpdateAuto_22A8380.pkg
      mtd: rosetta/RosettaUpdateAuto_22A8380.meta
      sum: sha256:9c6a40dab803ce150f094a0c3ada3551d3d17e222a373acf47a703720faa5c4b
  22D68:
    - rel: rosetta/RosettaUpdateAuto_22D68.pkg
      mtd: rosetta/RosettaUpdateAuto_22D68.meta
      sum: sha256:fae370ca948b7e028d41500a3e6da6ad5f539129148f61feba65513f4719f2a0
  20G1120:
    - rel: rosetta/RosettaUpdateAuto_20G1120.pkg
      mtd: rosetta/RosettaUpdateAuto_20G1120.meta
      sum: sha256:fb55d37d895537e01aadc698fedf3d1aed4fcf3d5847a333512ab8b1d555af8e
  22E5219e:
    - rel: rosetta/RosettaUpdateAuto_22E5219e.pkg
      mtd: rosetta/RosettaUpdateAuto_22E5219e.meta
      sum: sha256:8c3bdc04a9e062c7f8d0c377520340e96fec3593a4ffed4a17b30c64968050bd
  21G506:
    - rel: rosetta/RosettaUpdateAuto_21G506.pkg
      mtd: rosetta/RosettaUpdateAuto_21G506.meta
      sum: sha256:142415bd550ccaa2d2adb3a1fe54f00ca7a876aaa057890488613dd09e62b8ee
  20G1205:
    - rel: rosetta/RosettaUpdateAuto_20G1205.pkg
      mtd: rosetta/RosettaUpdateAuto_20G1205.meta
      sum: sha256:323ed0f1a71f4fdfb3406083049cb1b3bec05d0fc2e056c9d9e6e9bac4bab643
  22E5230e:
    - rel: rosetta/RosettaUpdateAuto_22E5230e.pkg
      mtd: rosetta/RosettaUpdateAuto_22E5230e.meta
      sum: sha256:805ce982906596aa16ae23fafe15b05fe8f0b507960ebcfa9d348552ab3b327f
  21G511:
    - rel: rosetta/RosettaUpdateAuto_21G511.pkg
      mtd: rosetta/RosettaUpdateAuto_21G511.meta
      sum: sha256:92297ac545edd59061596eef9b8712f8c0624589d7330a46c3dd57337bf99278
  20G1210:
    - rel: rosetta/RosettaUpdateAuto_20G1210.pkg
      mtd: rosetta/RosettaUpdateAuto_20G1210.meta
      sum: sha256:f8441460242383a0bf2e1cb6fa541c9e5b8544d0e8162d4ad4d528a30eaa5b38
  22E5236f:
    - rel: rosetta/RosettaUpdateAuto_22E5236f.pkg
      mtd: rosetta/RosettaUpdateAuto_22E5236f.meta
      sum: sha256:2d53465fd434e814e6b4e712d9b9d0b07c3eb0e7c3877dbb8ae468dcecd93105
  21G516:
    - rel: rosetta/RosettaUpdateAuto_21G516.pkg
      mtd: rosetta/RosettaUpdateAuto_21G516.meta
      sum: sha256:99c7c0438e2ba9b46ab1c1994a6ed240148fd2773fe271aa0cc10aa5e8785d2b
  20G1215:
    - rel: rosetta/RosettaUpdateAuto_20G1215.pkg
      mtd: rosetta/RosettaUpdateAuto_20G1215.meta
      sum: sha256:be5b32e8712a58a89219ce7ffb115a15e274f45b75aac16ff73200e46d556804
  22E5246b:
    - rel: rosetta/RosettaUpdateAuto_22E5246b.pkg
      mtd: rosetta/RosettaUpdateAuto_22E5246b.meta
      sum: sha256:43c3edff0f15c620b8225d833891f69aacb61abf8f290eb3cdba5bb2dd2a9dd9
  21G521:
    - rel: rosetta/RosettaUpdateAuto_21G521.pkg
      mtd: rosetta/RosettaUpdateAuto_21G521.meta
      sum: sha256:7548517121c35bc350c3085437e0c33d6187d7427f2df096ff4a84396c39c756
  20G1220:
    - rel: rosetta/RosettaUpdateAuto_20G1220.pkg
      mtd: rosetta/RosettaUpdateAuto_20G1220.meta
      sum: sha256:33f09cb1e7f0a45143b4121ef134aa9b56fb8cfc335074a807d04d521db16fd6
  21G526:
    - rel: rosetta/RosettaUpdateAuto_21G526.pkg
      mtd: rosetta/RosettaUpdateAuto_21G526.meta
      sum: sha256:cd00dbeb2f8f66cf3e306f13844d3b0b6888de3ce2594572044032d6e92e49e6
  20G1225:
    - rel: rosetta/RosettaUpdateAuto_20G1225.pkg
      mtd: rosetta/RosettaUpdateAuto_20G1225.meta
      sum: sha256:931f55950c3200a8111686484ad3ae4694a880aeccf9d8679a31acad33ed9721
  22E252:
    - rel: rosetta/RosettaUpdateAuto_22E252.pkg
      mtd: rosetta/RosettaUpdateAuto_22E252.meta
      sum: sha256:b6aa138a93c42b883f9ae5ea8c1c89515ebd7d07c62278ebbeb293aeb4f38ea2
  22F5027f:
    - rel: rosetta/RosettaUpdateAuto_22F5027f.pkg
      mtd: rosetta/RosettaUpdateAuto_22F5027f.meta
      sum: sha256:eb249770491b906aabeda6665193c1ba453cd5653d90e8862547e9545e94cf9f
  21G630:
    - rel: rosetta/RosettaUpdateAuto_21G630.pkg
      mtd: rosetta/RosettaUpdateAuto_21G630.meta
      sum: sha256:6e222d09074661cf2140beab7d7e0fce5910c524b52672053ea365930ef79314
  20G1329:
    - rel: rosetta/RosettaUpdateAuto_20G1329.pkg
      mtd: rosetta/RosettaUpdateAuto_20G1329.meta
      sum: sha256:8930e2f0f6adf6b838f3a0e70a7d2d37a6352d26a0e6e4375e66be4d15e8ff8b
  22E261:
    - rel: rosetta/RosettaUpdateAuto_22E261.pkg
      mtd: rosetta/RosettaUpdateAuto_22E261.meta
      sum: sha256:f1543d3b09b4779732f74c164c8870f7cfcdab52d8e31813de435c2e487ba8ad
  21G531:
    - rel: rosetta/RosettaUpdateAuto_21G531.pkg
      mtd: rosetta/RosettaUpdateAuto_21G531.meta
      sum: sha256:17c31ed15eb78300137ee1649839d6a1a5ca51b87c0733bf87c0fd937daee5c0
  20G1231:
    - rel: rosetta/RosettaUpdateAuto_20G1231.pkg
      mtd: rosetta/RosettaUpdateAuto_20G1231.meta
      sum: sha256:a5faf3c677a75fe830345c6a60a0112b4f8f14872eaf876eb01d74b92b38b135
  22F5037d:
    - rel: rosetta/RosettaUpdateAuto_22F5037d.pkg
      mtd: rosetta/RosettaUpdateAuto_22F5037d.meta
      sum: sha256:b9269ac4501ded75d04c875ffee2253ebfc50b7e9b75051fe6d2005a4fd46fb4
  21G633:
    - rel: rosetta/RosettaUpdateAuto_21G633.pkg
      mtd: rosetta/RosettaUpdateAuto_21G633.meta
      sum: sha256:d5124c83a8a3266abed1f3b1a28b68334505c041bffa782f35f6722850556215
  20G1332:
    - rel: rosetta/RosettaUpdateAuto_20G1332.pkg
      mtd: rosetta/RosettaUpdateAuto_20G1332.meta
      sum: sha256:b3bea280a1b95f8908504bd5e38c33c2eb648517744c4cc02a000c4e2b382c0b
  22F5049e:
    - rel: rosetta/RosettaUpdateAuto_22F5049e.pkg
      mtd: rosetta/RosettaUpdateAuto_22F5049e.meta
      sum: sha256:ae206c072d929bb1343c4ec3ac6a67ff2cb21c468543b63a7313fe5c139d5f1e
  21G639:
    - rel: rosetta/RosettaUpdateAuto_21G639.pkg
      mtd: rosetta/RosettaUpdateAuto_21G639.meta
      sum: sha256:f46644688e8675cadd3a0d91ef9940572cc1cd7995a9c1688efd49450ff52a83
  20G1338:
    - rel: rosetta/RosettaUpdateAuto_20G1338.pkg
      mtd: rosetta/RosettaUpdateAuto_20G1338.meta
      sum: sha256:feb713e4c6a4c32e02d15d76a264773393f21abc0e14efe798d0999eb974f4d4
  22F5059b:
    - rel: rosetta/RosettaUpdateAuto_22F5059b.pkg
      mtd: rosetta/RosettaUpdateAuto_22F5059b.meta
      sum: sha256:62c85b50f04803235bd0a5644a16645aa7b78a25f08fb6c2b06b4eae0bc2746c
  21G644:
    - rel: rosetta/RosettaUpdateAuto_21G644.pkg
      mtd: rosetta/RosettaUpdateAuto_21G644.meta
      sum: sha256:7f368e17869585709e39c3ddfda3b18262efbb2bda4de378fe680548bae27d57
  20G1342:
    - rel: rosetta/RosettaUpdateAuto_20G1342.pkg
      mtd: rosetta/RosettaUpdateAuto_20G1342.meta
      sum: sha256:1156283fcf3de2135cb8bad611e15910baa2e64e8d57fecc4840ab530294552f
  22F62:
    - rel: rosetta/RosettaUpdateAuto_22F62.pkg
      mtd: rosetta/RosettaUpdateAuto_22F62.meta
      sum: sha256:ef5b3ee2c7306464da98f35dc587738c7d79b64840c1834eeb8e44f0d2694f5f
  21G646:
    - rel: rosetta/RosettaUpdateAuto_21G646.pkg
      mtd: rosetta/RosettaUpdateAuto_21G646.meta
      sum: sha256:c6b4f7c96c2b94c002b5ca53652b11383cbb7330146ea9f7e60082660b09a5df
  20G1345:
    - rel: rosetta/RosettaUpdateAuto_20G1345.pkg
      mtd: rosetta/RosettaUpdateAuto_20G1345.meta
      sum: sha256:2882f0a63d7de9b39fd07e9eda5829574207e2b73fab245c96782135f0a0e2e7
  22F63:
    - rel: rosetta/RosettaUpdateAuto_22F63.pkg
      mtd: rosetta/RosettaUpdateAuto_22F63.meta
      sum: sha256:31da6e5eebd7d91283b34b02aa4a62ae7b7bad7f9aa4223e9ecb38a731a1cb75
  22F66:
    - rel: rosetta/RosettaUpdateAuto_22F66.pkg
      mtd: rosetta/RosettaUpdateAuto_22F66.meta
      sum: sha256:8ac9feb4f90934584b4a5e531a1f4a6d62ffd5c8dd2e883c7d4596a2e92f5d71
  21G703:
    - rel: rosetta/RosettaUpdateAuto_21G703.pkg
      mtd: rosetta/RosettaUpdateAuto_21G703.meta
      sum: sha256:3ee70906ddf164f706002374c424700dc84f606d5b0d57adacab01cbc4978535
  20G1403:
    - rel: rosetta/RosettaUpdateAuto_20G1403.pkg
      mtd: rosetta/RosettaUpdateAuto_20G1403.meta
      sum: sha256:5a8531440424884c47547e94bd7890548094051f09e47177cc4eae23bbc6fb8b
  22G5027e:
    - rel: rosetta/RosettaUpdateAuto_22G5027e.pkg
      mtd: rosetta/RosettaUpdateAuto_22G5027e.meta
      sum: sha256:c2d62b99174a038aed56fc6c82e91226f7863cde03d663b7447cf24d33315440
  22G5038d:
    - rel: rosetta/RosettaUpdateAuto_22G5038d.pkg
      mtd: rosetta/RosettaUpdateAuto_22G5038d.meta
      sum: sha256:4f438aa5190a419a200c9d1cafcfda90315fb78bcd396ed47358a5a8b18edb26
  21G708:
    - rel: rosetta/RosettaUpdateAuto_21G708.pkg
      mtd: rosetta/RosettaUpdateAuto_21G708.meta
      sum: sha256:8a5d5688c61605787e180d6e58c6d0ca5e3fd9a823e9b137642ba93abcbd0bf4
  20G1407:
    - rel: rosetta/RosettaUpdateAuto_20G1407.pkg
      mtd: rosetta/RosettaUpdateAuto_20G1407.meta
      sum: sha256:7ab5978ffae0af4df7238f98327fb1af6cd25adaf655db9d43b71acf0c32e473
  23A5257q:
    - rel: rosetta/RosettaUpdateAuto_23A5257q.pkg
      mtd: rosetta/RosettaUpdateAuto_23A5257q.meta
      sum: sha256:028f0c574bc52d8f42a081e70b220130ca63ba1203ebe5fbaf1adad28a34e8c7
  22E8252:
    - rel: rosetta/RosettaUpdateAuto_22E8252.pkg
      mtd: rosetta/RosettaUpdateAuto_22E8252.meta
      sum: sha256:966df8c8403f0178aa2ae7163bf6679062f28c440f174324ab133ed324bb8d39
  22F2073:
    - rel: rosetta/RosettaUpdateAuto_22F2073.pkg
      mtd: rosetta/RosettaUpdateAuto_22F2073.meta
      sum: sha256:5f99e11eec64322809b9639a4435491ddf65c84693e511cb2ac1961d162f3d35
  22F2063:
    - rel: rosetta/RosettaUpdateAuto_22F2063.pkg
      mtd: rosetta/RosettaUpdateAuto_22F2063.meta
      sum: sha256:d779273289b7ae3b247dd42352471ba6055861b8be8963bcf667d9b70dc44583
  22G5048d:
    - rel: rosetta/RosettaUpdateAuto_22G5048d.pkg
      mtd: rosetta/RosettaUpdateAuto_22G5048d.meta
      sum: sha256:ed487d0bf42ee4e225e6e0632cc06de407703f9f32bb9e485b07718bc7f9a608
  21G713:
    - rel: rosetta/RosettaUpdateAuto_21G713.pkg
      mtd: rosetta/RosettaUpdateAuto_21G713.meta
      sum: sha256:552a03eadd71406f6dd221351f249325cec0a806ef6afde66177ab4c4715877f
  20G1413:
    - rel: rosetta/RosettaUpdateAuto_20G1413.pkg
      mtd: rosetta/RosettaUpdateAuto_20G1413.meta
      sum: sha256:ea4647feec5252da17e2d92fc559b820b09499d73afa5741bfa31da236f17032
  22F82:
    - rel: rosetta/RosettaUpdateAuto_22F82.pkg
      mtd: rosetta/RosettaUpdateAuto_22F82.meta
      sum: sha256:06bf22d73da963f9875f8c6d34a49bdd901b38bc8226049d9a1227fe7ca42e99
  20G1351:
    - rel: rosetta/RosettaUpdateAuto_20G1351.pkg
      mtd: rosetta/RosettaUpdateAuto_20G1351.meta
      sum: sha256:e4e5809b206664c1d7a0917fe3042b66055a7e1ecbfc85b753aac88c1ac8d2fc
  22F2083:
    - rel: rosetta/RosettaUpdateAuto_22F2083.pkg
      mtd: rosetta/RosettaUpdateAuto_22F2083.meta
      sum: sha256:b1da92a2fc3ec2a74f9396df8224498868694474b2bcaba4a4d3cfee3da29f55
  21G651:
    - rel: rosetta/RosettaUpdateAuto_21G651.pkg
      mtd: rosetta/RosettaUpdateAuto_21G651.meta
      sum: sha256:f055be44140d27bf2415d2948220d92cbe1bb243178cf1e1dc02f69fcd9889ce
  23A5276g:
    - rel: rosetta/RosettaUpdateAuto_23A5276g.pkg
      mtd: rosetta/RosettaUpdateAuto_23A5276g.meta
      sum: sha256:6f8165b68a13972e5e38e23d23a314731a983977047a4a74215afb3838ba4143
  22G5059d:
    - rel: rosetta/RosettaUpdateAuto_22G5059d.pkg
      mtd: rosetta/RosettaUpdateAuto_22G5059d.meta
      sum: sha256:c309381e28387aafb89e39b3075d0f595558ccb5dc6b50475b417413466b5ad2
  21G716:
    - rel: rosetta/RosettaUpdateAuto_21G716.pkg
      mtd: rosetta/RosettaUpdateAuto_21G716.meta
      sum: sha256:570ab5ff3553b6cf5411180a5d9c0f1bf0b8268505fe820a7b47b71ca4f313c7
  20G1416:
    - rel: rosetta/RosettaUpdateAuto_20G1416.pkg
      mtd: rosetta/RosettaUpdateAuto_20G1416.meta
      sum: sha256:69bfc84b7c5940af794bc36ba06c3375500b2e2b48eb6c19172b62ef57f68e0c
  23A5286g:
    - rel: rosetta/RosettaUpdateAuto_23A5286g.pkg
      mtd: rosetta/RosettaUpdateAuto_23A5286g.meta
      sum: sha256:706307033195dd00604e0d499a8162d41640f575dd82e219018a8c154168bdcf
  22G5072a:
    - rel: rosetta/RosettaUpdateAuto_22G5072a.pkg
      mtd: rosetta/RosettaUpdateAuto_22G5072a.meta
      sum: sha256:e3a3456cc58dad36e23c14df5440e079c70ea7eb8924b79139fb42d808949f73
  21G724:
    - rel: rosetta/RosettaUpdateAuto_21G724.pkg
      mtd: rosetta/RosettaUpdateAuto_21G724.meta
      sum: sha256:6881700d3e49b10e4d497b66e8a66b4e02ae1cccb20c1db09fbc3ce8e053e807
  20G1424:
    - rel: rosetta/RosettaUpdateAuto_20G1424.pkg
      mtd: rosetta/RosettaUpdateAuto_20G1424.meta
      sum: sha256:546d2d8c22c258e741be8ec0ecc6ec644c23d1a7366df6de1ee3aefec0866803
  23A5286i:
    - rel: rosetta/RosettaUpdateAuto_23A5286i.pkg
      mtd: rosetta/RosettaUpdateAuto_23A5286i.meta
      sum: sha256:e576d75a757ab9905d1a8ef6656a11a219e40b0394efac4a387822ad5d2ac0e3
  22G74:
    - rel: rosetta/RosettaUpdateAuto_22G74.pkg
      mtd: rosetta/RosettaUpdateAuto_22G74.meta
      sum: sha256:c0f96086272fcd12bc94ccf1793bc4f940045ec8d44e8361879f2c394afe081a
  21G725:
    - rel: rosetta/RosettaUpdateAuto_21G725.pkg
      mtd: rosetta/RosettaUpdateAuto_21G725.meta
      sum: sha256:529c6b25d006b4a0139f34dff480776beea3e05f9332466a18fa6bdcf1474633
  20G1426:
    - rel: rosetta/RosettaUpdateAuto_20G1426.pkg
      mtd: rosetta/RosettaUpdateAuto_20G1426.meta
      sum: sha256:063039f4178f0adcd37ff9dbde36d9a03741127ee6c362c769cc709943ce046a
  23A5301g:
    - rel: rosetta/RosettaUpdateAuto_23A5301g.pkg
      mtd: rosetta/RosettaUpdateAuto_23A5301g.meta
      sum: sha256:cf380131db74e8a0aa03a958a9cbc5aec15bc4c55feeb779b53e9f615f58a961
  23A5301h:
    - rel: rosetta/RosettaUpdateAuto_23A5301h.pkg
      mtd: rosetta/RosettaUpdateAuto_23A5301h.meta
      sum: sha256:1ba39bc5e24116767cb19b706b262928ed7627cebf91c9e11801bf24b6d787a8
  23A5312d:
    - rel: rosetta/RosettaUpdateAuto_23A5312d.pkg
      mtd: rosetta/RosettaUpdateAuto_23A5312d.meta
      sum: sha256:f186efb81da7da8e610720e4c775a296e9e708ae232b3bffa0184ae84ca0e5ec
  22G90:
    - rel: rosetta/RosettaUpdateAuto_22G90.pkg
      mtd: rosetta/RosettaUpdateAuto_22G90.meta
      sum: sha256:a727a14cd4f4b0ae542dd35bfca59fa6f57bab604054ed7e18f162e21987304c
  22G109:
    - rel: rosetta/RosettaUpdateAuto_22G109.pkg
      mtd: rosetta/RosettaUpdateAuto_22G109.meta
      sum: sha256:f36ea09cd0ec2ebf755df36b01aac93aae0b34a7f0135c4b84a114b40511be24
  21G808:
    - rel: rosetta/RosettaUpdateAuto_21G808.pkg
      mtd: rosetta/RosettaUpdateAuto_21G808.meta
      sum: sha256:c99d6cf8fa760761b1b7ad14068096b62abaaf5e1fc5262757500d6b4156a649
  23A5328b:
    - rel: rosetta/RosettaUpdateAuto_23A5328b.pkg
      mtd: rosetta/RosettaUpdateAuto_23A5328b.meta
      sum: sha256:83a2099bd3045a2df2f435ffb4a93de276829b86ffa4dfbfb8cf5b6dd4878917
  23A5337a:
    - rel: rosetta/RosettaUpdateAuto_23A5337a.pkg
      mtd: rosetta/RosettaUpdateAuto_23A5337a.meta
      sum: sha256:9fb16f15330a33d9a25498b783a6494067e6d34ad1ab91da152e40a4b8d3d4d1
  22G115:
    - rel: rosetta/RosettaUpdateAuto_22G115.pkg
      mtd: rosetta/RosettaUpdateAuto_22G115.meta
      sum: sha256:c2c6dc07ba381bb0d2e2c23c59b1435478545beee84c1a1ec410844bb0b8a80a
  21G813:
    - rel: rosetta/RosettaUpdateAuto_21G813.pkg
      mtd: rosetta/RosettaUpdateAuto_21G813.meta
      sum: sha256:4ce1630f2fb75a556257a40c24092ace7ea7bf957ee0e48a2c169c60addd63e9
  22G91:
    - rel: rosetta/RosettaUpdateAuto_22G91.pkg
      mtd: rosetta/RosettaUpdateAuto_22G91.meta
      sum: sha256:ae1c8b3f93ffb3b5df41a225337354d3f813fd5c9a8373c4ab9a134e498c0b84
  21G726:
    - rel: rosetta/RosettaUpdateAuto_21G726.pkg
      mtd: rosetta/RosettaUpdateAuto_21G726.meta
      sum: sha256:fa2eba94c340b324661bb850a62466287bff38a0708311018681eb5c52b6a28e
  20G1427:
    - rel: rosetta/RosettaUpdateAuto_20G1427.pkg
      mtd: rosetta/RosettaUpdateAuto_20G1427.meta
      sum: sha256:b9eeddfec16f4e65d4cbd32a6bc9e3da339410ea82e4c9fed077f231582c8111
  23A339:
    - rel: rosetta/RosettaUpdateAuto_23A339.pkg
      mtd: rosetta/RosettaUpdateAuto_23A339.meta
      sum: sha256:5e7a8a7096a2e6f1d639c781356fc2ded01dab20d4d7b0caecdb09910c13da9a
  22G116:
    - rel: rosetta/RosettaUpdateAuto_22G116.pkg
      mtd: rosetta/RosettaUpdateAuto_22G116.meta
      sum: sha256:69451d9a7419a69bcc9bc485abf40fb3e47d28c29bc1a61a82b8104bba99c5ef
  21G814:
    - rel: rosetta/RosettaUpdateAuto_21G814.pkg
      mtd: rosetta/RosettaUpdateAuto_21G814.meta
      sum: sha256:1b766a90af9a786256ec5f6f30cd15e801009308b3051d931e391e7901491cec
  23A344:
    - rel: rosetta/RosettaUpdateAuto_23A344.pkg
      mtd: rosetta/RosettaUpdateAuto_23A344.meta
      sum: sha256:13a7b520f6615103fcf750f9858a0925012b3bf9fc28226bf4377077d9598a4d
  22G120:
    - rel: rosetta/RosettaUpdateAuto_22G120.pkg
      mtd: rosetta/RosettaUpdateAuto_22G120.meta
      sum: sha256:2211cdcdb5510a80ec6c991c84403b24b4127265eb6c88088359d1add5eee256
  21G816:
    - rel: rosetta/RosettaUpdateAuto_21G816.pkg
      mtd: rosetta/RosettaUpdateAuto_21G816.meta
      sum: sha256:81ff5687b432f30d824b6a61ae7d96f261be08f5933fb8c16e9f21993a96fbbd
  23B5046f:
    - rel: rosetta/RosettaUpdateAuto_23B5046f.pkg
      mtd: rosetta/RosettaUpdateAuto_23B5046f.meta
      sum: sha256:8206e4bbfba09b0845b0a458177021c3c43c35266e10da7aa0b838cb3616b350
  23B5056e:
    - rel: rosetta/RosettaUpdateAuto_23B5056e.pkg
      mtd: rosetta/RosettaUpdateAuto_23B5056e.meta
      sum: sha256:ce2415874b6935e33dc34d97b6633ff329eb1b1b702a0e8c39981de3833ea620
  22G213:
    - rel: rosetta/RosettaUpdateAuto_22G213.pkg
      mtd: rosetta/RosettaUpdateAuto_22G213.meta
      sum: sha256:09417987eb7b03da4d0be3e53fda1b11a749380cae78ee8d131080b43b0f9ce7
  21G913:
    - rel: rosetta/RosettaUpdateAuto_21G913.pkg
      mtd: rosetta/RosettaUpdateAuto_21G913.meta
      sum: sha256:bb1811fa6c18c06b2c9be9388c3f5461f8fe7e4ba41153b9499a4e35a48bf1c9
  23B5067a:
    - rel: rosetta/RosettaUpdateAuto_23B5067a.pkg
      mtd: rosetta/RosettaUpdateAuto_23B5067a.meta
      sum: sha256:fa55fa81cf1b1b9594b661b13f890d310c5ffd37e8d88a0667766c28a04259f8
  21G918:
    - rel: rosetta/RosettaUpdateAuto_21G918.pkg
      mtd: rosetta/RosettaUpdateAuto_21G918.meta
      sum: sha256:97d9b012511af6e59266862691cadb688796dabdb3bfa520aec9bbf2e5effb17
  22G311:
    - rel: rosetta/RosettaUpdateAuto_22G311.pkg
      mtd: rosetta/RosettaUpdateAuto_22G311.meta
      sum: sha256:3c99300a689057c5f2567a606144f9e05c447e2c90b219c41183f92d14bc4a17
  23B73:
    - rel: rosetta/RosettaUpdateAuto_23B73.pkg
      mtd: rosetta/RosettaUpdateAuto_23B73.meta
      sum: sha256:6ae48c2aefce856e8eb84e03155cdefc47d0b26257dfa19b266e082e933cc16a
  22G313:
    - rel: rosetta/RosettaUpdateAuto_22G313.pkg
      mtd: rosetta/RosettaUpdateAuto_22G313.meta
      sum: sha256:5aaf9f80d0209dd62bf7db0b058b2a4433a1d909080bc5dd727a86fafca5f090
  21G920:
    - rel: rosetta/RosettaUpdateAuto_21G920.pkg
      mtd: rosetta/RosettaUpdateAuto_21G920.meta
      sum: sha256:11368dbc3d6f02d94171c562a3523e2ca35d178004114eeccf5c990e1fb09e87
  23B74:
    - rel: rosetta/RosettaUpdateAuto_23B74.pkg
      mtd: rosetta/RosettaUpdateAuto_23B74.meta
      sum: sha256:1e8828fa7d365a9171e2666c823f5cac423f9ff3b2736ff2cf415d53be56db61
  23C5030f:
    - rel: rosetta/RosettaUpdateAuto_23C5030f.pkg
      mtd: rosetta/RosettaUpdateAuto_23C5030f.meta
      sum: sha256:17661ee457a15791c7338e1bd55898da21ded884dddb0cf109781d248d150eaa
  22G417:
    - rel: rosetta/RosettaUpdateAuto_22G417.pkg
      mtd: rosetta/RosettaUpdateAuto_22G417.meta
      sum: sha256:fb0ca23c86a892b046a69b2803084020378dd4852bd08ed044e3f8649d3445ab
  21G1925:
    - rel: rosetta/RosettaUpdateAuto_21G1925.pkg
      mtd: rosetta/RosettaUpdateAuto_21G1925.meta
      sum: sha256:224b8c272483c22085c848bf42b536db2f85ad28ccee842b12358020f127c66f
  23B2073:
    - rel: rosetta/RosettaUpdateAuto_23B2073.pkg
      mtd: rosetta/RosettaUpdateAuto_23B2073.meta
      sum: sha256:ddec96bbf684c34b45fc9f2358eb7b46d0caf7f9babc90f72de6ba0ab4c05cdb
  23B2077:
    - rel: rosetta/RosettaUpdateAuto_23B2077.pkg
      mtd: rosetta/RosettaUpdateAuto_23B2077.meta
      sum: sha256:46628d520cea69c95eb7d5be540ad6c20c346df3fadeb1ba7a10180762777755
  22G2080:
    - rel: rosetta/RosettaUpdateAuto_22G2080.pkg
      mtd: rosetta/RosettaUpdateAuto_22G2080.meta
      sum: sha256:a96ba3655d4f96bbb55044c40c18c2c331d2c1a20a59f4048bcecde25e64cd45
  22G2074:
    - rel: rosetta/RosettaUpdateAuto_22G2074.pkg
      mtd: rosetta/RosettaUpdateAuto_22G2074.meta
      sum: sha256:0cb42913b7cc03b828ebea4865945c8f17f33642b5b4ed9f3619339aeba37b01
  23B81:
    - rel: rosetta/RosettaUpdateAuto_23B81.pkg
      mtd: rosetta/RosettaUpdateAuto_23B81.meta
      sum: sha256:b095ad00a1038a18a4e69afc7167d6a2f038bc8f5b45493ca35f769d8942b3fa
  23B2082:
    - rel: rosetta/RosettaUpdateAuto_23B2082.pkg
      mtd: rosetta/RosettaUpdateAuto_23B2082.meta
      sum: sha256:943bc5ec21f8b0183b93151832cba594d987a2656f2e98efd74edf8efeea5b2b
  22G320:
    - rel: rosetta/RosettaUpdateAuto_22G320.pkg
      mtd: rosetta/RosettaUpdateAuto_22G320.meta
      sum: sha256:7b4d22f11818eeedd11c1bd358b19aeef5d862bc4656372fbb697f4ade2a6da6
  22G2321:
    - rel: rosetta/RosettaUpdateAuto_22G2321.pkg
      mtd: rosetta/RosettaUpdateAuto_22G2321.meta
      sum: sha256:e26cc7fd129425fc8969f6bbc5c54bfb0d4db5d1b4dde029b4534b958a7c581c
  22G423:
    - rel: rosetta/RosettaUpdateAuto_22G423.pkg
      mtd: rosetta/RosettaUpdateAuto_22G423.meta
      sum: sha256:937e86ea384b1dd3dcfd4b7bedf828177ddb9edb903a27e187c7707f536ce7f3
  23C5041e:
    - rel: rosetta/RosettaUpdateAuto_23C5041e.pkg
      mtd: rosetta/RosettaUpdateAuto_23C5041e.meta
      sum: sha256:ed560b81d22f7541df0121793f35b6088bea3cb672bf2d9f92a2b5b80572103a
  21G1965:
    - rel: rosetta/RosettaUpdateAuto_21G1965.pkg
      mtd: rosetta/RosettaUpdateAuto_21G1965.meta
      sum: sha256:bf23edf5146f92cb5b508c241192f501381b9edd4d008720c45775dfbfe084c8
  23C5047e:
    - rel: rosetta/RosettaUpdateAuto_23C5047e.pkg
      mtd: rosetta/RosettaUpdateAuto_23C5047e.meta
      sum: sha256:8b0ef3095a370b2608349f4e79f5d9ae55d6f1c12cb7c2bab9c2f90bf250b749
  22G430:
    - rel: rosetta/RosettaUpdateAuto_22G430.pkg
      mtd: rosetta/RosettaUpdateAuto_22G430.meta
      sum: sha256:9cdd6c8cadfbca8de2bc1acd87aa733c16cfe00cd4a6900bba6bf512b5ba8f8f
  21G1967:
    - rel: rosetta/RosettaUpdateAuto_21G1967.pkg
      mtd: rosetta/RosettaUpdateAuto_21G1967.meta
      sum: sha256:34e40a863aaec921995ab5a21078f58ea51d8f6bbbb91ede45524d8514abfc50
```

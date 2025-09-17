let
  pubKey = "age1r3ee8yzrvhsqzpur68xpuheg8g66q3g4eu8dk4eft9xyh0nczdhqpn3grr";
in
{
  "nextdns-config.age".publicKeys  = [ pubKey ];
  "hashed-password.age".publicKeys = [ pubKey ];
}

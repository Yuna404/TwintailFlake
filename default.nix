let
  lock = builtins.fromJSON (builtins.readFile ./flake.lock);
  locked = lock.nodes.nixpkgs.locked;
  nixpkgs = fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/${locked.rev}.tar.gz";
    sha256 = locked.narHash;
  };
  pkgs = import nixpkgs {
    system = "x86_64-linux";
    config.allowUnfree = true;
  };
in
{
  twintaillauncher = pkgs.callPackage ./package.nix { };
}

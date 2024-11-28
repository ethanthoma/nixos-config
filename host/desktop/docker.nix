{ ... }:

{
  virtualisation.docker.enable = true;

  users.extraGroups.docker.members = [ "username-with-access-to-socket" ];
}

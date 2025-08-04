{
  inputs,
  ...
}:

{
  systems = builtins.attrValues (builtins.mapAttrs (_: host: host.system) inputs.self.hosts);
}
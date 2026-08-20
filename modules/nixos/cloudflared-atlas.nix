{ ... }:
{
  # Tunnel UUID and hostname are not secrets (a Cloudflare tunnel id is useless
  # without the credentials json, which stays in /var/lib and never enters this
  # repo). So the tunnel is declared normally here.
  flake.nixosModules.cloudflared-atlas =
    { ... }:
    {
      services.cloudflared = {
        enable = true;
        tunnels."93c151d8-b148-4fb8-b256-e1a67e45c601" = {
          credentialsFile = "/var/lib/cloudflared/atlas-llm.json";
          default = "http_status:404";
          ingress."llm.gaugenumerics.com" = "http://localhost:8080";
        };
      };
    };
}

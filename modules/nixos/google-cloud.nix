{ self, ... }:
{
  flake.nixosModules.google-cloud =
    { config, ... }:
    {
      imports = [ self.nixosModules.sops ];

      sops.secrets.google-adc = {
        sopsFile = ../../secrets/google-adc.json;
        format = "json";
        key = "";
        owner = "ethanthoma";
        mode = "0400";
      };

      home-manager.users.ethanthoma.home.sessionVariables = {
        GOOGLE_APPLICATION_CREDENTIALS = config.sops.secrets.google-adc.path;
        GOOGLE_CLOUD_PROJECT = "pi-vertex-515304";
        GOOGLE_CLOUD_LOCATION = "global";
      };
    };
}

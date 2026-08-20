{ ... }:
{
  flake.nixosModules.llama-server =
    { pkgs, ... }:
    let
      llama-cpp-rocm = (pkgs.llama-cpp.override { rocmSupport = true; }).overrideAttrs (old: {
        version = "10419";
        src = pkgs.fetchFromGitHub {
          owner = "ggml-org";
          repo = "llama.cpp";
          tag = "b10419";
          hash = "sha256-5ZxaSfXztj/pSSTbUhh7SG3hiQedz/cOvn9QM7dBkSs=";
        };
        npmDeps = old.npmDeps.overrideAttrs (_: {
          outputHash = "sha256-2Q7XhaLAArmviOLdQsNbYTfdyDE5pW9lR26cRHEVl9k=";
        });
      });

      model = "/var/lib/llama-models/ornith-1.0-35b-IQ4_XS-MTP-graft-headQ6.gguf";

      # MTP self-speculative decoding: the grafted next-token heads draft, the
      # target verifies, so output is identical to plain decode but ~1.8x faster
      # on structured workloads. --parallel 1 is required (MTP gains vanish with
      # multiple slots), so concurrent requests queue.
      llamaArgs = [
        "--host"
        "0.0.0.0"
        "--port"
        "8080"
        "-m"
        model
        "-ngl"
        "99"
        "-c"
        "32768"
        "--parallel"
        "1"
        "--flash-attn"
        "on"
        "--jinja"
        "--temp"
        "0.6"
        "--top-k"
        "20"
        "--top-p"
        "0.95"
        "--spec-type"
        "draft-mtp"
        "--spec-draft-n-max"
        "4"
        "--reasoning-budget"
        "1024"
        "--no-context-shift"
        "--cache-type-k"
        "q8_0"
        "--cache-type-v"
        "q8_0"
      ];
    in
    {
      networking.firewall.allowedTCPPorts = [ 8080 ];

      systemd.services.llama-server = {
        description = "llama.cpp OpenAI-compatible server (Ornith 1.0 35B MTP self-speculative on ROCm)";
        wantedBy = [ "multi-user.target" ];
        after = [ "network.target" ];
        unitConfig.ConditionPathExists = model;
        serviceConfig = {
          ExecStart = "${llama-cpp-rocm}/bin/llama-server ${toString llamaArgs} --api-key \${LLAMA_API_KEY}";
          EnvironmentFile = "/var/lib/llama-server.env";
          Restart = "on-failure";
          RestartSec = 5;
          DynamicUser = true;
          SupplementaryGroups = [
            "video"
            "render"
          ];
        };
      };
    };
}

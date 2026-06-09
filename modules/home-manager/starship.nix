{ ... }:
{
  flake.homeManagerModules.starship =
    { pkgs, config, ... }:
    let
      bakeInit = import ../_lib/bake-init.nix { inherit (pkgs) runCommand; };
    in
    {
      programs.starship = {
        enable = true;
        enableBashIntegration = false;

        settings = {
          format = "$username$hostname$all";
          add_newline = false;

          username = {
            format = "\\[[$user]($style)";
            show_always = true;
          };
          hostname = {
            ssh_only = false;
            format = "@[$hostname]($style)\\]";
          };
          directory = {
            format = "\\[[$read_only]($read_only_style)[$path]($style)\\]";
            read_only = "";
          };

          os = {
            format = "\\[[$symbol]($style)\\]";
          };
          sudo = {
            format = "\\[[as $symbol]($style)\\]";
          };
          time = {
            format = "\\[[$time]($style)\\]";
          };
          cmd_duration = {
            format = "\\[[$duration]($style)\\]";
            min_time = 10000;
          };

          package = {
            format = "\\[[$symbol$version]($style)\\]";
            symbol = "";
          };
          git_branch = {
            format = "\\[[$symbol$branch]($style)\\]";
          };
          git_status = {
            format = "\\[[$all_status$ahead_behind]($style)\\]";
          };

          aws = {
            format = "\\[[$symbol($profile)(\\($region\\))(\\[$duration\\])]($style)\\]";
            symbol = "󰸏";
          };
          bun = {
            format = "\\[[$symbol($version)]($style)\\]";
            symbol = "󰚅";
          };
          c = {
            format = "\\[[$symbol($version(-$name))]($style)\\]";
            symbol = "";
          };
          deno = {
            format = "\\[[$symbol($version)]($style)\\]";
            symbol = "";
          };
          docker_context = {
            format = "\\[[$symbol$context]($style)\\]";
            symbol = "󰡨";
          };
          elixir = {
            format = "\\[[$symbol($version \(OTP $otp_version\))]($style)\\]";
            symbol = "";
          };
          gcloud = {
            format = "\\[[$symbol$account(\\($region\\))]($style)\\]";
            symbol = "󱇶";
          };
          gleam = {
            format = "\\[[$symbol($version)]($style)\\]";
            symbol = "󰦥";
          };
          golang = {
            format = "\\[[$symbol($version)]($style)\\]";
            symbol = "󰟓";
          };
          gradle = {
            format = "\\[[$symbol($version)]($style)\\]";
            symbol = "";
          };
          guix_shell = {
            format = "\\[[$symbol]($style)\\]";
          };
          haskell = {
            format = "\\[[$symbol($version)]($style)\\]";
            symbol = "";
          };
          java = {
            format = "\\[[$symbol($version)]($style)\\]";
            symbol = "";
          };
          julia = {
            format = "\\[[$symbol($version)]($style)\\]";
            symbol = "";
          };
          kubernetes = {
            format = "\\[[$symbol$context( \\($namespace\\))]($style)\\]";
            symbol = "󱃾";
          };
          lua = {
            format = "\\[[$symbol($version)]($style)\\]";
            symbol = "";
          };
          nix_shell = {
            format = "\\[[$symbol$state( \\($name\\))]($style)\\]";
            symbol = "󱄅";
          };
          nodejs = {
            format = "\\[[$symbol($version)]($style)\\]";
            detect_files = [
              "package.json"
              ".node-version"
              "!bunfig.toml"
              "!bun.lockb"
            ];
          };
          ocaml = {
            format = "\\[[$symbol($version)(\\($switch_indicator$switch_name\\))]($style)\\]";
            symbol = "";
          };
          pulumi = {
            format = "\\[[$symbol$stack]($style)\\]";
          };
          python = {
            format = "\\[[$symbol$pyenv_prefix($version)(\\($virtualenv\\))]($style)\\]";
            symbol = "";
          };
          rlang = {
            format = "\\[[$symbol($version)]($style)\\]";
            symbol = "";
          };
          rust = {
            format = "\\[[$symbol($version)]($style)\\]";
            symbol = "";
          };
          scala = {
            format = "\\[[$symbol($version)]($style)\\]";
            symbol = "";
          };
          terraform = {
            format = "\\[[$symbol($version)]($style)\\]";
            symbol = "󱁢";
          };
          typst = {
            format = "\\[[$symbol($version)]($style)\\]";
            symbol = "󰬁";
          };
          zig = {
            format = "\\[[$symbol($version)]($style)\\]";
            symbol = "";
          };

          custom.claude =
            let
              fetch = pkgs.writeShellScript "claude-usage-fetch" ''
                set -euo pipefail
                cache="''${XDG_CACHE_HOME:-$HOME/.cache}/claude-usage"
                creds="''${CLAUDE_CONFIG_DIR:-$HOME/.claude}/.credentials.json"
                token=$(${pkgs.jq}/bin/jq -r '.claudeAiOauth.accessToken' "$creds") || exit 0
                [ -n "$token" ] && [ "$token" != null ] || exit 0
                resp=$(${pkgs.curl}/bin/curl -sf --max-time 5 https://api.anthropic.com/api/oauth/usage \
                  -H "Authorization: Bearer $token" \
                  -H "anthropic-beta: oauth-2025-04-20" \
                  -H "User-Agent: claude-code/2.1.162") || exit 0
                printf '%s' "$resp" \
                  | ${pkgs.jq}/bin/jq -r '"5h \(.five_hour.utilization|floor)% 7d \(.seven_day.utilization|floor)%"' > "$cache.tmp" \
                  && ${pkgs.coreutils}/bin/mv "$cache.tmp" "$cache"
              '';
              usage = pkgs.writeShellScript "claude-usage" ''
                set -euo pipefail
                cache="''${XDG_CACHE_HOME:-$HOME/.cache}/claude-usage"
                creds="''${CLAUDE_CONFIG_DIR:-$HOME/.claude}/.credentials.json"
                [ -f "$creds" ] || exit 0

                if [ ! -f "$cache" ] || [ "$(( $(${pkgs.coreutils}/bin/date +%s) - $(${pkgs.coreutils}/bin/stat -c %Y "$cache") ))" -gt 300 ]; then
                  ${pkgs.coreutils}/bin/touch "$cache"
                  ${pkgs.util-linux}/bin/setsid -f ${fetch} >/dev/null 2>&1 || true
                fi

                [ -s "$cache" ] && ${pkgs.coreutils}/bin/cat "$cache" || true
              '';
            in
            {
              description = "Claude Code 5h / 7d usage from /usage";
              when = ''[ -f "''${CLAUDE_CONFIG_DIR:-$HOME/.claude}/.credentials.json" ]'';
              command = "${usage}";
              style = "bold #d97757";
              format = "(\\[[󰚩 $output]($style)\\])";
              shell = [
                "bash"
                "--noprofile"
                "--norc"
              ];
            };

        };
      };

      programs.bash.initExtra = ''
        [[ $- == *i* && $TERM != dumb ]] && source ${bakeInit "starship" "${config.programs.starship.package}/bin/starship init bash --print-full-init"}
      '';
    };
}

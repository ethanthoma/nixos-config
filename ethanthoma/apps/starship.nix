{ ... }:

{
  programs.starship = {
    enable = true;

    settings = {
      format = "$username$hostname$all";

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
        read_only = " ";
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
        format = "\\[[ $duration]($style)\\]";
        min_time = 10000;
      };

      package = {
        format = "\\[[$symbol$version]($style)\\]";
        symbol = " ";
      };
      git_branch = {
        format = "\\[[$symbol$branch]($style)\\]";
      };
      git_status = {
        format = "\\[[$all_status$ahead_behind]($style)\\]";
      };

      aws = {
        format = "\\[[$symbol($profile)(\\($region\\))(\\[$duration\\])]($style)\\]";
        symbol = "󰸏 ";
      };
      c = {
        format = "\\[[$symbol($version(-$name))]($style)\\]";
        symbol = " ";
      };
      docker_context = {
        format = "\\[[$symbol$context]($style)\\]";
        symbol = "󰡨 ";
      };
      gcloud = {
        format = "\\[[$symbol$account(\\($region\\))]($style)\\]";
        symbol = "󱇶 ";
      };
      golang = {
        format = "\\[[$symbol($version)]($style)\\]";
        symbol = "󰟓 ";
      };
      guix_shell = {
        format = "\\[[$symbol]($style)\\]";
      };
      haskell = {
        format = "\\[[$symbol($version)]($style)\\]";
        symbol = " ";
      };
      julia = {
        format = "\\[[$symbol($version)]($style)\\]";
        symbol = " ";
      };
      kubernetes = {
        format = "\\[[$symbol$context( \\($namespace\\))]($style)\\]";
        symbol = "󱃾 ";
      };
      lua = {
        format = "\\[[$symbol($version)]($style)\\]";
        symbol = " ";
      };
      nix_shell = {
        format = "\\[[$symbol$state( \\($name\\))]($style)\\]";
        symbol = "󱄅 ";
      };
      ocaml = {
        format = "\\[[$symbol($version)(\\($switch_indicator$switch_name\\))]($style)\\]";
        symbol = " ";
      };
      pulumi = {
        format = "\\[[$symbol$stack]($style)\\]";
      };
      python = {
        format = "\\[[$symbol$pyenv_prefix($version)(\\($virtualenv\\))]($style)\\]";
        symbol = " ";
      };
      rlang = {
        format = "\\[[$symbol($version)]($style)\\]";
        symbol = " ";
      };
      rust = {
        format = "\\[[$symbol($version)]($style)\\]";
        symbol = " ";
      };
      scala = {
        format = "\\[[$symbol($version)]($style)\\]";
        symbol = " ";
      };
      zig = {
        format = "\\[[$symbol($version)]($style)\\]";
        symbol = " ";
      };

    };
  };

  programs.bash = {
    bashrcExtra = ''
      eval "$(starship init bash)"
    '';
  };
}

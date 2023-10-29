{ home, ... }:

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

            time = { 
                format = "\\[[$time]($style)\\]"; 
            };
            os = { format = "\\[[$symbol]($style)\\]"; };
            sudo = { format = "\\[[as $symbol]($style)\\]"; };

            pulumi = { format = "\\[[$symbol$stack]($style)\\]"; };
            aws = { 
                format = "\\[[$symbol($profile)(\\($region\\))(\\[$duration\\])]($style)\\]"; 
            };
            c = { format = "\\[[$symbol($version(-$name))]($style)\\]"; };
            cmd_duration = { 
                format = "\\[[⏱ $duration]($style)\\]"; 
                min_time = 10000;
            };
            deno = { format = "\\[[$symbol($version)]($style)\\]"; };
            docker_context = { format = "\\[[$symbol$context]($style)\\]"; };
            gcloud = { 
                format = "\\[[$symbol$account(\\($region\\))]($style)\\]"; 
            };
            git_branch = { format = "\\[[$symbol$branch]($style)\\]"; };
            git_status = { format = "([\\[$all_status$ahead_behind\\]]($style))"; };
            golang = { format = "\\[[$symbol($version)]($style)\\]"; };
            guix_shell = { format = "\\[[$symbol]($style)\\]"; };
            julia = { format = "\\[[$symbol($version)]($style)\\]"; };
            kubernetes = { format = "\\[[$symbol$context( \\($namespace\\))]($style)\\]"; };
            lua = { format = "\\[[$symbol($version)]($style)\\]"; };
            nix_shell = { format = "\\[[$symbol$state( \\($name\\))]($style)\\]"; };
            ocaml = { format = "\\[[$symbol($version)(\\($switch_indicator$switch_name\\))]($style)\\]"; };
            package = { format = "\\[[$symbol$version]($style)\\]"; };
            python = { format = "\\[[$symbol$pyenv_prefix($version)(\\($virtualenv\\))]($style)\\]"; };
            rust = { format = "\\[[$symbol($version)]($style)\\]"; };
            scala = { format = "\\[[$symbol($version)]($style)\\]"; };
            zig = { format = "\\[[$symbol($version)]($style)\\]"; };
        };
    };
}

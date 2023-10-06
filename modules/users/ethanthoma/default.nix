{ config, pkgs, username, ... }:

{
    home = let
        username = "ethanthoma";
    in {
        inherit username;

        homeDirectory = "/home/${username}";
        stateVersion = "23.05";

        packages = with pkgs; [
            # CLI tools
            gh
            tree
            wget
            zip
            fzf

            # browser
            firefox-wayland

            # comm
            discord
        ];

        file.".config/nvim".source = pkgs.fetchFromGitHub {
            owner = "ethanthoma";
            repo = "neovim";
            rev = "94d1a383f839a856b320208665f40071c1b60495";
            sha256 = "14slvw8c8qpm18dzfp94naagm59ax9ikm8i0l8myfic9d97c8k9y";
        };

        file.".config/tmux".source = pkgs.fetchFromGitHub {
            owner = "ethanthoma";
            repo = "tmux-config";
            rev = "7fc153cabd55f01179423311a17b05232ac05d3c";
            sha256 = "0q7mk577pph4wvybv2341a2nad5f1l7gk0vp87s6r28l0kf2cgk0";
            fetchSubmodules = true;
        };
    };

    programs.home-manager.enable = true;
}


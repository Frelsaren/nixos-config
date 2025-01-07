{
  secrets,
  pkgs,
  username,
  nix-index-database,
  ...
}: let
  unstable-packages = with pkgs.unstable; [
    bat
    bottom
    coreutils
    curl
    du-dust
    fd
    findutils
    fx
    git
    git-crypt
    htop
    jq
    killall
    mosh
    procs
    ripgrep
    sd
    tree
    unzip
    # vim
    wget
    zip
  ];

  stable-packages = with pkgs; [
    gh # for bootstrapping
    just
    qmk
    tmux
    # core languages
    rustup
    nodejs
    python3
    typescript

    go
    nodePackages.typescript-language-server
    nodePackages.vscode-langservers-extracted # html, css, json, eslint
    nodePackages.ts-node
    gopls
    # rust stuff
    cargo-cache
    cargo-expand

    # local dev stuf
    mkcert
    httpie
    devenv
    # treesitter
    tree-sitter

    # language servers
    nodePackages.vscode-langservers-extracted # html, css, json, eslint
    nodePackages.yaml-language-server
    nil # nix
    # formatters and linters
    alejandra # nix
    deadnix # nix
    nodePackages.prettier
    shellcheck
    shfmt
    statix # nix
  ];
in {
  imports = [
    nix-index-database.hmModules.nix-index
  ];

  home.stateVersion = "22.11";

  home = {
    username = "${username}";
    homeDirectory = "/home/${username}";

    sessionVariables.EDITOR = "nvim";
    # FIXME: set your preferred $SHELL
    sessionVariables.SHELL = "/etc/profiles/per-user/${username}/bin/fish";
  };

  home.packages =
    stable-packages
    ++ unstable-packages
    ++
    # FIXME: you can add anything else that doesn't fit into the above two lists in here
    [
      (pkgs.jeezyvim.extend {
        plugins = {
          lsp.servers = {
            gopls.enable = true;
            ts_ls.enable = true;
          };
        };

        colorschemes.kanagawa.enable = false;
        colorschemes.catppuccin.enable = true;
        colorschemes.catppuccin.settings.flavour = "mocha";
      })
      # pkgs.some-package
      # pkgs.unstable.some-other-package
    ];

  programs = {
    home-manager.enable = true;
    nix-index.enable = true;
    nix-index.enableFishIntegration = true;
    nix-index-database.comma.enable = true;

    # FIXME: disable this if you don't want to use the starship prompt
    starship.enable = true;
    starship.settings = {
      aws.disabled = true;
      gcloud.disabled = true;
      kubernetes.disabled = false;
      git_branch.style = "242";
      directory.style = "blue";
      directory.truncate_to_repo = false;
      directory.truncation_length = 8;
      python.disabled = true;
      ruby.disabled = true;
      hostname.ssh_only = false;
      hostname.style = "bold green";
    };

    tmux = {
      enable = true;
      shell = "${pkgs.fish}/bin/fish";
      terminal = "screen-256color";
      plugins = with pkgs.tmuxPlugins; [
        {
          plugin = catppuccin;
          extraConfig = ''
            set -g @catppuccin_flavour 'mocha'
            set -g @catppuccin_windoww_tabs_enabled on
            set -g @catppuccin_date_time "%H:%M"
          '';
        }
        cpu
        better-mouse-mode
      ];
      extraConfig = ''
        set-option -a terminal-features "xterm-256color:RGB"
        set-option -a terminal-overrides "xterm-256color:Tc"
        bind s split-window -v -c "#{pane_current_path}"
        bind v split-window -h -c "#{pane_current_path}"

        bind -n C-h select-pane -L
        bind -n C-j select-pane -D
        bind -n C-k select-pane -U
        bind -n C-l select-pane -R
      '';
    };

    # FIXME: disable whatever you don't want
    fzf.enable = true;
    fzf.enableFishIntegration = true;
    lsd.enable = true;
    lsd.enableAliases = true;
    zoxide.enable = true;
    zoxide.enableFishIntegration = true;
    zoxide.options = ["--cmd cd"];
    broot.enable = true;
    broot.enableFishIntegration = true;
    direnv.enable = true;
    direnv.nix-direnv.enable = true;

    git = {
      enable = true;
      package = pkgs.unstable.git;
      delta.enable = true;
      delta.options = {
        line-numbers = true;
        side-by-side = true;
        navigate = true;
      };
      aliases = {
        ignore = "update-index --skip-worktree";
        uningore = "update-index --no-skip-worktree";
        ignored = ''!git ls-files -v | grep "^$"'';
      };
      userEmail = "markus.roiland00@gmail.com"; # FIXME: set your git email
      userName = "Frelsaren"; #FIXME: set your git username
      extraConfig = {
        # FIXME: uncomment the next lines if you want to be able to clone private https repos
        url = {
          "https://oauth2:${secrets.github_token}@github.com" = {
            insteadOf = "https://github.com";
          };
        };

        push = {
          default = "current";
          autoSetupRemote = true;
        };
        merge = {
          conflictstyle = "diff3";
        };
        diff = {
          colorMoved = "default";
        };
      };
    };

    # FIXME: This is my fish config - you can fiddle with it if you want
    fish = {
      enable = true;
      # FIXME: run 'scoop install win32yank' on Windows, then add this line with your Windows username to the bottom of interactiveShellInit
      # fish_add_path --append /mnt/c/Users/<Your Windows Username>/scoop/apps/win32yank/0.1.1
      interactiveShellInit = ''
        ${pkgs.lib.strings.fileContents (pkgs.fetchFromGitHub {
            owner = "rebelot";
            repo = "kanagawa.nvim";
            rev = "de7fb5f5de25ab45ec6039e33c80aeecc891dd92";
            sha256 = "sha256-f/CUR0vhMJ1sZgztmVTPvmsAgp0kjFov843Mabdzvqo=";
          }
          + "/extras/kanagawa.fish")}
        set -U fish_greeting
        fish_add_path --append /mnt/c/Users/markus/scoop/apps/win32yank/0.1.1
      '';
      functions = {
        refresh = "source $HOME/.config/fish/config.fish";
        take = ''mkdir -p -- "$argv" && cd "./$argv"'';

        ttake = "cd $(mktemp -d)";
        show_path = "echo $PATH | tr ' ' '\n'";
        posix-source = ''
          for i in (cat $argv)
            set arr (echo $i |tr = \n)
            set -gx $arr[1] $arr[2]
          end
        '';
      };
      shellAbbrs =
        {
          gc = "nix-collect-garbage --delete-old";
        }
        # navigation shortcuts
        // {
          ".." = "cd ..";
          "..." = "cd ../../";
          "...." = "cd ../../../";
          "....." = "cd ../../../../";
        }
        # git shortcuts
        // {
          gapa = "git add --patch";
          grpa = "git reset --patch";
          gst = "git status";
          gdh = "git diff HEAD";
          gp = "git push";
          gph = "git push -u origin HEAD";
          gco = "git checkout";
          gcob = "git checkout -b";
          gcm = "git checkout master";
          gcd = "git checkout develop";
          gsp = "git stash push -m";
          gsa = "git stash apply stash^{/";
          gsl = "git stash list";
        };
      shellAliases = {
        jvim = "nvim";
        lvim = "nvim";
        pbcopy = "/mnt/c/Windows/System32/clip.exe";
        pbpaste = "/mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe -command 'Get-Clipboard'";
        explorer = "/mnt/c/Windows/explorer.exe";
        code = "/mnt/c/Appl/vscode/bin/code";
        # cd = "__zoxide_z";
      };
      plugins = [
        {
          inherit (pkgs.fishPlugins.autopair) src;
          name = "autopair";
        }
        {
          inherit (pkgs.fishPlugins.done) src;
          name = "done";
        }
        {
          inherit (pkgs.fishPlugins.sponge) src;
          name = "sponge";
        }
      ];
    };
  };
}

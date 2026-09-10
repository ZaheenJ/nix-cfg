# Distro-agnostic shell, editor, development, and productivity environment.
{ pkgs, ... }:
{
  imports = [
    ../common/fish.nix
    ../common/nushell.nix
    ../common/starship.nix
    ../common/helix.nix
    ../common/git.nix
    ../common/cli.nix
    ../common/yazi.nix
  ];

  home.sessionPath = [
    "$HOME/.local/bin"
    "$HOME/.cargo/bin"
    "$HOME/.local/share/cargo/bin"
  ];

  programs.home-manager.enable = true;

  programs.taskwarrior = {
    enable = true;
    package = pkgs.taskwarrior3;
  };

  # Defining in Nix allows to merge with abbreivations defined elsewhere (ytda)
  local.nushell.abbreviations = {
    se = "sudo -E";
    g = "git";
    ga = "git add";
    gaa = "git add --all";
    gau = "git add --update";
    gb = "git branch";
    gba = "git branch --all";
    gbd = "git branch --delete";
    gc = "git commit --verbose";
    gca = "git commit --verbose --all";
    gcam = "git commit --verbose --all --message";
    gcl = "git clone --recurse-submodules";
    gcp = "git cherry-pick";
    gd = "git diff";
    gf = "git fetch";
    gfo = "git fetch origin";
    gfa = "git fetch --all";
    gfap = "git fetch --all --prune";
    gi = "git init";
    gl = "git log";
    glg = "git log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit";
    gm = "git merge";
    gmauhnf = "git merge --allow-unrelated-histories --no-ff";
    gp = "git push";
    gpsu = "git push --set-upstream";
    gpl = "git pull";
    gr = "git remote --verbose";
    gra = "git remote add";
    grrm = "git remote remove";
    grmv = "git remote rename";
    grb = "git rebase";
    grev = "git revert";
    grs = "git reset";
    grsh = "git reset --hard";
    grm = "git rm";
    grmc = "git rm --cached";
    gs = "git status -s";
    gsw = "git switch";
    gswc = "git switch --create";
  };

  home.packages = with pkgs; [
    fd
    ripgrep
    fzf
    zip
    unzip
    dust
    duf
    ncdu
    bottom
    tokei
    libqalculate
    taskwarrior-tui
    man-pages
    android-tools
  ];
}

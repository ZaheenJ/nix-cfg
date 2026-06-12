set -g fish_key_bindings fish_helix_key_bindings
set -gx EDITOR hx

alias e $EDITOR
abbr se "sudo -E"

# git abbreviations (ported from config.fish)
abbr g git
abbr ga 'git add'
abbr gaa 'git add --all'
abbr gapa 'git add --patch'
abbr gau 'git add --update'
abbr gav 'git add --verbose'
abbr gb 'git branch'
abbr gba 'git branch -a'
abbr gbd 'git branch -d'
abbr gbD 'git branch -D'
abbr gbnm 'git branch --no-merged'
abbr gbr 'git branch --remote'
abbr gbl 'git blame -b -w'
abbr gbs 'git bisect'
abbr gbsb 'git bisect bad'
abbr gbsg 'git bisect good'
abbr gbsr 'git bisect reset'
abbr gbss 'git bisect start'
abbr gc 'git commit -v'
abbr gci "git commit --allow-empty -v -m'chore: initial commit'"
abbr gcn 'git commit -v --no-edit'
abbr gca 'git commit -a -v'
abbr gcam 'git commit -a -m'
abbr gcas 'git commit -a -s'
abbr gcsm 'git commit -s -m'
abbr gcm 'git commit -m'
abbr gcs 'git commit -S'
abbr gcf 'git config --list'
abbr gcl 'git clone --recurse-submodules'
abbr gclean 'git clean -id'
abbr gco 'git checkout'
abbr gcob 'git checkout -b'
abbr gcount 'git shortlog -sn'
abbr gcp 'git cherry-pick'
abbr gcpa 'git cherry-pick --abort'
abbr gcpc 'git cherry-pick --continue'
abbr gd 'git diff'
abbr gdca 'git diff --cached'
abbr gdcw 'git diff --cached --word-diff'
abbr gdt 'git diff-tree --no-commit-id --name-only -r'
abbr gdup 'git diff @{upstream}'
abbr gf 'git fetch'
abbr gfa 'git fetch --all --prune'
abbr gfo 'git fetch origin'
abbr ghh 'git help'
abbr gi 'git init'
abbr gignore 'git update-index --assume-unchanged'
abbr gignored 'git ls-files -v | grep "^[[:lower:]]"'
abbr gfg 'git ls-files | grep'
abbr gl 'git log'
abbr gls 'git log --stat'
abbr glsp 'git log --stat -p'
abbr glg 'git log --graph'
abbr glgda 'git log --graph --decorate --all'
abbr glgm 'git log --graph --max-count=10'
abbr glo 'git log --oneline --decorate'
abbr glog 'git log --oneline --decorate --graph'
abbr gloga 'git log --oneline --decorate --graph --all'
abbr gm 'git merge'
abbr gmom 'git merge origin/(git_main_branch)'
abbr gmum 'git merge upstream/(git_main_branch)'
abbr gma 'git merge --abort'
abbr gmtl 'git mergetool --no-prompt'
abbr gmtlvim 'git mergetool --no-prompt --tool=vimdiff'
abbr gp 'git push'
abbr gpd 'git push --dry-run'
abbr gpf 'git push --force-with-lease'
abbr gpsu 'git push --set-upstream origin (git_current_branch)'
abbr gpt 'git push --tags'
abbr gpv 'git push -v'
abbr gpl 'git pull'
abbr gplo 'git pull origin'
abbr gplu 'git pull upstream'
abbr gr 'git remote -v'
abbr gra 'git remote add'
abbr grau 'git remote add upstream'
abbr grrm 'git remote remove'
abbr grmv 'git remote rename'
abbr grset 'git remote set-url'
abbr gru 'git remote update'
abbr grv 'git remote -v'
abbr grb 'git rebase'
abbr grba 'git rebase --abort'
abbr grbc 'git rebase --continue'
abbr grbi 'git rebase -i'
abbr grbom 'git rebase origin/(git_main_branch)'
abbr grbo 'git rebase --onto'
abbr grbs 'git rebase --skip'
abbr grev 'git revert'
abbr grs 'git reset'
abbr grsh 'git reset HEAD'
abbr gpristine 'git reset --hard && git clean -dffx'
abbr grm 'git rm'
abbr grmc 'git rm --cached'
abbr grst 'git restore'
abbr grsts 'git restore --source'
abbr grstst 'git restore --staged'
abbr grt 'cd (git rev-parse --show-toplevel || echo .)'
abbr gs 'git status'
abbr gss 'git status -s'
abbr gsb 'git status -sb'
abbr gshow 'git show'
abbr gshowps 'git show --pretty=short --show-signature'
abbr gst 'git stash'
abbr gsta 'git stash apply'
abbr gstc 'git stash clear'
abbr gstd 'git stash drop'
abbr gstl 'git stash list'
abbr gstp 'git stash pop'
abbr gstshow 'git stash show --text'
abbr gstall 'git stash --all'
abbr gsts 'git stash save'
abbr gsu 'git submodule update'
abbr gsw 'git switch'
abbr gswc 'git switch -c'
abbr gswm 'git switch (git_main_branch)'
abbr gswd 'git switch (git_develop_branch)'
abbr gt 'git tag'
abbr gts 'git tag -s'
abbr gta 'git tag -a'
abbr gtas 'git tag -a -s'
abbr gwch 'git whatchanged -p --abbrev-commit --pretty=medium'
abbr gwt 'git worktree'
abbr gwta 'git worktree add'
abbr gwtls 'git worktree list'
abbr gwtmv 'git worktree move'
abbr gwtrm 'git worktree remove'
abbr gam 'git am'
abbr gamc 'git am --continue'
abbr gams 'git am --skip'
abbr gama 'git am --abort'
abbr gamscp 'git am --show-current-patch'

abbr ytda 'yt-dlp --embed-metadata --xattrs -x -f bestaudio --sponsorblock-remove music_offtopic,intro,outro'

# Syntax colours (from fish_frozen_theme.fish)
set -g fish_color_autosuggestion brblack
set -g fish_color_cancel -r
set -g fish_color_command normal
set -g fish_color_comment red
set -g fish_color_cwd green
set -g fish_color_cwd_root red
set -g fish_color_end green
set -g fish_color_error brred
set -g fish_color_escape brcyan
set -g fish_color_history_current --bold
set -g fish_color_host normal
set -g fish_color_host_remote yellow
set -g fish_color_normal normal
set -g fish_color_operator brcyan
set -g fish_color_param cyan
set -g fish_color_quote yellow
set -g fish_color_redirection "cyan --bold"
set -g fish_color_search_match "white --background=brblack"
set -g fish_color_selection "white --bold --background=brblack"
set -g fish_color_status red
set -g fish_color_user brgreen
set -g fish_color_valid_path --underline
set -g fish_pager_color_completion normal
set -g fish_pager_color_description "yellow -i"
set -g fish_pager_color_prefix "normal --bold --underline"
set -g fish_pager_color_progress "brwhite --background=cyan"
set -g fish_pager_color_selected_background -r

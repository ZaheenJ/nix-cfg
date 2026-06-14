$env.config.buffer_editor = "hx"
$env.EDITOR = "hx"

$env.config.edit_mode = "vi"
$env.config.cursor_shape = {emacs: line, vi_insert: line, vi_normal: block}
$env.config.show_banner = false

# Custom commands
def fgpl [] {
    ls
    | where type == dir
    | where { |d| ($d.name | path join ".git" | path exists) }
    | each { |d|
        print $"Pulling ($d.name)..."
        cd $d.name
        ^git pull
    }
}

def power-draw [] {
    let current = (open /sys/class/power_supply/BAT1/current_now | into float)
    let voltage = (open /sys/class/power_supply/BAT1/voltage_now | into float)
    let power = ($current * $voltage * 0.000000000001)
    echo $"($power) W"
}

# Abbreviation-style expansion via a custom menu (on space / enter)
let abbreviations = {
    se: 'sudo -E'
    ytda: 'yt-dlp --embed-metadata --xattrs -x -f bestaudio --sponsorblock-remove music_offtopic,intro,outro'
    g: 'git'
    ga: 'git add'
    gaa: 'git add --all'
    gau: 'git add --update'
    gb: 'git branch'
    gba: 'git branch --all'
    gbd: 'git branch --delete'
    gc: 'git commit --verbose'
    gca: 'git commit --verbose --all'
    gcam: 'git commit --verbose --all --message'
    gcl: 'git clone --recurse-submodules'
    gcp: 'git cherry-pick'
    gd: 'git diff'
    gf: 'git fetch'
    gfo: 'git fetch origin'
    gfa: 'git fetch --all'
    gfap: 'git fetch --all --prune'
    gi: 'git init'
    gl: 'git log'
    glg: "git log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit"
    gm: 'git merge'
    gmauhnf: 'git merge --allow-unrelated-histories --no-ff'
    gp: 'git push'
    gpsu: 'git push --set-upstream'
    gpl: 'git pull'
    gr: 'git remote --verbose'
    gra: 'git remote add'
    grrm: 'git remote remove'
    grmv: 'git remote rename'
    grb: 'git rebase'
    grev: 'git revert'
    grs: 'git reset'
    grsh: 'git reset --hard'
    grm: 'git rm'
    grmc: 'git rm --cached'
    gs: 'git status -s'
    gsw: 'git switch'
    gswc: 'git switch --create'
}

$env.config.keybindings ++= [
    {
      name: abbr_menu
      modifier: none
      keycode: enter
      mode: [emacs, vi_normal, vi_insert]
      event: [
          { send: menu name: abbr_menu }
          { send: enter }
      ]
    }
    {
      name: accept_abbr
      modifier: control
      keycode: char_y
      mode: [emacs, vi_normal, vi_insert]
      event: [
        { send: HistoryHintComplete }]
    }
    {
      name: abbr_menu
      modifier: none
      keycode: space
      mode: [emacs, vi_normal, vi_insert]
      event: [
          { send: menu name: abbr_menu }
          { edit: insertchar value: ' '}
      ]
    }
]

$env.config.menus ++= [
{
  name: abbr_menu
  only_buffer_difference: false
  marker: none
  type: {
    layout: columnar
    columns: 1
    col_width: 20
    col_padding: 2
  }
  style: {
    text: green
    selected_text: green_reverse
    description_text: yellow
  }
  source: { |buffer, position|
    let before_cursor = ($buffer | str substring 0..$position)
    let current_word = ($before_cursor | split row ' ' | last)
    let match = $abbreviations | columns | where $it == $current_word
    if ($match | is-empty) {
      { value: $buffer }
    } else {
      let replacement = ($abbreviations | get $match.0)
      let word_len = ($current_word | str length | into int)
      let before_word_end = ($position - $word_len)
      let before_word = if $before_word_end > 0 {
        ($buffer | str substring 0..<$before_word_end)
      } else {
        ""
      }
      let after_cursor = ($buffer | str substring $position..)
      { value: ($before_word ++ $replacement ++ $after_cursor) }
    }
  }
}
]

# Hide vi mode indicator (starship handles prompt)
$env.PROMPT_INDICATOR_VI_NORMAL = ""
$env.PROMPT_INDICATOR_VI_INSERT = ""

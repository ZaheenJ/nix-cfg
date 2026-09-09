$env.config.buffer_editor = "hx"
$env.EDITOR = "hx"

$env.config.edit_mode = "helix"
$env.config.cursor_shape = {emacs: line, helix_insert: line, helix_normal: block}
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

# Abbreviation-style expansion via a custom menu (on space / enter)
$env.config.keybindings ++= [
    {
      name: abbr_menu_enter
      modifier: none
      keycode: enter
      mode: [emacs, helix_normal, helix_insert]
      event: [
          { send: menu name: abbr_menu }
          { send: enter }
      ]
    }
    {
      name: accept_abbr
      modifier: control
      keycode: char_y
      mode: [emacs, helix_normal, helix_insert]
      event: [
        { send: HistoryHintComplete }]
    }
    {
      name: abbr_menu_space
      modifier: none
      keycode: space
      mode: [emacs, helix_normal, helix_insert]
      event: [
          { send: menu name: abbr_menu }
          { edit: insertchar value: ' '}
      ]
    }
    {
      name: helix_l_hint_normal
      modifier: none
      keycode: char_l
      mode: [helix_normal]
      event: {
        until: [
          { send: HistoryHintComplete }
          { send: MenuRight }
          { edit: MoveRight }
        ]
      }
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

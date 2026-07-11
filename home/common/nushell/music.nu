# Music library management: metadata, cover art, synced lyrics.
# Requires on PATH: songrec, yt-dlp, opustags, opusinfo (opus-tools) — the
# latter two come from home/personal/media.nix, so these commands only work
# on machines that include it.
# Conventions: filename = title; multi-value ARTIST (main first, feat in title);
# classical titles "Composer: Work"; romanized or Hangeul metadata.

const MUSIC_DIR = "~/Music"
const MUSIC_JUNK_TAGS = [description synopsis purl language comment encoder]
const MUSIC_UA = "zaheenj-music-scripts/1.0"

# ---------- helpers ----------

def sanitize-filename [name: string] {
    $name | str replace -a "/" "⧸" | str replace -a ":" "：" | str trim
}

def read-tags [file: string] {
    ^opustags $file | lines | where ($it | str contains "=")
    | parse "{key}={value}" | update key { str downcase }
}

def tag-val [tags, key: string] {
    let rows = ($tags | where key == $key)
    if ($rows | is-empty) { "" } else { $rows | first | get value }
}

def opus-duration [file: string] {
    let line = (^opusinfo $file | lines | where ($it =~ "Playback length") | first)
    let m = ($line | parse -r '(?<m>\d+)m:(?<s>\d+(?:\.\d+)?)s' | first)
    ($m.m | into int) * 60 + ($m.s | into float)
}

# prompt with a proposed value; enter accepts, typing replaces
def confirm-field [label: string, proposal: string] {
    let answer = (input $"  ($label) [($proposal)]: ")
    if ($answer | str trim | is-empty) { $proposal } else { $answer | str trim }
}

def yes-or [prompt: string] {
    let ans = (input $prompt | str trim)
    ($ans | is-empty) or (($ans | str downcase) starts-with "y")
}

def rescale-lrc [lrc: string, ratio: float] {
    $lrc | lines | each {|line|
        mut l = $line
        mut out = ""
        while ($l =~ '^\[\d+:\d+(\.\d+)?\]') {
            let m = ($l | parse -r '^\[(?<mm>\d+):(?<ss>\d+(?:\.\d+)?)\](?<rest>.*)$' | first)
            let total = ((($m.mm | into int) * 60 + ($m.ss | into float)) * $ratio)
            let nm = ($total / 60 | math floor | into int)
            let ns = ($total mod 60 | math round --precision 2)
            let pad = if $ns < 10 { "0" } else { "" }
            $out = $out + $"[($nm | fill --alignment right --character '0' --width 2):($pad)($ns)]"
            $l = $m.rest
        }
        $out + $l
    } | str join "\n"
}

# ---------- cover art ----------

# Find and embed cover art (Deezer search with confirmation, or your own URL).
def music-cover [file: string] {
    let tags = (read-tags ($file | path expand))
    let artist = (tag-val $tags artist)
    let title = (tag-val $tags title)
    let album = (tag-val $tags album)
    let q = if ($album | is-empty) {
        $'artist:"($artist)" track:"($title)"'
    } else {
        $'artist:"($artist)" album:"($album)"'
    }
    let qs = ({q: $q} | url build-query)
    let res = (try {
        http get --headers [User-Agent $MUSIC_UA] $"https://api.deezer.com/search?($qs)"
    } catch { {data: []} })
    let hits = ($res | get -o data | default [])
    mut url = ""
    if ($hits | is-not-empty) {
        let h = ($hits | first)
        print $"  cover match: ($h.title) — ($h.artist.name) — album: ($h.album.title)"
        let ans = (input "  embed this cover? [Y]es / [n]o / paste image URL: " | str trim)
        if ($ans | is-empty) or (($ans | str downcase) starts-with "y") {
            $url = ($h.album | get -o cover_big | default ($h.album | get -o cover_xl | default ""))
        } else if ($ans starts-with "http") {
            $url = $ans
        }
    } else {
        let ans = (input "  no cover found on Deezer. Paste image URL or enter to skip: " | str trim)
        if ($ans starts-with "http") { $url = $ans }
    }
    if ($url | is-empty) { print "  cover: skipped"; return }
    let tmp = (mktemp --suffix .jpg)
    http get --headers [User-Agent $MUSIC_UA] $url | save -f $tmp
    ^opustags -i --set-cover $tmp ($file | path expand)
    rm $tmp
    print "  cover: embedded"
}

# ---------- lyrics ----------

# Fetch synced lyrics from LRCLIB into a .lrc next to the file.
# Rescales timestamps when the source recording length differs (speed-shifted rips).
def music-lyrics [file: string] {
    let file = ($file | path expand)
    let tags = (read-tags $file)
    let artist = (tag-val $tags artist)
    let title = (tag-val $tags title)
    let dur = (opus-duration $file)
    let clean_title = ($title | str replace --all --regex '\s*[\(\[][^\)\]]*[\)\]]' '' | str trim)
    let get_qs = ({artist_name: $artist, track_name: $title, duration: ($dur | math round)} | url build-query)
    mut rec = (try { http get --headers [User-Agent $MUSIC_UA] $"https://lrclib.net/api/get?($get_qs)" } catch { null })
    if ($rec == null) or (($rec | get -o syncedLyrics | default "") | is-empty) {
        let s_qs = ({track_name: $clean_title, artist_name: $artist} | url build-query)
        let results = (try { http get --headers [User-Agent $MUSIC_UA] $"https://lrclib.net/api/search?($s_qs)" } catch { [] })
        let candidates = ($results | default []
            | where {|r| (($r | get -o syncedLyrics | default "") | is-not-empty) and (($r | get -o duration | default 0) != 0) }
            | insert diff {|r| ($r.duration - $dur) | math abs }
            | where diff <= 20 | sort-by diff)
        $rec = (if ($candidates | is-empty) { null } else { $candidates | first })
    }
    if ($rec == null) { print "  lyrics: none found on LRCLIB"; return }
    mut lrc = $rec.syncedLyrics
    let srcdur = ($rec | get -o duration | default $dur)
    let ratio = ($dur / $srcdur)
    print $"  lyrics match: ($rec | get -o trackName | default $title) — ($rec | get -o artistName | default $artist) \(($srcdur | math round)s vs file ($dur | math round)s\)"
    if ((($ratio - 1) | math abs) > 0.015) {
        print $"  durations differ — rescaling timestamps x($ratio | math round --precision 4)"
        $lrc = (rescale-lrc $lrc $ratio)
    }
    if (yes-or "  save these lyrics? [Y]es / [n]o: ") {
        let lrc_path = ($file | path parse | update extension "lrc" | path join)
        $lrc + "\n" | save -f $lrc_path
        print $"  lyrics: saved ($lrc_path | path basename)"
    } else { print "  lyrics: skipped" }
}

# ---------- main flow ----------

# Fix up a freshly downloaded file: identify, confirm tags, rename, art, lyrics.
# Usage: metadata-adder <file> [--url <youtube-url>]
def metadata-adder [file: string, --url: string = ""] {
    let file = ($file | path expand)
    if not ($file | path exists) { error make {msg: $"no such file: ($file)"} }
    let old_tags = (read-tags $file)

    # source video context: --url flag, or the purl tag yt-dlp embedded
    let vurl = if ($url | is-not-empty) { $url } else { tag-val $old_tags purl }
    if ($vurl | is-not-empty) {
        print $"source video: ($vurl)"
        let v = (try { ^yt-dlp --dump-json --no-download $vurl | from json } catch { null })
        if ($v != null) {
            print $"  yt title:   ($v.title)"
            print $"  yt channel: ($v | get -o channel | default ($v | get -o uploader | default ''))"
            let desc = ($v | get -o description | default "" | lines | first 4 | str join "\n              ")
            print $"  yt descr:   ($desc)"
        }
    }

    # recognition
    print "recognizing via Shazam..."
    let sz = (try { ^songrec audio-file-to-recognized-song $file | from json } catch { {} })
    let track = ($sz | get -o track | default {})
    let metaflat = ($track | get -o sections | default [] | each {|s| $s | get -o metadata | default [] } | flatten)
    def meta-val [mf, name: string] {
        let rows = ($mf | where title == $name)
        if ($rows | is-empty) { "" } else { $rows | first | get text }
    }
    print $"  shazam: ($track | get -o title | default '(no match)') — ($track | get -o subtitle | default '')"

    # propose fields (falling back to existing tags)
    print "confirm each field (enter = accept, or type a correction):"
    print "  conventions: classical = 'Composer: Work'; feat. goes in the title; romanized or Hangeul"
    let title = (confirm-field "title " (($track | get -o title | default "") | default (tag-val $old_tags title)))
    let artists_raw = (confirm-field "artist(s), ';'-separated, main first" (($track | get -o subtitle | default "") | default (tag-val $old_tags artist)))
    let artists = ($artists_raw | split row ";" | each { str trim } | where ($it | is-not-empty))
    let alb_prop = ((meta-val $metaflat Album) | default (tag-val $old_tags album) | str replace --regex '\s*-\s*Single$' '')
    let album = (confirm-field "album " $alb_prop)
    let date = (confirm-field "date  " ((meta-val $metaflat Released) | default (tag-val $old_tags date)))
    let genre = (confirm-field "genre " (($track | get -o genres | default {} | get -o primary | default "") | default (tag-val $old_tags genre)))

    # duplicate check across the library (fixed glob pattern: titles may
    # contain glob metacharacters like parentheses)
    let newbase = (sanitize-filename $title)
    let dupes = (glob (($MUSIC_DIR | path expand) | path join "*" "*.opus")
        | where {|p| ($p | path basename) == $"($newbase).opus" }
        | where $it != $file)
    if ($dupes | is-not-empty) {
        print $"  WARNING: same title exists elsewhere: ($dupes | str join ', ')"
        print "  convention: if different songs, both filenames get a ' (Artist)' suffix."
    }

    # write tags: junk out, confirmed fields in (multi-value artist)
    mut args = [-i]
    for j in $MUSIC_JUNK_TAGS { $args = ($args ++ [-d $j]) }
    for c in ($old_tags | where key =~ '^chapter' | get key | uniq) { $args = ($args ++ [-d $c]) }
    for f in [title artist album date genre albumartist] { $args = ($args ++ [-d $f]) }
    $args = ($args ++ [-a $"TITLE=($title)"])
    for a in $artists { $args = ($args ++ [-a $"ARTIST=($a)"]) }
    if ($album | is-not-empty) { $args = ($args ++ [-a $"ALBUM=($album)"]) }
    if ($date | is-not-empty) { $args = ($args ++ [-a $"DATE=($date)"]) }
    if ($genre | is-not-empty) { $args = ($args ++ [-a $"GENRE=($genre)"]) }
    ^opustags ...$args $file
    print "  tags written"

    # rename to Title.opus
    let target = (($file | path dirname) | path join $"($newbase).opus")
    let final = if ($target == $file) {
        $file
    } else if ($target | path exists) {
        print $"  NOT renaming: ($target | path basename) already exists in this folder — resolve manually"
        $file
    } else {
        mv $file $target
        print $"  renamed -> ($target | path basename)"
        $target
    }

    music-cover $final
    music-lyrics $final
    print "done."
}

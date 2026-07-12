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

# ---------- MusicBrainz (album/date the way Picard would report them) ----------

# Does any artist credit match the wanted artist name (incl. romanized
# aliases, e.g. "Kenshi Yonezu" for 米津玄師)?
def mb-credit-match [entity, artist: string] {
    let want = ($artist | str downcase)
    $entity | get -o "artist-credit" | default [] | any {|c|
        let names = ([
            ($c | get -o name | default "")
            ($c | get -o artist | default {} | get -o name | default "")
        ] ++ ($c | get -o artist | default {} | get -o aliases | default [] | each {|al| $al | get -o name | default "" }))
        $names | any {|n| ($n | str downcase) == $want }
    }
}

# GET a MusicBrainz API URL with one retry (MB throttles with 503s)
def mb-get [url: string] {
    try {
        http get --headers [User-Agent $MUSIC_UA] $url
    } catch {
        sleep 2sec
        try { http get --headers [User-Agent $MUSIC_UA] $url } catch { {} }
    }
}

# Look up the earliest official album release of a recording on MusicBrainz.
# Returns {album, date, caaurl}, or an empty record when nothing was found.
def mb-release [artist: string, title: string] {
    if ($artist | is-empty) or ($title | is-empty) { return {} }
    # MB recording titles don't carry "(feat. X)" suffixes
    let clean = ($title | str replace --all --regex '\s*[\(\[][^\)\]]*[\)\]]' '' | str trim)
    # alias: catches romanized titles (e.g. "Yoru ni Kakeru" for 夜に駆ける);
    # the artist is matched client-side because no search field covers
    # romanized artist aliases
    let q = $"\(recording:\"($clean)\" OR alias:\"($clean)\"\)"
    let qs = ({query: $q, fmt: "json", limit: "100"} | url build-query)
    let res = (mb-get $"https://musicbrainz.org/ws/2/recording/?($qs)")
    # search ranking can't be trusted (live versions, re-records, DJ mixes and
    # covers all score 100): pool the releases of every non-derivative
    # recording credited to this artist, then pick the earliest studio album
    # (compilations/live/soundtracks have secondary types), then any album,
    # then any release. The date is the earliest release of any kind (the
    # single often precedes the album).
    let rels = ($res | get -o recordings | default []
        | where {|r| not (($r | get -o disambiguation | default "") =~ '(?i)live|demo|instrumental|karaoke|remix|mix|edit') }
        | where {|r| mb-credit-match $r $artist }
        | each {|r| $r | get -o releases | default [] } | flatten
        | where {|r| ($r | get -o status | default "Official") == "Official" }
        | insert ptype {|r| $r | get -o "release-group" | default {} | get -o "primary-type" | default "" }
        | insert secondary {|r| $r | get -o "release-group" | default {} | get -o "secondary-types" | default [] | length }
        | insert rdate {|r| $r | get -o date | default "" }
        | where rdate != "")
    let studio = ($rels | where ptype == Album | where secondary == 0 | sort-by rdate)
    let albums = ($rels | where ptype == Album | sort-by rdate)
    let pool = (if ($studio | is-not-empty) { $studio } else if ($albums | is-not-empty) { $albums } else { $rels | sort-by rdate })
    let pooled = (if ($pool | is-empty) { {} } else {
        {
            album: ($pool | first | get -o title | default "")
            date: ($rels | get rdate | sort | first | str substring 0..3)
            caaurl: $"https://coverartarchive.org/release/($pool | first | get -o id | default '')/front-500"
        }
    })
    # cross-check with a release-group search: the recording samples above
    # miss some original albums entirely (e.g. self-titled classics buried
    # under compilation entities). Prefer the release group when it's older.
    sleep 1100ms  # MusicBrainz rate limit: 1 request/second
    let gqs = ({query: $"releasegroup:\"($clean)\" AND primarytype:\"Album\"", fmt: "json", limit: "50"} | url build-query)
    let gres = (mb-get $"https://musicbrainz.org/ws/2/release-group/?($gqs)")
    let rgs = ($gres | get -o "release-groups" | default []
        | where {|g| (($g | get -o title | default "") | str downcase) == ($clean | str downcase) }
        | where {|g| ($g | get -o "secondary-types" | default [] | length) == 0 }
        | where {|g| mb-credit-match $g $artist }
        | insert frd {|g| $g | get -o "first-release-date" | default "" }
        | where frd != "" | sort-by frd)
    if ($rgs | is-not-empty) {
        let rg = ($rgs | first)
        if ($pooled | is-empty) or (($rg.frd | str substring 0..3) < $pooled.date) {
            return {
                album: $rg.title
                date: ($rg.frd | str substring 0..3)
                caaurl: $"https://coverartarchive.org/release-group/($rg.id)/front-500"
            }
        }
    }
    $pooled
}

# ---------- cover art ----------

# Download an image and embed it as the cover, validating it really is an
# image (pasted URLs sometimes serve HTML redirect pages).
def embed-image [file: string, url: string] {
    let data = (try { http get --headers [User-Agent $MUSIC_UA] $url | into binary } catch { null })
    if ($data == null) { print "  cover: download failed"; return false }
    let ext = if ($data | bytes starts-with 0x[FFD8FF]) {
        "jpg"
    } else if ($data | bytes starts-with 0x[89504E47]) {
        "png"
    } else { "" }
    if ($ext | is-empty) {
        print "  cover: URL did not return a JPEG/PNG (got HTML or something else) — not embedding"
        return false
    }
    let tmp = (mktemp --suffix $".($ext)")
    $data | save -f $tmp
    ^opustags -i --set-cover $tmp ($file | path expand)
    rm $tmp
    print "  cover: embedded"
    true
}

# Find and embed cover art. Tries the Cover Art Archive when a MusicBrainz
# release id is known (exact), then Deezer by album then by track, then a
# pasted URL.
def music-cover [file: string, --caa-url: string = ""] {
    # exact art for the release MusicBrainz identified
    if ($caa_url | is-not-empty) {
        let ok = (try {
            if (yes-or "  embed the MusicBrainz release cover \(Cover Art Archive\)? [Y]es / [n]o: ") {
                embed-image $file $caa_url
            } else { false }
        } catch { false })
        if $ok { return }
    }
    let tags = (read-tags ($file | path expand))
    let artist = (tag-val $tags artist)
    let title = (tag-val $tags title)
    let album = (tag-val $tags album)
    # Deezer: try the album first, fall back to the track
    mut queries = []
    if ($album | is-not-empty) { $queries = ($queries ++ [$'artist:"($artist)" album:"($album)"']) }
    $queries = ($queries ++ [$'artist:"($artist)" track:"($title)"'])
    mut hits = []
    for q in $queries {
        if ($hits | is-empty) {
            let qs = ({q: $q} | url build-query)
            let res = (try {
                http get --headers [User-Agent $MUSIC_UA] $"https://api.deezer.com/search?($qs)"
            } catch { {data: []} })
            $hits = ($res | get -o data | default [])
        }
    }
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
    embed-image $file $url | ignore
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

    # MusicBrainz: canonical album/date (earliest official album release).
    # Shazam identifies the recording reliably but reports whatever release its
    # catalog entry belongs to — often a compilation or remaster.
    let mb = (mb-release ($track | get -o subtitle | default "") ($track | get -o title | default ""))
    let sz_album = ((meta-val $metaflat Album) | str replace --regex '\s*-\s*Single$' '')
    let sz_date = (meta-val $metaflat Released)
    if ($mb | is-not-empty) {
        print $"  musicbrainz: album '($mb.album)' \(($mb.date)\)   [shazam said: '($sz_album)' \(($sz_date)\)]"
    }

    # propose fields (MusicBrainz for album/date, Shazam otherwise, old tags last)
    print "confirm each field (enter = accept, or type a correction):"
    print "  conventions: classical = 'Composer: Work'; feat. goes in the title; romanized or Hangeul"
    let title = (confirm-field "title " (($track | get -o title | default "") | default (tag-val $old_tags title)))
    let artists_raw = (confirm-field "artist(s), ';'-separated, main first" (($track | get -o subtitle | default "") | default (tag-val $old_tags artist)))
    let artists = ($artists_raw | split row ";" | each { str trim } | where ($it | is-not-empty))
    let alb_prop = (($mb | get -o album | default "") | default $sz_album | default (tag-val $old_tags album))
    let album = (confirm-field "album " $alb_prop)
    let date_prop = (($mb | get -o date | default "") | default $sz_date | default (tag-val $old_tags date))
    let date = (confirm-field "date  " $date_prop)
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

    # only offer the CAA cover when the user kept the MusicBrainz album
    let caa = (if ($mb | is-not-empty) and ($album == $mb.album) { $mb.caaurl } else { "" })
    music-cover $final --caa-url $caa
    music-lyrics $final
    print "done."
}

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

# prompt with one option per source: enter = first option, a number picks
# that option, any other text is a custom value.
# options: list of {src: string, value: string}; empties dropped, deduped.
def choose-field [label: string, options: list] {
    let opts = ($options | where {|o| $o.value | str trim | is-not-empty } | uniq-by value)
    if ($opts | is-empty) {
        return (input $"  ($label) \(no suggestions — type a value, enter leaves it empty\): " | str trim)
    }
    if (($opts | length) == 1 ) {
        let v = (confirm-field $"($label) \(($opts | first | get src); '-' = empty\)" ($opts | first | get value))
        return (if ($v == "-") { "" } else { $v })
    }
    print $"  ($label):"
    for i in 0..(($opts | length) - 1) {
        print $"    [($i + 1)] ($opts | get $i | get src): ($opts | get $i | get value)"
    }
    let ans = (input $"  ($label) \(number / custom / '-' = empty\) [1]: " | str trim)
    resolve-choice $ans $opts
}

# enter = first option, in-range number = that option, '-' = explicitly
# empty (e.g. a standalone single has no album), anything else = custom
def resolve-choice [ans: string, opts: list] {
    if ($ans | is-empty) { return ($opts | first | get value) }
    if ($ans == "-") { return "" }
    let n = (try { $ans | into int } catch { 0 })
    if ($n >= 1) and ($n <= ($opts | length)) {
        $opts | get ($n - 1) | get value
    } else { $ans }
}

def yes-or [prompt: string] {
    let ans = (input $prompt | str trim)
    ($ans | is-empty) or (($ans | str downcase) starts-with "y")
}

# Suggest a romanization for Japanese/Chinese text via kakasi (Hepburn-ish).
# Hangeul stays as-is per library convention. Returns the input unchanged when
# there's nothing to do or kakasi is unavailable. NB: kakasi assumes Japanese
# readings — for a Chinese-only title, treat the suggestion with suspicion.
def romanize-suggest [s: string] {
    if ($s =~ '[가-힣]') { return $s }
    if not ($s =~ '[぀-ヿ一-鿿]') { return $s }
    if (which kakasi | is-empty) { return $s }
    let r = (try { $s | ^kakasi -i utf8 -o utf8 -Ja -Ha -Ka -Ea -s | str trim } catch { "" })
    if ($r | is-empty) { $s } else {
        $r | str replace -a "( " "(" | str replace -a " )" ")" | str replace --all --regex ' +' ' '
    }
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

# GET a MusicBrainz API URL with retries (MB throttles bursts with 503s)
def mb-get [url: string] {
    for delay in [2sec 5sec] {
        let res = (try { http get --headers [User-Agent $MUSIC_UA] $url } catch { null })
        if ($res != null) { return $res }
        sleep $delay
    }
    try { http get --headers [User-Agent $MUSIC_UA] $url } catch { {} }
}

# Look up the earliest official album release of a recording on MusicBrainz.
# Returns {album, date, caaurl}, or an empty record when nothing was found.
def mb-release [artist: string, title: string] {
    if ($artist | is-empty) or ($title | is-empty) { return {} }
    # MB recording titles don't carry "(feat. X)" suffixes
    let clean = ($title | str replace --all --regex '\s*[\(\[][^\)\]]*[\)\]]' '' | str trim)
    # Two query shapes: artistname-constrained first (common titles like
    # "Mastermind" have hundreds of recordings and the right one may not make
    # the top 100 of a title-only search), then title-only with alias (covers
    # romanized titles like "Yoru ni Kakeru" and romanized artists that
    # artistname doesn't index, e.g. "Kenshi Yonezu"). Credits are also
    # matched client-side either way.
    let base = $"\(recording:\"($clean)\" OR alias:\"($clean)\"\)"
    mut recs = []
    for q in [$"($base) AND artistname:\"($artist)\"" $base] {
        if ($recs | is-empty) {
            let qs = ({query: $q, fmt: "json", limit: "100"} | url build-query)
            let res = (mb-get $"https://musicbrainz.org/ws/2/recording/?($qs)")
            $recs = ($res | get -o recordings | default []
                | where {|r| not (($r | get -o disambiguation | default "") =~ '(?i)live|demo|instrumental|karaoke|remix|mix|edit') }
                | where {|r| mb-credit-match $r $artist })
            if ($recs | is-empty) { sleep 1100ms }  # MusicBrainz rate limit
        }
    }
    # search ranking can't be trusted (live versions, re-records, DJ mixes and
    # covers all score 100): pool the releases of every non-derivative
    # recording credited to this artist, then pick the earliest studio album
    # (compilations/live/soundtracks have secondary types), then any album,
    # then any release. The date is the earliest release of any kind (the
    # single often precedes the album).
    let rels = ($recs
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

# ---------- Deezer (independent of the Apple-backed Shazam catalog) ----------

# Search Deezer for a track: advanced query first, plain-text fallback with
# a client-side artist check (Deezer's fielded search misses some catalog
# entries entirely, e.g. Taylor Swift's "Mastermind"). Returns hit or {}.
def deezer-find [artist: string, title: string] {
    let queries = [$'artist:"($artist)" track:"($title)"' $"($artist) ($title)"]
    for q in $queries {
        let qs = ({q: $q} | url build-query)
        let res = (try {
            http get --headers [User-Agent $MUSIC_UA] $"https://api.deezer.com/search?($qs)"
        } catch { {} })
        let hits = ($res | get -o data | default []
            | where {|h| (($h | get -o artist | default {} | get -o name | default "") | str downcase) == ($artist | str downcase) })
        if ($hits | is-not-empty) { return ($hits | first) }
    }
    {}
}

# Look up a track on Deezer. Returns {album, date} or an empty record.
# (Release date needs a second request: search results don't carry it.)
def deezer-lookup [artist: string, title: string] {
    if ($artist | is-empty) or ($title | is-empty) { return {} }
    let clean = ($title | str replace --all --regex '\s*[\(\[][^\)\]]*[\)\]]' '' | str trim)
    let h = (deezer-find $artist $clean)
    if ($h | is-empty) { return {} }
    let albid = ($h | get -o album | default {} | get -o id | default 0)
    let alb = (if ($albid == 0) { {} } else {
        try { http get --headers [User-Agent $MUSIC_UA] $"https://api.deezer.com/album/($albid)" } catch { {} }
    })
    {
        album: ($h | get -o album | default {} | get -o title | default "")
        date: ($alb | get -o release_date | default "" | str substring 0..3)
    }
}

# ---------- cover art ----------

# Download an image, validating it really is one (pasted URLs sometimes serve
# HTML redirect pages). Returns {data, ext} or an empty record.
def fetch-image [url: string] {
    let data = (try { http get --headers [User-Agent $MUSIC_UA] $url | into binary } catch { null })
    if ($data == null) { return {} }
    let ext = if ($data | bytes starts-with 0x[FFD8FF]) {
        "jpg"
    } else if ($data | bytes starts-with 0x[89504E47]) {
        "png"
    } else { "" }
    if ($ext | is-empty) { return {} }
    {data: $data, ext: $ext}
}

# Render the image inline (kitty graphics via viu; ghostty supports it).
def preview-image [img] {
    if (which viu | is-empty) { return }
    let tmp = (mktemp --suffix $".($img.ext)")
    $img.data | save -f $tmp
    try { ^viu -w 30 $tmp } catch { }
    rm $tmp
}

def embed-img [file: string, img] {
    let tmp = (mktemp --suffix $".($img.ext)")
    $img.data | save -f $tmp
    ^opustags -i --set-cover $tmp ($file | path expand)
    rm $tmp
    print "  cover: embedded"
}

# Download, preview, confirm, embed (used for custom URLs). Returns true
# when embedded.
def offer-image [file: string, url: string, label: string] {
    let img = (fetch-image $url)
    if ($img | is-empty) {
        print "  cover: URL did not return a JPEG/PNG (download failed, or HTML page)"
        return false
    }
    print $"  ($label):"
    preview-image $img
    if (yes-or "  embed this cover? [Y]es / [n]o: ") {
        embed-img $file $img
        true
    } else { false }
}

# Find and embed cover art: shows the MusicBrainz (Cover Art Archive) and
# Deezer candidates side by side, then pick by number, paste a URL, or skip.
def music-cover [file: string, --caa-url: string = ""] {
    let tags = (read-tags ($file | path expand))
    let artist = (tag-val $tags artist)
    let title = (tag-val $tags title)
    let album = (tag-val $tags album)
    mut cands = []
    # exact art for the release MusicBrainz identified
    if ($caa_url | is-not-empty) {
        let img = (fetch-image $caa_url)
        if ($img | is-not-empty) {
            $cands = ($cands ++ [{label: "MusicBrainz (Cover Art Archive)", img: $img}])
        }
    }
    # Deezer: try the album first, then the track (with plain-text fallback)
    mut h = {}
    if ($album | is-not-empty) {
        let qs = ({q: $'artist:"($artist)" album:"($album)"'} | url build-query)
        let res = (try {
            http get --headers [User-Agent $MUSIC_UA] $"https://api.deezer.com/search?($qs)"
        } catch { {data: []} })
        $h = ($res | get -o data | default [] | get -o 0 | default {})
    }
    if ($h | is-empty) { $h = (deezer-find $artist $title) }
    if ($h | is-not-empty) {
        let url = ($h.album | get -o cover_big | default ($h.album | get -o cover_xl | default ""))
        let img = (if ($url | is-empty) { {} } else { fetch-image $url })
        if ($img | is-not-empty) {
            $cands = ($cands ++ [{label: $"Deezer \(($h.album.title) — ($h.artist.name)\)", img: $img}])
        }
    }
    if ($cands | is-empty) {
        print "  no covers found on MusicBrainz/Deezer"
        let ans = (input "  paste an image URL to embed, or enter to skip: " | str trim)
        if ($ans starts-with "http") { offer-image $file $ans "your image" | ignore } else { print "  cover: skipped" }
        return
    }
    for i in 0..(($cands | length) - 1) {
        print $"  [($i + 1)] ($cands | get $i | get label):"
        preview-image ($cands | get $i | get img)
    }
    let ans = (input $"  cover \(number / image URL / 'n'one\) [1]: " | str trim)
    let n = (try { $ans | into int } catch { 0 })
    if ($ans | is-empty) {
        embed-img $file ($cands | first | get img)
    } else if ($n >= 1) and ($n <= ($cands | length)) {
        embed-img $file ($cands | get ($n - 1) | get img)
    } else if ($ans starts-with "http") {
        offer-image $file $ans "your image" | ignore
    } else {
        print "  cover: skipped"
    }
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
    let mb_album = ($mb | get -o album | default "")
    let mb_date = ($mb | get -o date | default "")
    # Deezer: catalog independent of Apple (Shazam's metadata is Apple Music's)
    let dz = (deezer-lookup ($track | get -o subtitle | default "") ($track | get -o title | default ""))
    let dz_album = ($dz | get -o album | default "" | str replace --regex '\s*-\s*Single$' '')
    let dz_date = ($dz | get -o date | default "")

    # every source is offered per field; kakasi romanizations of
    # Japanese/Chinese values are prepended as the default per convention
    def with-romanized [src: string, value: string] {
        let sug = (romanize-suggest $value)
        if ($sug != $value) {
            [{src: $"($src), romanized", value: $sug} {src: $src, value: $value}]
        } else {
            [{src: $src, value: $value}]
        }
    }
    print "pick each field (enter = first option, number = that option, text = custom):"
    print "  conventions: classical = 'Composer: Work'; feat. goes in the title; romanized or Hangeul"
    let title = (choose-field "title " (
        (with-romanized shazam ($track | get -o title | default ""))
        ++ (with-romanized "existing tag" (tag-val $old_tags title))))
    let artists_raw = (choose-field "artist(s), ';'-separated, main first" (
        (with-romanized shazam ($track | get -o subtitle | default ""))
        ++ (with-romanized "existing tag" (tag-val $old_tags artist))))
    let artists = ($artists_raw | split row ";" | each { str trim } | where ($it | is-not-empty))
    let album = (choose-field "album " (
        (with-romanized musicbrainz $mb_album)
        ++ (with-romanized "shazam/apple" $sz_album)
        ++ (with-romanized deezer $dz_album)
        ++ (with-romanized "existing tag" (tag-val $old_tags album))))
    let date = (choose-field "date  " [
        {src: musicbrainz, value: $mb_date}
        {src: "shazam/apple", value: $sz_date}
        {src: deezer, value: $dz_date}
        {src: "existing tag", value: (tag-val $old_tags date)}
    ])
    let genre = (choose-field "genre " [
        {src: shazam, value: ($track | get -o genres | default {} | get -o primary | default "")}
        {src: "existing tag", value: (tag-val $old_tags genre)}
    ])

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

    # the MusicBrainz cover is always shown as one of the side-by-side
    # candidates when MB matched — you judge it by eye, not by whether the
    # album string was edited
    let caa = (if ($mb | is-not-empty) { $mb | get -o caaurl | default "" } else { "" })
    music-cover $final --caa-url $caa
    music-lyrics $final
    print "done."
}

# Download from YouTube and immediately fix its metadata: ytda + metadata-adder.
# (Keep the yt-dlp flags in sync with the ytda abbreviation in config.nu.)
def ytdm [url: string] {
    let printed = (^yt-dlp --embed-metadata --xattrs -x -f bestaudio
        --sponsorblock-remove music_offtopic,intro,outro
        --progress --no-simulate --print after_move:filepath $url | lines)
    # the progress bar shares stdout using carriage returns; the real path is
    # the last CR-separated segment of the last line
    let out = (if ($printed | is-empty) { "" } else { $printed | last | split row (char cr) | last | str trim })
    if ($out | is-empty) or (not ($out | path exists)) {
        error make {msg: "yt-dlp did not produce a file"}
    }
    print $"downloaded: ($out)"
    metadata-adder $out --url $url
}

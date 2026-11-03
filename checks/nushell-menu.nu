let expand = ($env.config.menus | where name == abbr_menu | last | get source)

for case in [
    {buffer: "g", cursor: 1, expected: "git"}
    {buffer: "sudo g", cursor: 6, expected: "sudo git"}
    {buffer: "echo gs tail", cursor: 7, expected: "echo git status tail"}
    {buffer: "echo é g tail", cursor: 9, expected: "echo é git tail"}
    {buffer: "echo unchanged", cursor: 14, expected: "echo unchanged"}
    {buffer: "", cursor: 0, expected: ""}
] {
    # Exercise both the Mac's positional API and Linux's named-record API.
    for place in [$case.cursor {cursor: $case.cursor}] {
        let actual = (do $expand $case.buffer $place).value
        if $actual != $case.expected {
            error make {msg: $"Abbreviation failed for '($case.buffer)': expected '($case.expected)', got '($actual)'"}
        }
    }
}

let nu_version = (version | get version | split row '.' | take 2 | each { into int })
if $nu_version.0 > 0 or $nu_version.1 >= 116 {
    # This uses the same named-parameter binder as menus and surfaces deprecations.
    $env.config.completions.external.completer = $expand
    'git g' | commandline complete --detailed | ignore
}

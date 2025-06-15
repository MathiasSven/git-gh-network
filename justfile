bash := require("bash")
set shell := ["bash", "-uc"]
set quiet

PREFIX := "/usr/local"
BINPREFIX := PREFIX / "bin"
SYSCONFDIR := PREFIX / "etc"
MANPREFIX := PREFIX / "share/man/man1"

COMPL_DIR := if os() == "macos" {
    SYSCONFDIR / "bash_completion.d"
} else {
    SYSCONFDIR / "bash-completion/completions"
}

VERSION := ```
    [[ $(cat ./src/git-gh-network) =~ VERSION=\"([^[:space:]]*)\" ]]
    echo ${BASH_REMATCH[1]}
```

install: docs
    install -m 0644 docs/*.1 -D -t {{MANPREFIX}}
    install src/* -D -t {{BINPREFIX}}


# Example recipe that uses the variables
@test:
    echo "Prefix: {{PREFIX}}"
    echo "Binary Prefix: {{BINPREFIX}}"
    echo "System Config Dir: {{SYSCONFDIR}}"
    echo "Man Prefix: {{MANPREFIX}}"
    echo "Completion Dir: {{COMPL_DIR}}"

docs:
    #!{{bash}}
    set -euo pipefail

    function gen_doc {
        local filename="${1##*/}"
        local base="${filename%%.*}"
        local date=$(git log -1 --pretty="format:%cd" --date=format:'%m/%d/%Y' "$1" 2>/dev/null)
        pandoc \
            --standalone \
            --to man \
            --shift-heading-level-by=-1 \
            -V date="$date" \
            -V title="${base^^}" \
            -V section=1 \
            -V header="Git GitHub Network Manual" \
            -V footer='git-gh-network {{VERSION}}' \
            $1 docs/common/footer.md \
            -o "${1%.*}.1"
    }
    for file in docs/*.md; do
        gen_doc "$file"
    done

[confirm("Remove all ignored files?")]
clean:
    git clean -X -f

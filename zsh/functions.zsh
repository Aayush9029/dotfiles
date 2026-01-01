# Custom Functions

# Quick Claude Haiku prompt helper
function ask_claude {
  claude --model=haiku -p "$*"
}

# Google search with Gemini
google() {
  gemini -p "Search google for <query>$*</query> and summarize results"
}

# Generate context from files of a specific extension
function context_gen {
    find . -name "*.$1" -type f -exec printf '\n=== %s ===\n' {} \; -exec cat {} \;
}

# Wrap xcodebuild to automatically pipe through xcbeautify
function xcodebuild {
    command xcodebuild "$@" 2>&1 | xcbeautify
}

# Convert video files to optimized GIFs using ffmpeg and gifsicle
gifify() {
    # Defaults
    local lossy=65 fps=24 width=1000 gamma=1.2

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --lossy) lossy="$2"; shift 2 ;;
            --fps)   fps="$2";   shift 2 ;;
            --width) width="$2"; shift 2 ;;
            --gamma) gamma="$2"; shift 2 ;;
            --help|-h)
              echo "Usage: gifify [--lossy N] [--fps N] [--width N] [--gamma VAL] <input video> <output.gif>"
              echo "Defaults: --lossy 65  --fps 24  --width 1000  --gamma 1.2"
              return 0
              ;;
            --) shift; break ;;
            --*) echo "Unknown option: $1" >&2; return 2 ;;
            *)  break ;;
        esac
    done

    if (( $# < 2 )); then
        echo "Usage: gifify [--lossy N] [--fps N] [--width N] [--gamma VAL] <input video> <output.gif>" >&2
        return 2
    fi

    local in="$1"
    local out="$2"
    local tmp="$(mktemp -t gifify.XXXXXX).gif"
    trap 'rm -f "$tmp"' EXIT

    echo "[gifify] FFmpeg: starting encode → '$in' → temp GIF (fps=${fps}, width=${width})…"
    if ! ffmpeg -hide_banner -loglevel error -nostats -y -i "$in" \
        -filter_complex "fps=${fps},scale=iw*sar:ih,scale=${width}:-1,split[a][b];[a]palettegen[p];[b][p]paletteuse=dither=floyd_steinberg" \
        "$tmp"
    then
        echo "[gifify] FFmpeg failed." >&2
        return 1
    fi

    echo "[gifify] FFmpeg: done. Starting gifsicle (lossy=${lossy}, gamma=${gamma})…"
    if ! gifsicle -O3 --gamma="$gamma" --lossy="$lossy" "$tmp" -o "$out"; then
        echo "[gifify] gifsicle failed." >&2
        return 1
    fi

    local bytes
    bytes=$(stat -f%z "$out" 2>/dev/null || stat -c%s "$out" 2>/dev/null || echo "")
    if [[ -n "$bytes" ]]; then
        local mb
        mb=$(LC_ALL=C printf "%.2f" $(( bytes / 1000000.0 )))
        echo "[gifify] gifsicle: done. Wrote '$out' (${mb} MB)."
    else
        echo "[gifify] gifsicle: done. Wrote '$out'."
    fi
}

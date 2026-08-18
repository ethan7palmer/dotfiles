#!/usr/bin/env bash
#
# Updates the packages and software this repo installs - never a
# system-wide `apt upgrade`, and never re-runs install-only steps
# (identity prompts, symlinking, GNOME settings). See updates/*.sh for
# what each stage actually does; this file only orchestrates them, the
# same division install.sh keeps against scripts/*.sh.
#
set -euo pipefail

cd "$(dirname "$0")"
source lib/stages.sh

if [ -t 1 ] && command -v tput >/dev/null 2>&1 && [ "$(tput colors 2>/dev/null || echo 0)" -ge 8 ]; then
    BOLD="$(tput bold)"
    RESET="$(tput sgr0)"
    CYAN="$(tput setaf 6)"
    GREEN="$(tput setaf 2)"
else
    BOLD="" RESET="" CYAN="" GREEN=""
fi

# ---------------------------------------------------------------------------
# Options
# ---------------------------------------------------------------------------

INTERACTIVE_SKIP=false
declare -A SKIP=()

for arg in "$@"; do
    case "${arg}" in
        -h | --help)
            cat <<EOF
${BOLD}Usage:${RESET} ./update.sh [OPTIONS]

Updates apt packages, Handy, herdr, Claude Code, zinit + its zsh plugins,
and Neovim's lazy.nvim plugins - everything this repo installs, and
nothing else. Safe to re-run any time.

${BOLD}Options:${RESET}
  --skip=STAGE,...    Skip these stages (comma-separated). Stage ids are
                       the updates/ filenames with the numeric prefix
                       stripped.
                       Current stages: $(all_stage_ids updates | paste -sd, -)
  --skip               Same, but prompts with a numbered checklist instead
                       of taking stage ids on the command line.
  -h, --help           Show this help and exit.
EOF
            exit 0
            ;;
        --skip=*)
            raw="${arg#--skip=}"
            valid="$(all_stage_ids updates)"
            for id in ${raw//,/ }; do
                if ! grep -qx "${id}" <<<"${valid}"; then
                    echo "Unknown stage for --skip: ${id}" >&2
                    echo "Valid stages: $(echo "${valid}" | paste -sd, -)" >&2
                    exit 1
                fi
                SKIP["${id}"]=true
            done
            ;;
        --skip)
            INTERACTIVE_SKIP=true
            ;;
        *)
            echo "Unknown option: ${arg}" >&2
            echo "Run './update.sh --help' for usage." >&2
            exit 1
            ;;
    esac
done

if [ "${INTERACTIVE_SKIP}" = true ]; then
    echo "Enter the numbers of any stages to skip (space or comma separated),"
    echo "or press Enter to skip none:"
    prompt_skip_picker updates
    echo
fi

run=() skip=()
for id in $(all_stage_ids updates); do
    if skipped "${id}"; then
        skip+=("${id}")
    else
        run+=("${id}")
    fi
done

if [ ${#run[@]} -eq 0 ]; then
    echo "Every stage is skipped — nothing to do."
    exit 0
fi

echo "${BOLD}Will update:${RESET} ${run[*]}"
[ ${#skip[@]} -gt 0 ] && echo "${BOLD}Skipping:${RESET} ${skip[*]}"

reply=""
read -r -p "Continue? [Y/n] " reply || true
case "$(printf '%s' "$reply" | tr '[:upper:]' '[:lower:]')" in
    n | no)
        echo "Aborted, no changes made."
        exit 0
        ;;
    *) ;;
esac

for script in updates/*.sh; do
    skipped "$(stage_id "${script}")" && continue
    echo
    echo "${BOLD}${CYAN}==> ${script}${RESET}"
    bash "${script}"
done

echo
echo "${BOLD}${GREEN}Done.${RESET}"

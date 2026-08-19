# Shared by install.sh and update.sh: turns a directory of numbered
# NN-name.sh stage scripts into --skip-able stage ids ("name", numeric
# prefix stripped), backed by a SKIP[] associative array each caller
# declares for itself before sourcing this.
#
# shellcheck shell=bash

stage_id() {
    basename "$1" .sh | sed -E 's/^[0-9]+-//'
}

all_stage_ids() {
    local script
    for script in "$1"/*.sh; do
        stage_id "${script}"
    done
}

skipped() { [ "${SKIP[$1]:-false}" = true ]; }

# Numbered checklist of every stage in dir $1; marks whatever's picked as
# skipped in SKIP[]. Caller prints its own prompt text first, and must have
# already sourced lib/colors.sh for the warn() this uses.
prompt_skip_picker() {
    local dir="$1" id token reply="" i=1
    local -a stage_list=()
    for id in $(all_stage_ids "${dir}"); do
        stage_list+=("${id}")
        echo "  ${i}) ${id}"
        i=$((i + 1))
    done
    read -r -p "> " reply || true
    for token in ${reply//,/ }; do
        if [[ "${token}" =~ ^[0-9]+$ ]] && [ "${token}" -ge 1 ] && [ "${token}" -le "${#stage_list[@]}" ]; then
            SKIP["${stage_list[$((token - 1))]}"]=true
        else
            warn "Ignoring unrecognized entry: ${token}"
        fi
    done
}

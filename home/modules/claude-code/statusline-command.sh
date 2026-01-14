#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# Claude Code Status Line Command
# ==============================================================================

readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly BOLD_GREEN='\033[1;32m'
readonly YELLOW='\033[0;33m'
readonly BOLD_BLUE='\033[1;34m'
readonly DIMMED_WHITE='\033[2;37m'
readonly RESET='\033[0m'

# ------------------------------------------------------------------------------
# Utility Functions
# ------------------------------------------------------------------------------

get_directory_display() {
  local cwd="$1"
  if [[ "${cwd}" == "${HOME}" ]]; then
    echo "~"
  else
    basename "${cwd}"
  fi
}

get_git_branch() {
  local cwd="$1"
  git -C "${cwd}" --no-optional-locks branch --show-current 2>/dev/null || true
}

get_git_divergence() {
  local cwd="$1"
  local ahead behind

  # Get commits ahead / behind from tracking branch
  read -r ahead behind < <(git -C "${cwd}" --no-optional-locks rev-list --left-right --count '@{upstream}...HEAD' 2>/dev/null || echo "0 0")

  local divergence=()
  [[ "${ahead}" -gt 0 ]] && divergence+=("»${ahead}")
  [[ "${behind}" -gt 0 ]] && divergence+=("«${behind}")

  [[ ${#divergence[@]} -gt 0 ]] && printf ' %s' "${divergence[@]}"
}

get_git_status_counts() {
  local cwd="$1"
  local status_output
  status_output="$(git -C "${cwd}" --no-optional-locks status --porcelain 2>/dev/null || true)"

  if [[ -z "${status_output}" ]]; then
    return
  fi

  local staged modified untracked
  staged="$(echo "${status_output}" | grep -c '^[MA]' || true)"
  modified="$(echo "${status_output}" | grep -c '^ M' || true)"
  untracked="$(echo "${status_output}" | grep -c '^??' || true)"

  local status_parts=()
  [[ "${staged}" -gt 0 ]] && status_parts+=("+${staged}")
  [[ "${modified}" -gt 0 ]] && status_parts+=("!${modified}")
  [[ "${untracked}" -gt 0 ]] && status_parts+=("?${untracked}")

  [[ ${#status_parts[@]} -gt 0 ]] && printf ' %s' "${status_parts[@]}"
}

format_git_info() {
  local cwd="$1"

  if [[ ! -d "${cwd}/.git" ]] && ! git -C "${cwd}" rev-parse --git-dir >/dev/null 2>&1; then
    return
  fi

  local branch
  branch="$(get_git_branch "${cwd}")"
  [[ -z "${branch}" ]] && return

  local git_display divergence status_counts
  git_display="$(printf '%b%s%b' "${GREEN}" "${branch}" "${RESET}")"
  divergence="$(get_git_divergence "${cwd}")"
  status_counts="$(get_git_status_counts "${cwd}")"

  local combined_status="${divergence}${status_counts}"
  if [[ -n "${combined_status}" ]]; then
    git_display="${git_display}$(printf '%b%s%b' "${YELLOW}" "${combined_status}" "${RESET}")"
  fi

  printf ' %s ' "${git_display}"
}

format_context_usage() {
  local input="$1"
  local usage context_size

  usage="$(echo "${input}" | jq '.context_window.current_usage')"
  context_size="$(echo "${input}" | jq -r '.context_window.context_window_size // 0')"

  if [[ "${usage}" == "null" ]] || [[ "${context_size}" -eq 0 ]]; then
    printf '%b0%%%b' "${GREEN}" "${RESET}"
    return
  fi

  # Calculate total current tokens: input + cache_creation + cache_read
  local current_tokens percent_used
  current_tokens="$(echo "${usage}" | jq '
    (.input_tokens // 0) +
    (.cache_creation_input_tokens // 0) +
    (.cache_read_input_tokens // 0)
  ')"
  percent_used=$((current_tokens * 100 / context_size))

  local color="${GREEN}"
  if [[ "${percent_used}" -ge 80 ]]; then
    color="${RED}"
  elif [[ "${percent_used}" -ge 50 ]]; then
    color="${YELLOW}"
  fi

  printf '%b%d%% (%dk/%dk)%b' "${color}" "${percent_used}" "$((current_tokens / 1000))" "$((context_size / 1000))" "${RESET}"
}

format_cost() {
  local input="$1"
  local cost_usd
  cost_usd="$(echo "${input}" | jq -r '.cost.total_cost_usd // 0')"
  printf '%b$%.3f%b' "${GREEN}" "${cost_usd}" "${RESET}"
}

# ------------------------------------------------------------------------------
# Main
# ------------------------------------------------------------------------------

main() {
  local input cwd
  input="$(cat)"
  cwd="$(echo "${input}" | jq -r '.workspace.current_dir')"

  local dir_display git_info prompt_symbol current_time context_usage cost
  dir_display="$(get_directory_display "${cwd}")"
  git_info="$(format_git_info "${cwd}")"
  prompt_symbol="$(printf '%b❯%b' "${BOLD_GREEN}" "${RESET}")"
  context_usage="$(format_context_usage "${input}")"
  cost="$(format_cost "${input}")"
  current_time="$(date +%H:%M)"

  local left_side right_side
  left_side="$(printf '%b%s%b%s%s' "${BOLD_BLUE}" "${dir_display}" "${RESET}" "${git_info}" "${prompt_symbol}")"
  right_side="$(printf '%s  %s  %b%s%b' "${context_usage}" "${cost}" "${DIMMED_WHITE}" "${current_time}" "${RESET}")"

  printf '%s  %s' "${left_side}" "${right_side}"
}

main "$@"

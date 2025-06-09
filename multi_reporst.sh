#!/bin/bash

# =======================================================
# Drutiny Reporting Script (Bash 3.2 compatible)
# =======================================================

# --- Function: Print error message and exit ---
error_exit() {
  echo -e "\033[0;31m[ERROR]\033[0m $1" >&2
  exit 1
}

# --- Function: Parse command-line arguments ---
parse_args() {
  for arg in "$@"; do
    case "$arg" in
      --sitename=*) sitename="${arg#*=}" ;;
      --env=*) env="${arg#*=}" ;;
      --drupal=*) drupal="${arg#*=}" ;;
      --sitereview=*) sitereview="${arg#*=}" ;;
      --domain-selection=*) domain_selection="${arg#*=}" ;;
      --exclude-acquia=*) exclude_acquia="${arg#*=}" ;;
      --domain-list-path=*) domain_list_path="${arg#*=}" ;;
      --sitereview-format=*) sitereview_format="${arg#*=}" ;;
      --sitereview-limit=*) sitereview_limit="${arg#*=}" ;;
      --otherreports=*) otherreports="${arg#*=}" ;;
      --period=*) period="${arg#*=}" ;;
      --start=*) start="${arg#*=}" ;;
      --end=*) end="${arg#*=}" ;;
      --loadanalysis=*) loadanalysis="${arg#*=}" ;;
      --healthanalysis=*) healthanalysis="${arg#*=}" ;;
      --trafficanalysis=*) trafficanalysis="${arg#*=}" ;;
      --appanalysis=*) appanalysis="${arg#*=}" ;;
      --createjson=*) createjson="${arg#*=}" ;;
    esac
  done
}

# --- Function: Prompt for a value if not set by argument ---
prompt_if_empty() {
  local varname="$1"
  local prompt="$2"
  local default="$3"
  eval "current=\$$varname"
  if [ -z "$current" ]; then
    read -p "$prompt" input
    eval "$varname=\"\${input:-$default}\""
  fi
}

# --- Function: Validate argument combinations ---
validate_dependencies() {
  if [[ "$domain_selection" == 4 && -z "$domain_list_path" ]]; then
    error_exit "--domain-selection=4 requires --domain-list-path"
  fi

  if [[ -n "$start" || -n "$end" ]]; then
    if [[ -z "$start" || -z "$end" ]]; then
      error_exit "Both --start and --end must be provided for custom date range"
    fi
    if [[ "$otherreports" != 1 ]]; then
      error_exit "Custom start/end dates require --otherreports=1"
    fi
  fi
}

# --- Function: Construct the period argument ---
get_period_argument() {
  if [[ -n "$start" && -n "$end" ]]; then
    PERIOD_ARGS=(--reporting-period-start="$start" --reporting-period-end="$end")
  else
    case "$period" in
      1) PERIOD_ARGS=(--reporting-period-start="-1 days") ;;
      2) PERIOD_ARGS=(--reporting-period-start="-7 days") ;;
      3) PERIOD_ARGS=(--reporting-period-start="-14 days") ;;
      *) PERIOD_ARGS=() ;;
    esac
  fi
}

# --- Function: Run a drutiny report ---
run_drutiny_report() {
  local profile="$1"
  local folder="$2"
  mkdir -p "$folder"
  cd "$folder" || exit 1

  drutinycs profile:run "$profile" aht:@${sitename}.${env} -f html --no-interaction "${PERIOD_ARGS[@]}"

  if [[ "$createjson" == 1 ]]; then
    drutinycs profile:run "$profile" aht:@${sitename}.${env} -f json --no-interaction "${PERIOD_ARGS[@]}" > "${profile}.json"
  fi
  cd - > /dev/null
}

# --- Main Script ---
parse_args "$@"

prompt_if_empty "sitename" "Enter site name: "
prompt_if_empty "env" "Enter environment: "
prompt_if_empty "drupal" "Drupal version (1=8+, 2=7): "

prompt_if_empty "sitereview" "Run site review? (1=Yes, 2=No): "
if [[ "$sitereview" == 1 ]]; then
  prompt_if_empty "domain_selection" "Domain selection (1=All, 2=WWW, 3=No WWW, 4=Custom): "
  if [[ "$domain_selection" == 4 ]]; then
    prompt_if_empty "domain_list_path" "Path to domain list: "
  fi
  prompt_if_empty "exclude_acquia" "Exclude Acquia domains? (1=Yes, 2=No): "
  prompt_if_empty "sitereview_format" "Site review format (1=HTML, 2=CSV, 3=Both): "
  prompt_if_empty "sitereview_limit" "Limit site reviews (0=All): "
fi

prompt_if_empty "otherreports" "Run other reports? (1=Yes, 2=No): "
if [[ "$otherreports" == 1 ]]; then
  if [[ -z "$start" || -z "$end" ]]; then
    prompt_if_empty "period" "Period (1=1d, 2=1w, 3=2w) or use --start and --end: "
  fi
  prompt_if_empty "loadanalysis" "Run load analysis? (1=Yes, 2=No): "
  prompt_if_empty "healthanalysis" "Run health analysis? (1=Yes, 2=No): "
  prompt_if_empty "trafficanalysis" "Run traffic analysis? (1=Yes, 2=No): "
  prompt_if_empty "appanalysis" "Run app analysis? (1=Yes, 2=No): "
fi

validate_dependencies
get_period_argument

YEAR=$(date +%Y)
WEEK=$(date +%V)
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
NAMEDETAIL="${WEEK}_${sitename}${env}-${TIMESTAMP}"

mkdir -p "${sitename}/$YEAR/$NAMEDETAIL"
cd "${sitename}/$YEAR/$NAMEDETAIL" || exit 1

if [[ "$drupal" == 1 ]]; then
  HEALTH_PROFILE="health_analysis_d8"
else
  HEALTH_PROFILE="health_analysis_d7"
fi

if [[ "$otherreports" == 1 ]]; then
  [[ "$loadanalysis" == 1 ]] && run_drutiny_report "load_analysis" "load_analysis"
  [[ "$healthanalysis" == 1 ]] && run_drutiny_report "$HEALTH_PROFILE" "$HEALTH_PROFILE"
  [[ "$trafficanalysis" == 1 ]] && run_drutiny_report "traffic_analysis" "traffic_analysis"
  [[ "$appanalysis" == 1 ]] && run_drutiny_report "app_analysis" "app_analysis"
fi

echo -e "\n\033[0;32m[INFO]\033[0m All selected reports have been executed."

if [[ "$createjson" == 1 ]]; then
  echo -e "\033[0;36m[INFO]\033[0m Generating AI-friendly summary JSONs..."

  # Determine the directory where this script is located
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

  # Run the Python script from the same directory as the shell script
  python3 "${SCRIPT_DIR}/combine_summaries.py" "$(pwd)"

fi

#!/usr/bin/zsh


while getopts ":t:i:o:" opt; do
  case ${opt} in
    t )
      file=${OPTARG}
      ;;
    i )
      inscope=${OPTARG}
      ;;
    o )
      outscope=${OPTARG}
      ;;
    \? )
      echo "Invalid option: $OPTARG" 1>&2
      exit 1
      ;;
    : )
      echo "Option -$OPTARG requires an argument." >&2
      exit 1
      ;;
  esac
done

# Generate inscope domains
if [[ -n "${inscope}" ]]; then
  if [[ -n "${file}" ]]; then
    while read -r domain; do
      echo ".*\\.${domain//./\\.}\$"
    done < "${file}"
  else
    while read -r domain; do
      echo ".*\\.${domain//./\\.}\$"
    done
  fi
fi

# Generate out-of-scope domains
if [[ -n "${outscope}" ]]; then
  if [[ -n "${file}" ]]; then
    while read -r domain; do
      echo "!.*${domain//./\\.}$"
    done < "${file}"
  else
    while read -r domain; do
      echo "!.*${domain//./\\.}$"
    done
  fi
fi
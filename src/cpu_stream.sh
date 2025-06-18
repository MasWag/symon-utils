#!/bin/sh -ue
######################################
# NAME
#   cpu_stream.sh — Continuously stream CPU usage of matching processes with POSIX timestamps
#
# SYNOPSIS
#   cpu_stream.sh PATTERN [INTERVAL]
#
# DESCRIPTION
#   cpu_stream.sh prints the CPU usage (%) and command name of all processes whose
#   command name matches the given PATTERN, along with a POSIX timestamp (seconds since epoch),
#   at regular intervals as space-separated fields: "CPU" <process> <cpu> <timestamp>. If INTERVAL is omitted, it defaults to 1 second.
#
# OPTIONS
#   PATTERN
#       A shell pattern or POSIX-compatible regular expression to match against the
#       process command name (the "COMM" field from ps).
#   INTERVAL
#       The number of seconds to wait between samples (default: 1).
#
# EXAMPLES
#   # Sample every second (default):
#   cpu_stream.sh myproc
#
#   # Sample every 2 seconds:
#   cpu_stream.sh myproc 2
#
# AUTHOR
#   Masaki Waga
#
# LICENSE
#   Apache License, Version 2.0
######################################

usage() {
  cat <<EOF >&2
Usage: $0 PATTERN [INTERVAL]

PATTERN  Process name pattern to match (required).
INTERVAL Sampling interval in seconds (optional, default: 1).
EOF
  exit 1
}

# Argument count check
if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
  echo "Error: Wrong number of arguments." >&2
  usage
fi

PATTERN=$1
INTERVAL=${2:-1}

# Validate INTERVAL is a positive integer
case "$INTERVAL" in
  *[!0-9]* | "")
    echo "Error: INTERVAL must be a positive integer, got '$INTERVAL'." >&2
    usage
    ;;
  *)
    if [ "$INTERVAL" -le 0 ]; then
      echo "Error: INTERVAL must be >= 1." >&2
      usage
    fi
    ;;
esac

# Main sampling loop
while :
do
  # POSIX time (seconds since epoch)
  TS=$(date '+%s')

  ps -e -o pcpu= -o comm= |
    awk -v pat="$PATTERN" -v ts="$TS" '
      $2 ~ pat { printf("CPU %s %.1f %s\n", $2, $1, ts) }
    '

  sleep "$INTERVAL"
done


#!/usr/bin/env bash
# Lint a handoff document written by the `handoff` skill.
#
# Usage: bash lint.sh <path-to-handoff.md>
#
# Exit codes:
#   0 — valid
#   1 — usage error
#   2 — file not found / not readable
#   3 — structural errors (missing sections, wrong order, missing meta, empty required sections)
#
# Rules enforced (errors unless noted):
#   - File path ends with context/handoff.md (warn-only if not)
#   - H1 starts with "Handoff:" and has a non-empty, non-placeholder title
#   - "Meta" section is the first H2 and contains all required keys with non-empty,
#     non-placeholder values; Status is one of in-progress|blocked|review|done;
#     Date is YYYY-MM-DD
#   - All required H2 sections are present, exactly named, and in the defined order
#   - No required section is empty
#   - "_None._" is accepted only in sections where empty-by-design is legitimate
#   - "Edited Files" contains the four required subsections, each with either at
#     least one list entry or "_None._"
#   - "Edited Files" does not list any `context/*` paths except other handoffs (these
#     files are ephemeral subagent state and must be distilled, not referenced)
#   - No leftover placeholders (<...>, TODO, FIXME, template paths) in required sections (warn)
#   - References to ephemeral `context/*.md` files (other than handoffs) are flagged (warn)

set -u

if [ "$#" -ne 1 ]; then
  echo "usage: bash lint.sh <path-to-handoff.md>" >&2
  exit 1
fi

FILE="$1"

if [ ! -f "$FILE" ] || [ ! -r "$FILE" ]; then
  echo "error: cannot read file: $FILE" >&2
  exit 2
fi

ERRORS=0
WARNINGS=0

err()  { echo "ERROR: $*" >&2; ERRORS=$((ERRORS + 1)); }
warn() { echo "warn:  $*" >&2; WARNINGS=$((WARNINGS + 1)); }

case "$FILE" in
  */context/handoff.md) ;;
  *) warn "file is not located at context/handoff.md (got: $FILE)" ;;
esac

# Required H2 sections in exact order.
REQUIRED_SECTIONS=(
  "Meta"
  "TL;DR"
  "Task Summary"
  "Context & Background"
  "Status"
  "Edited Files"
  "Commits"
  "Decisions & Rationale"
  "Test & Verification Status"
  "Open Points"
  "Problems & Caveats"
  "Environment & Setup Notes"
  "Skills to Load"
  "Next Steps"
  "References"
)

# Sections where "_None._" is an acceptable substitute for content.
NONE_ALLOWED=(
  "Commits"
  "Decisions & Rationale"
  "Open Points"
  "Problems & Caveats"
  "References"
)

is_none_allowed() {
  local s="$1" x
  for x in "${NONE_ALLOWED[@]}"; do
    [ "$x" = "$s" ] && return 0
  done
  return 1
}

# --- H1 check ---
H1_LINE="$(grep -m1 -E '^# ' "$FILE" || true)"
if [ -z "$H1_LINE" ]; then
  err "missing H1 title (expected '# Handoff: <title>')"
else
  case "$H1_LINE" in
    "# Handoff: "*)
      TITLE="${H1_LINE#\# Handoff: }"
      stripped="$(echo "$TITLE" | tr -d '[:space:]')"
      if [ -z "$stripped" ] || echo "$TITLE" | grep -q '<'; then
        err "H1 title is empty or still contains a placeholder: '$H1_LINE'"
      fi
      ;;
    *)
      err "H1 must start with '# Handoff: ' (got: '$H1_LINE')"
      ;;
  esac
fi

# --- Collect H2 headings (line number + name), in document order ---
# Only lines that begin with exactly "## " (one space). This excludes H3+.
FOUND_NAMES=()
FOUND_LINES=()
while IFS= read -r raw; do
  ln="${raw%%:*}"
  rest="${raw#*:}"
  name="${rest#\#\# }"
  FOUND_NAMES+=("$name")
  FOUND_LINES+=("$ln")
done < <(grep -nE '^## ' "$FILE" || true)

# --- Required sections present and in order ---
idx=0
for required in "${REQUIRED_SECTIONS[@]}"; do
  match_idx=-1
  j=$idx
  while [ "$j" -lt "${#FOUND_NAMES[@]}" ]; do
    if [ "${FOUND_NAMES[$j]}" = "$required" ]; then
      match_idx=$j
      break
    fi
    j=$((j + 1))
  done
  if [ "$match_idx" -lt 0 ]; then
    if printf '%s\n' "${FOUND_NAMES[@]}" | grep -qxF "$required"; then
      err "section '## $required' is present but out of order"
    else
      err "missing required section: '## $required'"
    fi
  else
    idx=$((match_idx + 1))
  fi
done

# Helper: get body of a named H2 section.
section_body() {
  local name="$1" start="" end="" j next
  for j in "${!FOUND_NAMES[@]}"; do
    if [ "${FOUND_NAMES[$j]}" = "$name" ]; then
      start=$(( ${FOUND_LINES[$j]} + 1 ))
      next=$((j + 1))
      if [ "$next" -lt "${#FOUND_LINES[@]}" ]; then
        end=$(( ${FOUND_LINES[$next]} - 1 ))
      else
        end=$(wc -l < "$FILE" | tr -d ' ')
      fi
      [ "$end" -ge "$start" ] && sed -n "${start},${end}p" "$FILE"
      return
    fi
  done
}

content_is_meaningful() {
  local body="$1"
  printf '%s\n' "$body" \
    | sed -E 's/<!--.*-->//g' \
    | grep -vE '^[[:space:]]*$' \
    | grep -q .
}

has_placeholder() {
  local body="$1"
  printf '%s\n' "$body" | grep -qE '(<[a-zA-Z][^>]*>|(^|[[:space:]])TODO\b|(^|[[:space:]])FIXME\b|YYYY-MM-DD)'
}

# True if a context/* path is a handoff file (and therefore allowed to be referenced).
is_handoff_path() {
  # Matches: context/handoff.md, context/handoff-anything.md
  printf '%s' "$1" | grep -qE '(^|/)context/handoff[^/]*\.md$'
}

# --- Meta block validation ---
META_BLOCK="$(section_body "Meta" || true)"
REQUIRED_META_KEYS=("Date" "Branch" "HEAD" "Session start" "Status" "Author agent")
VALID_STATUSES_REGEX='^(in-progress|blocked|review|done)$'

if [ -n "$META_BLOCK" ]; then
  for key in "${REQUIRED_META_KEYS[@]}"; do
    row="$(printf '%s\n' "$META_BLOCK" | grep -E "^\| *${key} *\|" | head -n1 || true)"
    if [ -z "$row" ]; then
      err "Meta table is missing key: '$key'"
      continue
    fi
    value="$(printf '%s\n' "$row" | awk -F'|' '{print $3}' | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//')"
    bare="$(printf '%s' "$value" | sed -E 's/^`(.*)`$/\1/')"
    if [ -z "$bare" ] || printf '%s' "$bare" | grep -qE '^<.*>$' || [ "$bare" = "YYYY-MM-DD" ]; then
      err "Meta key '$key' has empty or placeholder value: '$value'"
      continue
    fi
    if [ "$key" = "Status" ] && ! printf '%s' "$bare" | grep -qE "$VALID_STATUSES_REGEX"; then
      err "Meta key 'Status' must be one of in-progress|blocked|review|done (got: '$bare')"
    fi
    if [ "$key" = "Date" ] && ! printf '%s' "$bare" | grep -qE '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'; then
      err "Meta key 'Date' must be YYYY-MM-DD (got: '$bare')"
    fi
  done
fi

# --- Per-section content checks ---
for sec in "${REQUIRED_SECTIONS[@]}"; do
  [ "$sec" = "Meta" ] && continue
  body="$(section_body "$sec" || true)"
  if ! content_is_meaningful "$body"; then
    err "section '## $sec' is empty"
    continue
  fi
  trimmed="$(printf '%s\n' "$body" \
    | sed -E 's/<!--.*-->//g' \
    | grep -vE '^[[:space:]]*$' \
    | head -n1 \
    | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//')"
  if [ "$trimmed" = "_None._" ]; then
    if is_none_allowed "$sec"; then
      continue
    else
      err "section '## $sec' uses '_None._' but real content is required here"
      continue
    fi
  fi
  if has_placeholder "$body"; then
    warn "section '## $sec' still contains placeholder text (e.g. <...>, TODO, FIXME)"
  fi
done

# --- Edited Files subsections ---
EDITED_BODY="$(section_body "Edited Files" || true)"
if [ -n "$EDITED_BODY" ]; then
  for sub in "Added" "Modified" "Deleted" "Renamed / Moved"; do
    if ! printf '%s\n' "$EDITED_BODY" | grep -qE "^### ${sub}$"; then
      err "Edited Files: missing required subsection '### $sub'"
    fi
  done

  if printf '%s\n' "$EDITED_BODY" | grep -qE '`path/'; then
    err "Edited Files: contains template placeholder paths (e.g. \`path/to/...\`)"
  fi

  # Each required subsection must have at least one "- " entry or "_None._".
  MISSING_SUBS="$(printf '%s\n' "$EDITED_BODY" | awk '
    BEGIN { sub_name=""; has_item=0; has_none=0 }
    /^### / {
      if (sub_name != "") {
        if (!has_item && !has_none) print sub_name
      }
      sub_name=$0; sub(/^### /, "", sub_name)
      has_item=0; has_none=0
      next
    }
    /^_None\._[[:space:]]*$/ { has_none=1; next }
    /^- /                    { has_item=1; next }
    END {
      if (sub_name != "" && !has_item && !has_none) print sub_name
    }
  ')"
  if [ -n "$MISSING_SUBS" ]; then
    while IFS= read -r name; do
      case "$name" in
        "Added"|"Modified"|"Deleted"|"Renamed / Moved")
          err "Edited Files: subsection '### $name' has no entries and no '_None._' marker"
          ;;
      esac
    done <<EOF
$MISSING_SUBS
EOF
  fi

  # Reject context/* paths in Edited Files except handoff files. These are ephemeral
  # subagent artifacts and must not be tracked as real work.
  while IFS= read -r ctx_path; do
    [ -z "$ctx_path" ] && continue
    if ! is_handoff_path "$ctx_path"; then
      err "Edited Files: lists ephemeral subagent artifact '$ctx_path' — distill into prose instead"
    fi
  done < <(printf '%s\n' "$EDITED_BODY" \
    | grep -oE '`[^`]*context/[^`]+`' \
    | sed -E 's/^`//; s/`$//')
fi

# --- Ephemeral context/* references anywhere in the document (warn) ---
# We scan all sections except "Edited Files" (already handled above) and "References"
# where pointing at other handoffs is fine. The check looks at backticked paths and
# bare paths containing "context/".
DOC_BODY="$(cat "$FILE")"
EDITED_RANGE_START=""
EDITED_RANGE_END=""
for j in "${!FOUND_NAMES[@]}"; do
  if [ "${FOUND_NAMES[$j]}" = "Edited Files" ]; then
    EDITED_RANGE_START="${FOUND_LINES[$j]}"
    next=$((j + 1))
    if [ "$next" -lt "${#FOUND_LINES[@]}" ]; then
      EDITED_RANGE_END=$(( ${FOUND_LINES[$next]} - 1 ))
    else
      EDITED_RANGE_END=$(wc -l < "$FILE" | tr -d ' ')
    fi
    break
  fi
done

while IFS= read -r ref_line; do
  ln_no="${ref_line%%:*}"
  rest="${ref_line#*:}"
  # Skip lines inside the Edited Files block (handled above).
  if [ -n "$EDITED_RANGE_START" ] && [ "$ln_no" -ge "$EDITED_RANGE_START" ] && [ "$ln_no" -le "$EDITED_RANGE_END" ]; then
    continue
  fi
  # Extract every context/... reference on the line and check each.
  while IFS= read -r ctx; do
    [ -z "$ctx" ] && continue
    if ! is_handoff_path "$ctx"; then
      warn "line $ln_no references ephemeral subagent artifact '$ctx' — inline its content instead"
    fi
  done < <(printf '%s\n' "$rest" | grep -oE '(`[^`]*context/[^`]+`|\(context/[^)]+\)|(^|[^A-Za-z0-9_/.-])context/[A-Za-z0-9_./-]+)' \
            | sed -E 's/^[^c]*(context\/[A-Za-z0-9_./-]+).*/\1/; s/^`//; s/`$//; s/^\(//; s/\)$//')
done < <(grep -nE 'context/' "$FILE" || true)

# --- Skills to Load format ---
SKILLS_BODY="$(section_body "Skills to Load" || true)"
if [ -n "$SKILLS_BODY" ]; then
  first_line="$(printf '%s\n' "$SKILLS_BODY" | sed -E 's/<!--.*-->//g' | grep -vE '^[[:space:]]*$' | head -n1 | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//')"
  if [ "$first_line" != "_None._" ]; then
    if ! printf '%s\n' "$SKILLS_BODY" | grep -qE '^- `[^`]+` — .+'; then
      warn "Skills to Load: entries should look like '- \`skill-name\` — reason'"
    fi
  fi
fi

# --- Next Steps must be an ordered list ---
NEXT_BODY="$(section_body "Next Steps" || true)"
if [ -n "$NEXT_BODY" ]; then
  if ! printf '%s\n' "$NEXT_BODY" | grep -qE '^[0-9]+\. '; then
    err "Next Steps must contain an ordered (numbered) list"
  fi
fi

echo
if [ "$ERRORS" -gt 0 ]; then
  echo "handoff lint: FAILED — $ERRORS error(s), $WARNINGS warning(s)" >&2
  exit 3
fi
echo "handoff lint: OK — $WARNINGS warning(s)"
exit 0

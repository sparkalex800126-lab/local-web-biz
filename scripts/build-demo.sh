#!/usr/bin/env bash
# ========================================
# PageReady TW — Demo Builder
# 用 JSON config + HTML/CSS template 產出完整 demo 網站
# Usage: ./scripts/build-demo.sh --config path/to/config.json
# ========================================

set -euo pipefail

# --- Color output helpers ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

info()  { echo -e "${CYAN}ℹ${NC}  $1"; }
ok()    { echo -e "${GREEN}✓${NC}  $1"; }
warn()  { echo -e "${YELLOW}⚠${NC}  $1"; }
fail()  { echo -e "${RED}✗${NC}  $1"; exit 1; }

# --- Parse args ---
CONFIG_FILE=""
NO_GIT=false
DRY_RUN=false

while [[ $# -gt 0 ]]; do
  case $1 in
    --config)  CONFIG_FILE="$2"; shift 2 ;;
    --no-git)  NO_GIT=true; shift ;;
    --dry-run) DRY_RUN=true; shift ;;
    -h|--help)
      echo "Usage: $0 --config <config.json> [--no-git] [--dry-run]"
      echo ""
      echo "Options:"
      echo "  --config   Path to JSON config file (required)"
      echo "  --no-git   Skip git add/commit"
      echo "  --dry-run  Generate files but don't copy to demos/"
      echo ""
      exit 0
      ;;
    *) fail "Unknown option: $1" ;;
  esac
done

[[ -z "$CONFIG_FILE" ]] && fail "Missing --config. Usage: $0 --config <config.json>"
[[ ! -f "$CONFIG_FILE" ]] && fail "Config file not found: $CONFIG_FILE"

# --- Resolve project root ---
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TEMPLATE_DIR="$PROJECT_ROOT/templates"

# Validate templates exist
[[ ! -f "$TEMPLATE_DIR/base-template.html" ]] && fail "Template not found: $TEMPLATE_DIR/base-template.html"
[[ ! -f "$TEMPLATE_DIR/base-style.css" ]]     && fail "Template not found: $TEMPLATE_DIR/base-style.css"
[[ ! -f "$TEMPLATE_DIR/base-script.js" ]]     && fail "Template not found: $TEMPLATE_DIR/base-script.js"

# Validate jq is available
command -v jq >/dev/null 2>&1 || fail "jq is required. Install: brew install jq"

info "Reading config: $CONFIG_FILE"

# --- Helper: read a simple string from JSON ---
jval() {
  jq -r "$1 // empty" "$CONFIG_FILE"
}

# --- Read basic config values ---
STORE_NAME="$(jval '.store_name')"
STORE_NAME_EN="$(jval '.store_name_en')"
STORE_SHORT_NAME="$(jval '.store_short_name')"
STORE_SLUG="$(jval '.store_slug')"
STORE_TYPE="$(jval '.store_type')"
STORE_LOCATION="$(jval '.store_location')"

PRIMARY_COLOR="$(jval '.primary_color')"
PRIMARY_LIGHT="$(jval '.primary_light')"
PRIMARY_DARK="$(jval '.primary_dark')"
PRIMARY_PALE="$(jval '.primary_pale')"
ACCENT_COLOR="$(jval '.accent_color')"
ACCENT_HOVER="$(jval '.accent_hover')"

PHONE="$(jval '.phone')"
ADDRESS="$(jval '.address')"
LINE_ID="$(jval '.line_id')"
HOURS="$(jval '.hours')"

NAV_EMOJI="$(jval '.nav_emoji')"
FAVICON_EMOJI="$(jval '.favicon_emoji')"

HERO_BADGE="$(jval '.hero_badge')"
HERO_IMAGE_ID="$(jval '.hero_image_id')"
SLOGAN="$(jval '.slogan')"
CTA_TEXT="$(jval '.cta_text')"
TESTIMONIAL_SECTION_NAV="$(jval '.testimonial_section_nav')"
META_DESCRIPTION="$(jval '.meta_description')"

ABOUT_IMAGE_ID="$(jval '.about_image_id')"
ABOUT_TITLE="$(jval '.about_title')"
ABOUT_P1="$(jval '.about_p1')"
ABOUT_P2="$(jval '.about_p2')"

FEATURES_TITLE="$(jval '.features_title')"
FEATURES_SUBTITLE="$(jval '.features_subtitle')"

GALLERY_TITLE="$(jval '.gallery_title')"
GALLERY_SUBTITLE="$(jval '.gallery_subtitle')"

TESTIMONIAL_TITLE="$(jval '.testimonial_title')"
TESTIMONIAL_SUBTITLE="$(jval '.testimonial_subtitle')"

CONTACT_SUBTITLE="$(jval '.contact_subtitle')"
SERVICE_EMOJI="$(jval '.service_emoji')"
SERVICE_LABEL="$(jval '.service_label')"
SERVICE_VALUE="$(jval '.service_value')"
MAP_EMBED="$(jval '.map_embed')"

FORM_TITLE="$(jval '.form_title')"
FORM_SUBMIT_TEXT="$(jval '.form_submit_text')"
FOOTER_DESC="$(jval '.footer_desc')"

# Phone without dashes for tel: link
PHONE_RAW="$PHONE"

# Current year
YEAR="$(date +%Y)"

[[ -z "$STORE_SLUG" ]] && fail "store_slug is required in config"
[[ -z "$STORE_NAME" ]] && fail "store_name is required in config"

info "Building demo for: $STORE_NAME ($STORE_SLUG)"

# --- Read stats ---
STAT1_NUM="$(jq -r '.stats[0].num // "0"' "$CONFIG_FILE")"
STAT1_SUFFIX="$(jq -r '.stats[0].suffix // ""' "$CONFIG_FILE")"
STAT1_LABEL="$(jq -r '.stats[0].label // ""' "$CONFIG_FILE")"
STAT2_NUM="$(jq -r '.stats[1].num // "0"' "$CONFIG_FILE")"
STAT2_SUFFIX="$(jq -r '.stats[1].suffix // ""' "$CONFIG_FILE")"
STAT2_LABEL="$(jq -r '.stats[1].label // ""' "$CONFIG_FILE")"
STAT3_NUM="$(jq -r '.stats[2].num // "0"' "$CONFIG_FILE")"
STAT3_SUFFIX="$(jq -r '.stats[2].suffix // ""' "$CONFIG_FILE")"
STAT3_LABEL="$(jq -r '.stats[2].label // ""' "$CONFIG_FILE")"

# --- Generate features HTML ---
info "Generating features HTML..."
FEATURES_HTML=""
FEATURE_COUNT=$(jq '.features | length' "$CONFIG_FILE")
for i in $(seq 0 $((FEATURE_COUNT - 1))); do
  DELAY_CLASS=$(( (i % 4) + 1 ))
  ICON=$(jq -r ".features[$i].icon" "$CONFIG_FILE")
  TITLE=$(jq -r ".features[$i].title" "$CONFIG_FILE")
  DESC=$(jq -r ".features[$i].desc" "$CONFIG_FILE")
  FEATURES_HTML+="        <div class=\"feature-card reveal reveal-delay-${DELAY_CLASS}\">
          <div class=\"feature-icon\">${ICON}</div>
          <h3>${TITLE}</h3>
          <p>${DESC}</p>
        </div>
"
done

# --- Generate gallery HTML ---
info "Generating gallery HTML..."
GALLERY_HTML=""
GALLERY_COUNT=$(jq '.gallery | length' "$CONFIG_FILE")
for i in $(seq 0 $((GALLERY_COUNT - 1))); do
  IMAGE_ID=$(jq -r ".gallery[$i].image_id" "$CONFIG_FILE")
  ALT=$(jq -r ".gallery[$i].alt" "$CONFIG_FILE")
  LABEL=$(jq -r ".gallery[$i].label" "$CONFIG_FILE")
  SIZE=$(jq -r ".gallery[$i].size // \"600\"" "$CONFIG_FILE")
  HEIGHT=$(( SIZE * 3 / 4 ))
  GALLERY_HTML+="        <div class=\"gallery-item\">
          <img src=\"https://images.unsplash.com/${IMAGE_ID}?w=${SIZE}&q=80&auto=format&fit=crop\"
               alt=\"${ALT}\" loading=\"lazy\">
          <div class=\"gallery-item-overlay\"><span>${LABEL}</span></div>
        </div>
"
done

# --- Generate testimonials HTML ---
info "Generating testimonials HTML..."
TESTIMONIALS_HTML=""
TESTIMONIAL_COUNT=$(jq '.testimonials | length' "$CONFIG_FILE")
for i in $(seq 0 $((TESTIMONIAL_COUNT - 1))); do
  DELAY_CLASS=$(( (i % 3) + 1 ))
  TEXT=$(jq -r ".testimonials[$i].text" "$CONFIG_FILE")
  AVATAR=$(jq -r ".testimonials[$i].avatar" "$CONFIG_FILE")
  NAME=$(jq -r ".testimonials[$i].name" "$CONFIG_FILE")
  ROLE=$(jq -r ".testimonials[$i].role" "$CONFIG_FILE")
  TESTIMONIALS_HTML+="        <div class=\"testimonial-card reveal reveal-delay-${DELAY_CLASS}\">
          <div class=\"testimonial-quote\">\&ldquo;</div>
          <div class=\"testimonial-stars\">★★★★★</div>
          <p>${TEXT}</p>
          <div class=\"testimonial-author\">
            <div class=\"testimonial-avatar\">${AVATAR}</div>
            <div>
              <div class=\"testimonial-name\">${NAME}</div>
              <div class=\"testimonial-role\">${ROLE}</div>
            </div>
          </div>
        </div>
"
done

# --- Generate form HTML ---
info "Generating form HTML..."
FORM_HTML=""
FIELD_COUNT=$(jq '.form_fields | length' "$CONFIG_FILE")
for i in $(seq 0 $((FIELD_COUNT - 1))); do
  HAS_ROW=$(jq -r ".form_fields[$i] | has(\"row\")" "$CONFIG_FILE")
  HAS_FULL=$(jq -r ".form_fields[$i] | has(\"full\")" "$CONFIG_FILE")

  if [[ "$HAS_ROW" == "true" ]]; then
    FORM_HTML+="            <div class=\"form-row\">\n"
    ROW_LEN=$(jq ".form_fields[$i].row | length" "$CONFIG_FILE")
    for j in $(seq 0 $((ROW_LEN - 1))); do
      FID=$(jq -r ".form_fields[$i].row[$j].id" "$CONFIG_FILE")
      FTYPE=$(jq -r ".form_fields[$i].row[$j].type" "$CONFIG_FILE")
      FLABEL=$(jq -r ".form_fields[$i].row[$j].label" "$CONFIG_FILE")
      FPLACEHOLDER=$(jq -r ".form_fields[$i].row[$j].placeholder // \"\"" "$CONFIG_FILE")
      FREQUIRED=$(jq -r ".form_fields[$i].row[$j].required // false" "$CONFIG_FILE")

      REQ_ATTR=""
      [[ "$FREQUIRED" == "true" ]] && REQ_ATTR=" required"

      FORM_HTML+="              <div class=\"form-group\">\n"
      FORM_HTML+="                <label for=\"${FID}\">${FLABEL}</label>\n"

      if [[ "$FTYPE" == "select" ]]; then
        FORM_HTML+="                <select id=\"${FID}\" name=\"${FID}\">\n"
        OPT_COUNT=$(jq ".form_fields[$i].row[$j].options | length" "$CONFIG_FILE")
        for k in $(seq 0 $((OPT_COUNT - 1))); do
          OPT=$(jq -r ".form_fields[$i].row[$j].options[$k]" "$CONFIG_FILE")
          if [[ $k -eq 0 ]]; then
            FORM_HTML+="                  <option value=\"\">${OPT}</option>\n"
          else
            FORM_HTML+="                  <option value=\"${OPT}\">${OPT}</option>\n"
          fi
        done
        FORM_HTML+="                </select>\n"
      elif [[ "$FTYPE" == "date" ]]; then
        FORM_HTML+="                <input type=\"date\" id=\"${FID}\" name=\"${FID}\">\n"
      else
        FORM_HTML+="                <input type=\"${FTYPE}\" id=\"${FID}\" name=\"${FID}\" placeholder=\"${FPLACEHOLDER}\"${REQ_ATTR}>\n"
      fi

      FORM_HTML+="              </div>\n"
    done
    FORM_HTML+="            </div>\n"

  elif [[ "$HAS_FULL" == "true" ]]; then
    FID=$(jq -r ".form_fields[$i].full.id" "$CONFIG_FILE")
    FTYPE=$(jq -r ".form_fields[$i].full.type" "$CONFIG_FILE")
    FLABEL=$(jq -r ".form_fields[$i].full.label" "$CONFIG_FILE")
    FPLACEHOLDER=$(jq -r ".form_fields[$i].full.placeholder // \"\"" "$CONFIG_FILE")
    FROWS=$(jq -r ".form_fields[$i].full.rows // 4" "$CONFIG_FILE")

    FORM_HTML+="            <div class=\"form-group\">\n"
    FORM_HTML+="              <label for=\"${FID}\">${FLABEL}</label>\n"
    if [[ "$FTYPE" == "textarea" ]]; then
      FORM_HTML+="              <textarea id=\"${FID}\" name=\"${FID}\" rows=\"${FROWS}\" placeholder=\"${FPLACEHOLDER}\"></textarea>\n"
    else
      FORM_HTML+="              <input type=\"${FTYPE}\" id=\"${FID}\" name=\"${FID}\" placeholder=\"${FPLACEHOLDER}\">\n"
    fi
    FORM_HTML+="            </div>\n"
  fi
done

# --- Compute CSS color derivatives ---
# Extract RGB from primary_dark for shadow tints
# We'll use a simple approach: generate rgba strings
# Parse hex colors for shadow tints
hex_to_rgba() {
  local hex="${1#\#}"
  local r=$((16#${hex:0:2}))
  local g=$((16#${hex:2:2}))
  local b=$((16#${hex:4:2}))
  local a="${2:-0.12}"
  echo "rgba($r, $g, $b, $a)"
}

SHADOW_TINT="$(hex_to_rgba "$PRIMARY_COLOR" "0.12")"
SHADOW_TINT_SM="$(hex_to_rgba "$PRIMARY_COLOR" "0.06")"
SHADOW_TINT_MD="$(hex_to_rgba "$PRIMARY_COLOR" "0.10")"
SHADOW_TINT_LG="$(hex_to_rgba "$PRIMARY_COLOR" "0.14")"
FOCUS_TINT="$(hex_to_rgba "$PRIMARY_COLOR" "0.3")"
PRIMARY_SHADOW="$(hex_to_rgba "$PRIMARY_DARK" "0.35")"
PRIMARY_SHADOW_HOVER="$(hex_to_rgba "$PRIMARY_DARK" "0.45")"
OVERLAY_TINT="$(hex_to_rgba "$PRIMARY_COLOR" "0.25")"

# --- Build output directory ---
OUTPUT_DIR="$PROJECT_ROOT/demos/$STORE_SLUG"

if [[ "$DRY_RUN" == "true" ]]; then
  OUTPUT_DIR="/tmp/pageready-demo-$STORE_SLUG"
fi

mkdir -p "$OUTPUT_DIR"
info "Output directory: $OUTPUT_DIR"

# --- Generate index.html ---
info "Generating index.html..."
cp "$TEMPLATE_DIR/base-template.html" "$OUTPUT_DIR/index.html"

# Perform all replacements
# Use a temp file approach to avoid sed delimiter issues
replace_placeholder() {
  local placeholder="$1"
  local value="$2"
  local file="$3"

  # Use awk for safe replacement
  # Escape & in the replacement value (awk gsub treats & as backreference)
  awk -v pat="$placeholder" -v rep="$value" 'BEGIN { gsub(/&/, "\\\\&", rep) } {gsub(pat, rep); print}' "$file" > "$file.tmp"
  mv "$file.tmp" "$file"
}

HTML="$OUTPUT_DIR/index.html"

replace_placeholder '{{STORE_NAME}}'            "$STORE_NAME"            "$HTML"
replace_placeholder '{{STORE_NAME_EN}}'         "$STORE_NAME_EN"         "$HTML"
replace_placeholder '{{STORE_SHORT_NAME}}'      "$STORE_SHORT_NAME"      "$HTML"
replace_placeholder '{{STORE_SLUG}}'            "$STORE_SLUG"            "$HTML"
replace_placeholder '{{STORE_TYPE}}'            "$STORE_TYPE"            "$HTML"
replace_placeholder '{{STORE_LOCATION}}'        "$STORE_LOCATION"        "$HTML"
replace_placeholder '{{PRIMARY_COLOR}}'         "$PRIMARY_COLOR"         "$HTML"
replace_placeholder '{{ACCENT_COLOR}}'          "$ACCENT_COLOR"          "$HTML"
replace_placeholder '{{PHONE}}'                 "$PHONE"                 "$HTML"
replace_placeholder '{{PHONE_RAW}}'             "$PHONE_RAW"             "$HTML"
replace_placeholder '{{ADDRESS}}'               "$ADDRESS"               "$HTML"
replace_placeholder '{{LINE_ID}}'               "$LINE_ID"               "$HTML"
replace_placeholder '{{HOURS}}'                 "$HOURS"                 "$HTML"
replace_placeholder '{{NAV_EMOJI}}'             "$NAV_EMOJI"             "$HTML"
replace_placeholder '{{FAVICON_EMOJI}}'         "$FAVICON_EMOJI"         "$HTML"
replace_placeholder '{{HERO_BADGE}}'            "$HERO_BADGE"            "$HTML"
replace_placeholder '{{HERO_IMAGE_ID}}'         "$HERO_IMAGE_ID"         "$HTML"
replace_placeholder '{{SLOGAN}}'                "$SLOGAN"                "$HTML"
replace_placeholder '{{CTA_TEXT}}'              "$CTA_TEXT"              "$HTML"
replace_placeholder '{{TESTIMONIAL_SECTION_NAV}}' "$TESTIMONIAL_SECTION_NAV" "$HTML"
replace_placeholder '{{META_DESCRIPTION}}'      "$META_DESCRIPTION"      "$HTML"
replace_placeholder '{{ABOUT_IMAGE_ID}}'        "$ABOUT_IMAGE_ID"        "$HTML"
replace_placeholder '{{ABOUT_TITLE}}'           "$ABOUT_TITLE"           "$HTML"
replace_placeholder '{{ABOUT_P1}}'              "$ABOUT_P1"              "$HTML"
replace_placeholder '{{ABOUT_P2}}'              "$ABOUT_P2"              "$HTML"
replace_placeholder '{{STAT1_NUM}}'             "$STAT1_NUM"             "$HTML"
replace_placeholder '{{STAT1_SUFFIX}}'          "$STAT1_SUFFIX"          "$HTML"
replace_placeholder '{{STAT1_LABEL}}'           "$STAT1_LABEL"           "$HTML"
replace_placeholder '{{STAT2_NUM}}'             "$STAT2_NUM"             "$HTML"
replace_placeholder '{{STAT2_SUFFIX}}'          "$STAT2_SUFFIX"          "$HTML"
replace_placeholder '{{STAT2_LABEL}}'           "$STAT2_LABEL"           "$HTML"
replace_placeholder '{{STAT3_NUM}}'             "$STAT3_NUM"             "$HTML"
replace_placeholder '{{STAT3_SUFFIX}}'          "$STAT3_SUFFIX"          "$HTML"
replace_placeholder '{{STAT3_LABEL}}'           "$STAT3_LABEL"           "$HTML"
replace_placeholder '{{FEATURES_TITLE}}'        "$FEATURES_TITLE"        "$HTML"
replace_placeholder '{{FEATURES_SUBTITLE}}'     "$FEATURES_SUBTITLE"     "$HTML"
replace_placeholder '{{GALLERY_TITLE}}'         "$GALLERY_TITLE"         "$HTML"
replace_placeholder '{{GALLERY_SUBTITLE}}'      "$GALLERY_SUBTITLE"      "$HTML"
replace_placeholder '{{TESTIMONIAL_TITLE}}'     "$TESTIMONIAL_TITLE"     "$HTML"
replace_placeholder '{{TESTIMONIAL_SUBTITLE}}'  "$TESTIMONIAL_SUBTITLE"  "$HTML"
replace_placeholder '{{CONTACT_SUBTITLE}}'      "$CONTACT_SUBTITLE"      "$HTML"
replace_placeholder '{{SERVICE_EMOJI}}'         "$SERVICE_EMOJI"         "$HTML"
replace_placeholder '{{SERVICE_LABEL}}'         "$SERVICE_LABEL"         "$HTML"
replace_placeholder '{{SERVICE_VALUE}}'         "$SERVICE_VALUE"         "$HTML"
replace_placeholder '{{MAP_EMBED}}'             "$MAP_EMBED"             "$HTML"
replace_placeholder '{{FORM_TITLE}}'            "$FORM_TITLE"            "$HTML"
replace_placeholder '{{FORM_SUBMIT_TEXT}}'       "$FORM_SUBMIT_TEXT"      "$HTML"
replace_placeholder '{{FOOTER_DESC}}'           "$FOOTER_DESC"           "$HTML"
replace_placeholder '{{YEAR}}'                  "$YEAR"                  "$HTML"

# Replace multi-line blocks using temp files + awk
# Write snippets to temp files for safe awk replacement
TMPDIR_BUILD="$(mktemp -d)"
trap "rm -rf $TMPDIR_BUILD" EXIT

printf '%s' "$FEATURES_HTML" > "$TMPDIR_BUILD/features.html"
printf '%s' "$GALLERY_HTML" > "$TMPDIR_BUILD/gallery.html"
printf '%s' "$TESTIMONIALS_HTML" > "$TMPDIR_BUILD/testimonials.html"
# Form HTML uses literal \n sequences; convert them
printf '%b' "$FORM_HTML" > "$TMPDIR_BUILD/form.html"

replace_block() {
  local placeholder="$1"
  local snippet_file="$2"
  local target="$3"

  awk -v pat="$placeholder" -v sfile="$snippet_file" '{
    if (index($0, pat) > 0) {
      while ((getline line < sfile) > 0) print line
      close(sfile)
    } else {
      print
    }
  }' "$target" > "$target.tmp"
  mv "$target.tmp" "$target"
}

replace_block '{{FEATURES_HTML}}'     "$TMPDIR_BUILD/features.html"     "$HTML"
replace_block '{{GALLERY_HTML}}'      "$TMPDIR_BUILD/gallery.html"      "$HTML"
replace_block '{{TESTIMONIALS_HTML}}' "$TMPDIR_BUILD/testimonials.html" "$HTML"
replace_block '{{FORM_HTML}}'         "$TMPDIR_BUILD/form.html"         "$HTML"

ok "index.html generated"

# --- Generate style.css ---
info "Generating style.css..."
cp "$TEMPLATE_DIR/base-style.css" "$OUTPUT_DIR/style.css"

CSS="$OUTPUT_DIR/style.css"
replace_placeholder '{{STORE_NAME}}'          "$STORE_NAME"            "$CSS"
replace_placeholder '{{PRIMARY_COLOR}}'       "$PRIMARY_COLOR"         "$CSS"
replace_placeholder '{{PRIMARY_LIGHT}}'       "$PRIMARY_LIGHT"         "$CSS"
replace_placeholder '{{PRIMARY_DARK}}'        "$PRIMARY_DARK"          "$CSS"
replace_placeholder '{{PRIMARY_PALE}}'        "$PRIMARY_PALE"          "$CSS"
replace_placeholder '{{ACCENT_COLOR}}'        "$ACCENT_COLOR"          "$CSS"
replace_placeholder '{{ACCENT_HOVER}}'        "$ACCENT_HOVER"          "$CSS"
replace_placeholder '{{SHADOW_TINT}}'         "$SHADOW_TINT"           "$CSS"
replace_placeholder '{{SHADOW_TINT_SM}}'      "$SHADOW_TINT_SM"        "$CSS"
replace_placeholder '{{SHADOW_TINT_MD}}'      "$SHADOW_TINT_MD"        "$CSS"
replace_placeholder '{{SHADOW_TINT_LG}}'      "$SHADOW_TINT_LG"        "$CSS"
replace_placeholder '{{FOCUS_TINT}}'          "$FOCUS_TINT"            "$CSS"
replace_placeholder '{{PRIMARY_SHADOW}}'      "$PRIMARY_SHADOW"        "$CSS"
replace_placeholder '{{PRIMARY_SHADOW_HOVER}}' "$PRIMARY_SHADOW_HOVER" "$CSS"
replace_placeholder '{{OVERLAY_TINT}}'        "$OVERLAY_TINT"          "$CSS"

ok "style.css generated"

# --- Copy script.js ---
info "Copying script.js..."
cp "$TEMPLATE_DIR/base-script.js" "$OUTPUT_DIR/script.js"
ok "script.js copied"

# --- Git operations ---
if [[ "$NO_GIT" == "false" && "$DRY_RUN" == "false" ]]; then
  info "Git: staging changes..."
  cd "$PROJECT_ROOT"
  git add "demos/$STORE_SLUG/" 2>/dev/null || warn "git add failed (not a git repo?)"
  git commit -m "feat: add demo site for $STORE_NAME ($STORE_SLUG)" 2>/dev/null || warn "git commit failed (nothing to commit?)"
  ok "Git: committed"
fi

# --- Summary ---
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${GREEN}✅ Demo site generated successfully!${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo -e "  📁 Files:    ${CYAN}$OUTPUT_DIR/${NC}"
echo -e "  🌐 Preview:  ${CYAN}https://pagereadytw.cc/demos/$STORE_SLUG/${NC}"
echo -e "  📊 Config:   ${CYAN}$CONFIG_FILE${NC}"
echo ""

# Verify output
HTML_SIZE=$(wc -c < "$OUTPUT_DIR/index.html" | tr -d ' ')
CSS_SIZE=$(wc -c < "$OUTPUT_DIR/style.css" | tr -d ' ')
JS_SIZE=$(wc -c < "$OUTPUT_DIR/script.js" | tr -d ' ')

echo "  Files generated:"
echo -e "    index.html  ${CYAN}${HTML_SIZE} bytes${NC}"
echo -e "    style.css   ${CYAN}${CSS_SIZE} bytes${NC}"
echo -e "    script.js   ${CYAN}${JS_SIZE} bytes${NC}"
echo ""

if [[ $HTML_SIZE -lt 5000 ]]; then
  warn "index.html is smaller than 5KB — check template"
else
  ok "All files look good (index.html > 5KB)"
fi

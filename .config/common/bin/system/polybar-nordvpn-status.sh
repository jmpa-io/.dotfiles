#!/usr/bin/env bash
# This script is used to show the NordVPN connection state, and is largely used
# to display a label in polybar. It runs forever (polybar "tail" mode), so the
# globe can spin while connected.
#
# Styled like the other modules: Font Awesome icon + plain text. Polybar cannot
# draw emoji flags (it shows two big letters), so the flags are drawn as colour
# glyphs in the PolybarIcons font; countries without one lead with the code.
#
# - Connected:      spinning white globe + "[<flag> Australia]" (green name).
# - Disconnected:   white globe + bright yellow "[VPN off]".
# - Daemon down:    white globe + grey "[VPN n/a]" (not running, or not logged in).
#
# --mini shows only the icon and the flag (or "off"). Pass --once to print a single line and exit. NORDVPN_CMD,
# FRAME_DELAY (seconds) and POLL_FRAMES (frames between checks) can be overridden.

declare -A codes=(
  ["Albania"]=AL ["Algeria"]=DZ ["Andorra"]=AD ["Angola"]=AO ["Argentina"]=AR ["Armenia"]=AM
  ["Australia"]=AU ["Austria"]=AT ["Azerbaijan"]=AZ ["Bahamas"]=BS ["Bahrain"]=BH
  ["Bangladesh"]=BD ["Belgium"]=BE ["Belize"]=BZ ["Bermuda"]=BM ["Bhutan"]=BT ["Bolivia"]=BO
  ["Bosnia and Herzegovina"]=BA ["Brazil"]=BR ["Brunei Darussalam"]=BN ["Bulgaria"]=BG
  ["Cambodia"]=KH ["Canada"]=CA ["Cayman Islands"]=KY ["Chile"]=CL ["Colombia"]=CO
  ["Costa Rica"]=CR ["Croatia"]=HR ["Cyprus"]=CY ["Czech Republic"]=CZ ["Czechia"]=CZ
  ["Denmark"]=DK ["Dominican Republic"]=DO ["Ecuador"]=EC ["Egypt"]=EG ["El Salvador"]=SV
  ["Estonia"]=EE ["Finland"]=FI ["France"]=FR ["Georgia"]=GE ["Germany"]=DE ["Ghana"]=GH
  ["Greece"]=GR ["Greenland"]=GL ["Guam"]=GU ["Guatemala"]=GT ["Honduras"]=HN
  ["Hong Kong"]=HK ["Hungary"]=HU ["Iceland"]=IS ["India"]=IN ["Indonesia"]=ID ["Ireland"]=IE
  ["Isle of Man"]=IM ["Israel"]=IL ["Italy"]=IT ["Jamaica"]=JM ["Japan"]=JP ["Jersey"]=JE
  ["Kazakhstan"]=KZ ["Kenya"]=KE ["Laos"]=LA ["Latvia"]=LV ["Lebanon"]=LB ["Liechtenstein"]=LI
  ["Lithuania"]=LT ["Luxembourg"]=LU ["Malaysia"]=MY ["Malta"]=MT ["Mexico"]=MX
  ["Moldova"]=MD ["Monaco"]=MC ["Mongolia"]=MN ["Montenegro"]=ME ["Morocco"]=MA
  ["Myanmar"]=MM ["Nepal"]=NP ["Netherlands"]=NL ["New Zealand"]=NZ ["Nigeria"]=NG
  ["North Macedonia"]=MK ["Norway"]=NO ["Pakistan"]=PK ["Panama"]=PA ["Papua New Guinea"]=PG
  ["Paraguay"]=PY ["Peru"]=PE ["Philippines"]=PH ["Poland"]=PL ["Portugal"]=PT
  ["Puerto Rico"]=PR ["Romania"]=RO ["Senegal"]=SN ["Serbia"]=RS ["Singapore"]=SG
  ["Slovakia"]=SK ["Slovenia"]=SI ["South Africa"]=ZA ["South Korea"]=KR ["Spain"]=ES
  ["Sri Lanka"]=LK ["Sweden"]=SE ["Switzerland"]=CH ["Taiwan"]=TW ["Thailand"]=TH
  ["Trinidad and Tobago"]=TT ["Tunisia"]=TN ["Turkey"]=TR ["Ukraine"]=UA
  ["United Arab Emirates"]=AE ["United Kingdom"]=GB ["United States"]=US ["Uruguay"]=UY
  ["Uzbekistan"]=UZ ["Venezuela"]=VE ["Vietnam"]=VN
)

# Countries that have a colour flag in the PolybarIcons font (see FLAGS in bin/build-polybar-icons.py).
flagCodes=" AR AT AU BE BG BR CA CH DE DK EE ES FI FR GB HK HU IE IN IT JP LT LU MX NL NO NZ PL RO SE SG UA US "

# flag CODE -> the flag glyph in the icon font (U+F0000 + 26 * first letter + second letter).
flagGlyph() {
  local a b h
  a=$(($(printf '%d' "'${1:0:1}") - 65)) b=$(($(printf '%d' "'${1:1:1}") - 65))
  printf -v h '\\U%08x' $((0xF0000 + a * 26 + b))
  printf '%b' "$h"
}

# refresh sets $state ("connected"/"off"/"na"), $place (country) and $flag (glyph, may be empty).
refresh() {
  local out status country city
  out=$(timeout 3 "${NORDVPN_CMD:-nordvpn}" status 2>&1) || true
  status=$(sed -nE 's/^[[:space:]]*Status:[[:space:]]*(.*)$/\1/p' <<<"$out" | head -1)
  case "$status" in
    "") state=na; place="" ;;
    Connected)
      state=connected
      country=$(sed -nE 's/^[[:space:]]*Country:[[:space:]]*(.*)$/\1/p' <<<"$out" | head -1)
      city=$(sed -nE 's/^[[:space:]]*City:[[:space:]]*(.*)$/\1/p' <<<"$out" | head -1)
      place="${country:-${city:-connected}}"
      flag=""
      code="${codes[$country]:-}"
      if [[ -n "$code" && "$flagCodes" == *" $code "* ]]; then
        flag="$(flagGlyph "$code")"
      elif [[ -n "$code" ]]; then
        place="$code $country" # no flag drawn for this country, so lead with the code.
      fi
      ;;
    *) state=off; place="" ;;
  esac
}

# %{T6} is "PolybarIcons" (font-5 in fonts.ini): a globe drawn in 12 spin frames (U+E000-U+E00B).
render() {
  local icon="$1" tag
  if [[ "$mini" == 1 ]]; then # just the icon, and the flag (or country code) or a short state.
    case "$state" in
      connected) # the flag, or the country code when no flag is drawn for it.
        tag="$code"
        [[ -n "$flag" ]] && tag="%{T6}${flag}%{T-}"
        echo "%{T6}${icon}%{T-}  [${tag}]" ;;
      off)       echo "%{T6}${globe}%{T-}  [%{F#FFE94D}off%{F-}]" ;;
      *)         echo "%{T6}${globe}%{T-}  [%{F#6272A4}n/a%{F-}]" ;;
    esac
    return
  fi
  case "$state" in
    connected) echo "%{T6}${icon}%{T-}  [${flag:+%{T6\}${flag}%{T-\} }%{F#50FA7B}${place}%{F-}]" ;;
    off)       echo "%{T6}${globe}%{T-}  [%{F#FFE94D}VPN off%{F-}]" ;;
    *)         echo "%{T6}${globe}%{T-}  [%{F#6272A4}VPN n/a%{F-}]" ;;
  esac
}

mini=0
[[ "${1:-}" == "--mini" ]] && { mini=1; shift; }

globe=$'\ue000' # still frame.
frames=(); for i in {0..11}; do printf -v g '\\U%08x' $((0xE000 + i)); frames+=("$(printf '%b' "$g")"); done
state=na place="" flag="" code=""

if [[ "${1:-}" == "--once" ]]; then
  refresh
  render "${frames[0]}"
  exit 0
fi

n=0
while true; do
  ((n % ${POLL_FRAMES:-25} == 0)) && refresh
  render "${frames[n % ${#frames[@]}]}"
  n=$((n + 1))
  sleep "${FRAME_DELAY:-0.12}"
done

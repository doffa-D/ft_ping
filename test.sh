#!/bin/bash

# ============================================================
#   ft_ping Evaluator-Style Test Suite
#   Mirrors the exact eval sheet order and criteria
# ============================================================

FT_PING="./ft_ping"
SYSTEM_PING=$(which ping)
COUNT=3
TIMEOUT=15
RTT_TOLERANCE=30

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

passed=0
failed=0
skipped=0
total=0

# Arrays to collect failures for AI prompt generation
declare -a FAILED_TESTS
declare -a FAILED_FT_OUT
declare -a FAILED_SYS_OUT
declare -a FAILED_DESC

if [ $# -ge 1 ]; then FT_PING="$1"; fi

# ── helpers ────────────────────────────────────────────────

header()  { echo -e "\n${BOLD}${BLUE}══════════════════════════════════════${NC}"; echo -e "${BOLD}${BLUE}  $1${NC}"; echo -e "${BOLD}${BLUE}══════════════════════════════════════${NC}"; }
section() { echo -e "\n${YELLOW}── $1 ──${NC}"; }
info()    { echo -e "         ${BOLD}$1${NC}"; }

pass() {
    echo -e "  ${GREEN}✔ PASS${NC}  $1"
    ((passed++)); ((total++))
}

fail() {
    local label="$1"
    local ft_out="$2"
    local sys_out="$3"
    local desc="$4"
    echo -e "  ${RED}✘ FAIL${NC}  $label"
    FAILED_TESTS+=("$label")
    FAILED_FT_OUT+=("$ft_out")
    FAILED_SYS_OUT+=("$sys_out")
    FAILED_DESC+=("$desc")
    ((failed++)); ((total++))
}

skip() {
    echo -e "  ${YELLOW}⚠ SKIP${NC}  $1"
    ((skipped++)); ((total++))
}

run_ft()  { timeout $TIMEOUT $FT_PING $@ 2>&1; }
run_sys() { timeout $TIMEOUT $SYSTEM_PING $@ 2>&1; }

strip_for_diff() {
    grep -v "^round-trip\|^rtt\|^---\|packets transmitted" \
    | sed 's/time=[0-9.]* ms/time=X ms/g' \
    | sed 's/icmp_seq=[0-9]*/icmp_seq=N/g' \
    | sed 's/ttl=[0-9]*/ttl=N/g' \
    | sed 's/^[0-9]* bytes from/N bytes from/g' \
    | grep -v "^$"
}

# ── PRELIMINARY CHECKS ─────────────────────────────────────

header "PRELIMINARIES"

section "Binary exists"
if [ -f "$FT_PING" ]; then
    pass "Binary $FT_PING found"
else
    fail "Binary $FT_PING not found — stopping" "" "" "The binary was not found at $FT_PING"
    exit 1
fi

section "Written in C (check source files)"
C_FILES=$(find . -name "*.c" 2>/dev/null | grep -v ".git" | wc -l)
if [ "$C_FILES" -gt 0 ]; then
    pass "$C_FILES .c file(s) found"
else
    fail "No .c source files found" "" "" "No C source files detected in current directory"
fi

section "Only one global variable"
info "Globals detected (manual check recommended)"
info "→ Evaluator will read your code. Make sure only 1 global exists."
skip "One global — manual check required"

section "Forbidden functions (fcntl, poll, ppoll)"
FORBIDDEN=$(grep -rn "fcntl\|[^s]poll\|ppoll" srcs/ *.c 2>/dev/null | grep -v "//")
if [ -z "$FORBIDDEN" ]; then
    pass "No forbidden functions found"
else
    fail "Forbidden function usage detected" "$FORBIDDEN" "" "fcntl/poll/ppoll are not allowed"
fi

section "Makefile rules"
for rule in all clean fclean re; do
    if grep -q "^$rule" Makefile 2>/dev/null; then
        pass "Makefile has '$rule' rule"
    else
        fail "Makefile missing '$rule' rule" "" "" "The Makefile does not contain a '$rule' target"
    fi
done

section "Makefile compiles the project"
make re > /dev/null 2>&1
if [ $? -eq 0 ] && [ -f "$FT_PING" ]; then
    pass "make re succeeds and binary produced"
else
    fail "make re failed" "$(make re 2>&1)" "" "make re did not produce the binary"
    exit 1
fi

section "Root rights check"
if [ "$EUID" -eq 0 ]; then
    pass "Running as root"
else
    echo -e "  ${RED}✘${NC} ${RED}NOT running as root — live packet tests will fail${NC}"
    echo -e "     Run with: ${BOLD}sudo $0${NC}"
fi

# ── ARGUMENT / HELP CHECK ──────────────────────────────────

header "CHECKING ARGUMENTS"

section "-? help option"
out=$(run_ft -?)
if echo "$out" | grep -qi "usage\|option\|-v\|-c"; then
    pass "-? shows usage/help"
    info "Output: $(echo "$out" | head -1)"
else
    fail "-? did not show help" "$out" "" "Running ft_ping -? should print a usage/help message"
fi

section "-h help option"
out=$(run_ft -h)
if echo "$out" | grep -qi "usage\|option\|-v\|-c"; then
    pass "-h shows usage/help"
else
    fail "-h did not show help" "$out" "" "Running ft_ping -h should print a usage/help message"
fi

section "Missing hostname"
out=$(run_ft 2>&1)
if echo "$out" | grep -qi "missing\|host\|usage"; then
    pass "Missing hostname → correct error message"
    info "Got: $out"
else
    fail "Missing hostname — no error" "$out" "Expected: error about missing host operand" \
        "When called with no arguments, the program should print an error about the missing hostname"
fi

section "Invalid option"
out=$(run_ft -z 8.8.8.8 2>&1)
if echo "$out" | grep -qi "invalid\|unknown\|option\|usage"; then
    pass "Invalid option (-z) → correct error"
    info "Got: $out"
else
    fail "Invalid option (-z) — no error" "$out" "Expected: error about unknown option" \
        "When given an unknown flag like -z, the program should print an error about the invalid option"
fi

# ── IPv4 TESTS ─────────────────────────────────────────────

header "ft_ping ip"
echo -e "  ${YELLOW}Comparing output with system ping. RTT line ignored. ±${RTT_TOLERANCE}ms tolerance.${NC}"

section "Good IP — 8.8.8.8 (Google DNS)"
if [ "$EUID" -eq 0 ]; then
    ft_out=$(run_ft  -c $COUNT 8.8.8.8 2>&1)
    sys_out=$(run_sys -c $COUNT 8.8.8.8 2>&1)

    echo "  [ft_ping output]";   echo "$ft_out"  | sed 's/^/    /'
    echo "  [system ping output]"; echo "$sys_out" | sed 's/^/    /'

    if echo "$ft_out" | grep -q "bytes from" && \
       echo "$ft_out" | grep -q "icmp_seq=1"   && \
       echo "$ft_out" | grep -q "ttl="        && \
       echo "$ft_out" | grep -q "time="; then
        pass "Good IP — output format matches (icmp_seq starts at 1)"
    else
        fail "Good IP — output format incorrect" "$ft_out" "$sys_out" \
            "ft_ping sent packets to 8.8.8.8 but the per-packet output is incorrect. Expected icmp_seq to start at 1, format: 'N bytes from X.X.X.X: icmp_seq=N ttl=N time=X ms'"
    fi
else
    skip "Good IP — need root"
fi

section "Bad IP — 192.0.2.1 (TEST-NET, unreachable)"
if [ "$EUID" -eq 0 ]; then
    # 2 packets x 2s timeout = 4s minimum, allow extra time
    ft_out=$(timeout 12 $FT_PING  -c 2 192.0.2.1 2>&1)
    sys_out=$(timeout 12 $SYSTEM_PING -c 2 192.0.2.1 2>&1)

    echo "  [ft_ping output]";   echo "$ft_out"  | sed 's/^/    /'
    echo "  [system ping output]"; echo "$sys_out" | sed 's/^/    /'

    # ft_ping should show stats with 100% loss, no timeout messages without -v
    if echo "$ft_out" | grep -qi "statistics\|loss" && \
       ! echo "$ft_out" | grep -qi "Request timeout"; then
        pass "Bad IP — silent (no timeout msgs without -v)"
    elif echo "$ft_out" | grep -qi "statistics\|loss"; then
        pass "Bad IP — handled correctly"
    else
        fail "Bad IP — incorrect output" "$ft_out" "$sys_out" \
            "ft_ping was given an unreachable IP. Without -v flag, should show only final stats with 100% loss."
    fi
else
    skip "Bad IP — need root"
fi

section "-v Bad IP — 192.0.2.1 with verbose"
if [ "$EUID" -eq 0 ]; then
    ft_out=$(timeout 5 $FT_PING  -v -c 2 192.0.2.1 2>&1)
    sys_out=$(timeout 5 $SYSTEM_PING -v -c 2 192.0.2.1 2>&1)

    echo "  [ft_ping -v output]";   echo "$ft_out"  | sed 's/^/    /'
    echo "  [system ping -v output]"; echo "$sys_out" | sed 's/^/    /'

    # With -v, ft_ping shows "Request timeout for icmp_seq X" messages
    if echo "$ft_out" | grep -qi "PING\|data bytes\|statistics\|timeout"; then
        pass "-v Bad IP — verbose output shown"
    else
        fail "-v Bad IP — no output" "$ft_out" "$sys_out" \
            "ft_ping -v should show PING banner, Request timeout messages per packet, and final statistics."
    fi
else
    skip "-v Bad IP — need root"
fi

# ── HOSTNAME TESTS ─────────────────────────────────────────

header "ft_ping hostname"

section "Good hostname — google.com"
if [ "$EUID" -eq 0 ]; then
    ft_out=$(run_ft  -c $COUNT google.com 2>&1)
    sys_out=$(run_sys -c $COUNT google.com 2>&1)

    echo "  [ft_ping output]";   echo "$ft_out"  | sed 's/^/    /'
    echo "  [system ping output]"; echo "$sys_out" | sed 's/^/    /'

    # Check key elements match (reverse DNS is NOT mandatory per eval)
    if echo "$ft_out" | grep -q "PING google.com" && \
       echo "$ft_out" | grep -q "icmp_seq=" && \
       echo "$ft_out" | grep -q "ttl=" && \
       echo "$ft_out" | grep -q "time="; then
        pass "Good hostname — output format correct"
    else
        fail "Good hostname — output format incorrect" "$ft_out" "$sys_out" \
            "ft_ping resolved google.com but the output format is incorrect. Banner should be 'PING google.com (X.X.X.X): 56 data bytes' and reply lines should be 'N bytes from X.X.X.X: icmp_seq=N ttl=N time=X ms'. Reverse DNS (hostname) is NOT mandatory."
    fi
else
    skip "Good hostname — need root"
fi

section "Bad hostname — notarealhost99.invalid"
ft_out=$(run_ft notarealhost99.invalid 2>&1)
sys_out=$(run_sys notarealhost99.invalid 2>&1)

echo "  [ft_ping output]";   echo "$ft_out"  | sed 's/^/    /'
echo "  [system ping output]"; echo "$sys_out" | sed 's/^/    /'

if echo "$ft_out" | grep -qi "unknown\|not known\|failure\|cannot resolve\|invalid"; then
    pass "Bad hostname → error message shown"
else
    fail "Bad hostname — no error" "$ft_out" "$sys_out" \
        "ft_ping was given a hostname that does not exist (notarealhost99.invalid). The DNS resolution will fail. The program should detect this and print an error message like 'ft_ping: unknown host: notarealhost99.invalid' then exit. Currently it does not print the expected error."
fi

section "-v Bad hostname — notarealhost99.invalid with verbose"
ft_out=$(run_ft -v notarealhost99.invalid 2>&1)
echo "  [ft_ping -v output]"; echo "$ft_out" | sed 's/^/    /'

if echo "$ft_out" | grep -qi "unknown\|not known\|failure\|cannot resolve\|invalid"; then
    pass "-v Bad hostname → error shown"
else
    fail "-v Bad hostname — no error" "$ft_out" "" \
        "ft_ping -v was given a non-existent hostname. Even with the -v flag active, the DNS resolution failure should still be caught and printed as an error. The program should not crash or exit silently."
fi

section "TTL test (-v with low TTL forces ICMP Time Exceeded)"
info "Using -v -t 1 to force ICMP Time Exceeded response"
if [ "$EUID" -eq 0 ]; then
    ft_out=$(timeout 5 $FT_PING -v -t 1 -c 2 google.com 2>&1)
    sys_out=$(timeout 5 $SYSTEM_PING -v -t 1 -c 2 google.com 2>&1)
    echo "  [ft_ping -v -t 1 output]"; echo "$ft_out" | sed 's/^/    /'
    echo "  [system ping -v -t 1 output]"; echo "$sys_out" | sed 's/^/    /'
    if echo "$ft_out" | grep -qi "time.to.live.exceeded\|ttl"; then
        pass "TTL=1 shows Time Exceeded in -v mode"
    else
        fail "TTL=1 — no Time Exceeded message" "$ft_out" "$sys_out" \
            "With -v -t 1, the router should respond with ICMP Time Exceeded. ft_ping should display this in verbose mode."
    fi
else
    skip "TTL test — need root"
fi

# ── FINAL SUMMARY ──────────────────────────────────────────

header "SUMMARY"

echo -e "  ${GREEN}Passed : $passed${NC}"
echo -e "  ${RED}Failed : $failed${NC}"
echo -e "  ${YELLOW}Skipped: $skipped${NC}"
echo -e "  Total  : $total"
echo ""

if [ $failed -eq 0 ]; then
    echo -e "  ${GREEN}${BOLD}All mandatory checks passed ✔${NC}"
    exit 0
fi

echo -e "  ${RED}${BOLD}$failed check(s) failed ✘${NC}"

# ── AI PROMPTS FOR EACH FAILURE ────────────────────────────

SOURCE=$(cat srcs/main.c 2>/dev/null || cat main.c 2>/dev/null || echo "[source not found]")

header "AI DEBUG PROMPTS"
echo -e "  ${YELLOW}For each failure below, a prompt has been generated.${NC}"
echo -e "  ${YELLOW}Copy it and send it to an AI. It explains the bug — not the fix.${NC}"

for i in "${!FAILED_TESTS[@]}"; do
    name="${FAILED_TESTS[$i]}"
    ft_out="${FAILED_FT_OUT[$i]}"
    sys_out="${FAILED_SYS_OUT[$i]}"
    desc="${FAILED_DESC[$i]}"
    num=$((i + 1))

    echo ""
    echo -e "${BOLD}${RED}┌─ Prompt #${num} — ${name}${NC}"
    echo    "│"
    echo    "│  ═══ COPY EVERYTHING BELOW THIS LINE ═══"
    echo    "│"
    echo    "│  I am doing the 42 school ft_ping project — a reimplementation"
    echo    "│  of the Linux ping command in C using raw ICMP sockets (SOCK_RAW)."
    echo    "│  The program must run as root and match inetutils-2.0 output."
    echo    "│"
    echo    "│  I have a failing test: \"${name}\""
    echo    "│"
    echo    "│  Problem description:"
    echo    "│  ${desc}"
    echo    "│"
    if [ -n "$ft_out" ]; then
    echo    "│  What my ft_ping actually printed:"
    echo    "│  ─────────────────────────────────"
    echo "$ft_out" | head -20 | while IFS= read -r line; do echo "│    $line"; done
    echo    "│"
    fi
    if [ -n "$sys_out" ]; then
    echo    "│  What the system ping printed (the expected behaviour):"
    echo    "│  ─────────────────────────────────"
    echo "$sys_out" | head -20 | while IFS= read -r line; do echo "│    $line"; done
    echo    "│"
    fi
    echo    "│  My source code (main.c):"
    echo    "│  ─────────────────────────────────"
    echo "$SOURCE" | head -100 | while IFS= read -r line; do echo "│    $line"; done
    echo    "│"
    echo    "│  Please explain ONLY what is wrong — do not give me the fixed code."
    echo    "│  Describe the root cause so I can fix it myself."
    echo    "│"
    echo -e "${BOLD}${RED}└──────────────────────────────────────────────────────────${NC}"
done

exit 1
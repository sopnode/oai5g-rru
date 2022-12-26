# run the script with various combinations of options
# and produce an svg for visual inspection
function store-svg() {
    local name=test-logic--"$1"; shift
    local svg=${name}.svg
    [[ -f $svg ]] && { echo $svg already present - skipped ; return 0; }
    [[ -n "$DRY_RUN" ]] && { echo would update $svg from options "$@"; return 0; }
    echo "==============================" RUNNING with options "$@"
    python -u ./demo-oai.py --devel -n -v "$@"
    rm demo-oai-graph.dot
    mv demo-oai-graph.svg $svg
    echo "===============" DONE $svg from options "$@"
}

function tests-basic() {
    store-svg "plain"
    store-svg "plain-load" -l
    store-svg "plain-noauto" -a
    store-svg "plain-start" --start
    store-svg "plain-stop" --stop
    store-svg "plain-cleanup" --cleanup
    store-svg "plain-load-noauto" -l -a
    store-svg "plain-nok8reset" -k
    store-svg "plain-load-nok8reset" -l -k
}

# with quectel selected
function tests-quectel() {
    store-svg "quectel1-load" -l -Q 18
    store-svg "quectel2-load" -l -Q 18 -Q 32
    store-svg "quectel1" -Q 18
    store-svg "quectel2" -Q 18 -Q 32
    store-svg "quectel1-noauto"  -Q 18 -a
    store-svg "quectel1-start" -Q 18 --start
    store-svg "quectel1-stop" -Q 18 --stop
    store-svg "quectel1-cleanup" -Q 18 --cleanup
    store-svg "quectel2-start" -Q 18 -Q 32 --start
    store-svg "quectel2-stop" -Q 18 -Q 32 --stop
    store-svg "quectel2-cleanup" -Q 18 -Q 32 --cleanup
    store-svg "quectel1-nok8reset" -Q 18 -k
}

default_steps="tests-basic tests-quectel"

if [[ -n "$@" ]]; then
    steps="$@"
else
    steps="$default_steps"
fi

for step in $steps; do
    $step
done

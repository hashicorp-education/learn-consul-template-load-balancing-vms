#!/usr/bin/env bash

# ++-----------------+
# || Functions       |
# ++-----------------+

_check_value_in_range() {
    _value=$1
    _min_value=$2
    _max_value=$3

    if (( "${_min_value}" <= "${_max_value}")); then
        if (( "${_value}" >= "${_min_value}")); then
            if (( "${_value}" <= "${_max_value}")); then
                # Value in range
                echo 0
            else
                # Value too big
                echo 2
            fi
        else
            # Value too small
            echo 1
        fi
    else
        # Ranges are wrong MAX < MIN
        echo 3
    fi
}

# ++-----------------+
# || Variables       |
# ++-----------------+

export STEP_ASSETS="${SCENARIO_OUTPUT_FOLDER}conf/"

# ++-----------------+
# || Begin           |
# ++-----------------+

# header1 "Monitor your application health with distributed checks"

## Validate scenario can contain tests that can be used to verify soluton was applied correctly.
## ATM all tests are inside the `solve_scenario.sh` script but it is possible to split them.
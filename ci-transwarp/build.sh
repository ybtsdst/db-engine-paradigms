#!/bin/bash
#!/bin/bash

common_build_args="
  --network=host
"

function image_suffix {
  commit=$(git rev-parse --short HEAD)
  current_date=$(date +%Y%m%d)

  echo "${current_date}_${commit}"

  unset commit
  unset current_date
}

# run this under project root directory
function build_dev_image {
  tag=$(image_suffix)

  build_args="
    ${common_build_args}
  "

  docker build \
    ${build_args} \
    -t db_engine_paradigms_build:${tag} \
    -f ci-transwarp/Dockerfile.dev \
    ci-transwarp

  unset tag
  unset build_args
}

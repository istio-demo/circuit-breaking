#!/usr/bin/env bash

set -x

export FORTIO_POD=$(kubectl get pods -l app=fortio -o 'jsonpath={.items[0].metadata.name}')
kubectl exec "$FORTIO_POD" -c fortio -- /usr/bin/fortio load -c $1 -qps 0 -n 200 -loglevel Warning http://httpbin:8000/get

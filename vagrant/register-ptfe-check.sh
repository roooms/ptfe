#!/bin/sh

curl --request PUT --data @ptfe-check.json http://localhost:8500/v1/agent/service/register

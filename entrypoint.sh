#!/bin/bash

envsubst '$BASE_URL:$SHOW_ID' < public/index.template.html > public/index.html
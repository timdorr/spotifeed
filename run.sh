#!/bin/sh
envsubst '$BASE_URL:$SHOW_ID' < public/index.template.html > public/index.html
bundle exec puma -p $PORT -e production
#!/usr/bin/env bash
#  anki.sh
#  Created by cdpath on 2018/4/19.
#  Copyright © 2018 cdpath. All rights reserved.

set -e

entry=$POPCLIP_TEXT
safe_entry=$POPCLIP_URLENCODED_TEXT
dict_svc=$POPCLIP_OPTION_DICT_SVC
target_deck=$POPCLIP_OPTION_TARGET_DECK
tag="PopClip"
app_tag=${POPCLIP_APP_NAME// /_} # replace spaces with underscore

#  debug
#  entry='debug'
#  dict_svc='youdao'
#  gubed


_shanbay()
{
    url="https://api.shanbay.com/bdc/search/?word=$safe_entry"
#    url="$(echo "${url}" | tr -d '[:space:]')"
    curl -sSL $url \
    | grep -Eo '"definition":.*?[^\\]",' \
    | cut -d: -f 2 | tr -d '"' \
    | sed -e 's/,$//g' \
    | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'
}


_youdao()
{
    url="http://dict.youdao.com/m/search?q=$safe_entry"
    curl -sSL $url \
    | sed -ne '/网络释义/,/更多释义/p' \
    | grep '<li>' \
    | sed -e 's/<[^>]*>//g' \
    | awk 'ORS="<br>"'
}


look_up()
{
    if [ "$dict_svc" = "shanbay" ]
    then
        _shanbay
    elif [ "$dict_svc" = "youdao" ]
    then
        _youdao
    else
        echo "Not Implemented"
        exit 1
    fi
}


gen_post_data()
{
  cat <<EOF
{
  "action": "addNote",
  "version": 5,
  "params": {
    "note": {
      "fields": {
        "Front": "$entry",
        "Back": "$(look_up)"
      },
      "modelName": "Basic",
      "deckName": "$target_deck",
      "tags": [
        "$tag",
        "$app_tag"
      ]
    }
  }
}
EOF
}
    

curl -X POST -d "$(gen_post_data)" "localhost:8765"


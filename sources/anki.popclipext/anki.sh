#!/usr/bin/env bash
#  anki.sh
#  Created by cdpath on 2018/4/19.
#  Copyright © 2018 cdpath. All rights reserved.

set -xeuo pipefail


## PopClip Env
entry=$POPCLIP_TEXT
safe_entry=$POPCLIP_URLENCODED_TEXT
dict_svc=$POPCLIP_OPTION_DICT_SVC
target_deck=$POPCLIP_OPTION_TARGET_DECK
note_type=$POPCLIP_OPTION_NOTE_TYPE
tag="PopClip"
app_tag=${POPCLIP_APP_NAME// /_} # replace spaces with underscore


## cocoaDialog
dialog() {
    ./dialog/Contents/MacOS/cocoaDialog bubble \
        --title "$1" \
        --text "$2" \
        --timeout "$3" \
        --icon-file anki.png
}


## Dictionary Services
_shanbay()
{
    url="https://api.shanbay.com/bdc/search/?word=$safe_entry"
    local definition=$(curl -sSL $url | perl -pe 's/^.*?(?<="definition":)(.*?[^\\]")(?=\,).*?$/$1/' | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' -e 's/^"//' -e 's/"$//')
    if [[ $definition = *'"status_code": 1'* ]]; then
        echo ''
    else
        echo ${definition//\\n/<br>}
    fi
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
    local definition=''
    if [ "$dict_svc" = "shanbay" ]
    then
        definition=$(_shanbay)
    elif [ "$dict_svc" = "youdao" ]
    then
        definition=$(_youdao)
    else
        echo "Not Implemented"
        exit 1
    fi

    if [[ -z "$definition" ]]; then
        dialog "$dict_svc" "未找到单词" 3
        exit 1
    else
        echo $definition
    fi
}


## AnkiConnect
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
      "modelName": "$note_type",
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

check_result()
{
    if [[ $1 != *'"error": null'* ]]; then
        if [[ $1 = "null" ]]; then
            msg="Invalid post data for AnkiConnect"
        else
            msg=$(echo "$1" | perl -pe 's/^.*?(?<="error": ")(.*?[^\\])(?=[\."]).*?$/$1/' | sed -e 's/^"//' -e 's/"$//')
        fi
        if [[ -z "$1" ]]; then
            msg="Did you open anki?"
        fi
        dialog "AnkiConnect" "$msg" 5
    fi
}


## main
main()
{
    local res=$(curl -X POST -d "$(gen_post_data)" "localhost:8765")
    check_result "$res"
}


main


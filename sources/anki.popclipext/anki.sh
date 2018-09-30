#!/usr/bin/env bash
#  anki.sh
#  Created by cdpath on 2018/4/19.
#  Copyright © 2018 cdpath. All rights reserved.

#set -xeuo pipefail


## PopClip Env
entry=${POPCLIP_TEXT:-debug}
safe_entry=${POPCLIP_URLENCODED_TEXT:-debug}
dict_service=${POPCLIP_OPTION_DICT_SVC:-shanbay}
target_deck=${POPCLIP_OPTION_TARGET_DECK:-Default}
note_type=${POPCLIP_OPTION_NOTE_TYPE:-Basic}
front_field=${POPCLIP_OPTION_FRONT_FIELD:-Front}
back_field=${POPCLIP_OPTION_BACK_FIELD:-Back}
tag=${POPCLIP_OPTION_TAG:-debug}
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
    local safe_entry=$1
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
    local safe_entry=$1
    url="http://dict.youdao.com/m/search?q=$safe_entry"
    curl -sSL $url \
    | sed -ne '/网络释义/,/更多释义/p' \
    | grep '<li>' \
    | sed -e 's/<[^>]*>//g' \
    | awk 'ORS="<br>"'
}

look_up()
{
    local safe_entry=$1
    if [ "$dict_service" = "shanbay" ]
    then
        definition=$(_shanbay $safe_entry)
    elif [ "$dict_service" = "youdao" ]
    then
        definition=$(_youdao $safe_entry)
    else
        definition=''
        echo "Not Implemented"
        exit 1
    fi

    if [[ -z "$definition" ]]; then
        dialog "$dict_service" "未找到单词" 3
        exit 1
    else
        echo $definition
    fi
}


## AnkiConnect
gen_post_data()
{
    local definition=$1
    cat <<EOF
{
  "action": "addNote",
  "version": 5,
  "params": {
    "note": {
      "fields": {
        "$front_field": "$entry",
        "$back_field": "$definition"
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
    local resp=$1
    local definition=$2
    if [[ $resp != *'"error": null'* ]]; then
        if [[ $resp = "null" ]]; then
            msg="Invalid post data for AnkiConnect"
        else
            msg=$(echo "$resp" | perl -pe 's/^.*?(?<="error": ")(.*?[^\\])(?=[\."]).*?$/$1/' | sed -e 's/^"//' -e 's/"$//')
        fi
        if [[ -z "$resp" ]]; then
            msg="Did you open anki?"
        fi
        dialog "AnkiConnect" "$msg" 5
    else
        dialog "$entry" "Saved to $target_deck" 5
    fi
}


## main
main()
{
    local definition=$(look_up $safe_entry)
    payload=$(gen_post_data "$definition")
    res=$(curl -sX POST -d "$payload" "localhost:8765")
    check_result "$res" "$definition"
}


main


#!/usr/bin/env bash
#  anki.sh
#  Created by cdpath on 2018/4/19.
#  Copyright © 2018 cdpath. All rights reserved.

#set -xeuo pipefail


## PopClip Env
entry=${POPCLIP_TEXT:-debug}
safe_entry=${POPCLIP_URLENCODED_TEXT:-debug}
dict_service=${POPCLIP_OPTION_DICT_SVC:-caiyun}
target_deck=${POPCLIP_OPTION_TARGET_DECK:-Default}
note_type=${POPCLIP_OPTION_NOTE_TYPE:-Basic}
front_field=${POPCLIP_OPTION_FRONT_FIELD:-Front}
back_field=${POPCLIP_OPTION_BACK_FIELD:-Back}
source_field=${POPCLIP_OPTION_SOURCE_FIELD:-Source}
tag=${POPCLIP_OPTION_TAG:-debug}
app_tag=${POPCLIP_APP_NAME// /_} # replace spaces with underscore
api_token=${POPCLIP_OPTION_API_TOKEN}


## Dictionary Services
_caiyun()
{
    local safe_entry=$1
    url="http://api.interpreter.caiyunai.com/v1/translator"
    DIRECTION="en2zh"
    BODY='{"source": ["'$safe_entry'"], "trans_type": "'$DIRECTION'", "replaced": true, "media": "text"}'
 
    curl -sSL -XPOST $url \
         -H 'Content-Type: application/json' \
         -H "X-Authorization: token $api_token" \
         -d "$BODY" | python3 -c "import sys, json; print(json.load(sys.stdin)['target'][0])"

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
    if [ "$dict_service" = "caiyun" ]
    then
        definition=$(_caiyun "$safe_entry")
    elif [ "$dict_service" = "youdao" ]
    then
        definition=$(_youdao "$safe_entry")
    else
        definition=''
        echo "API Not Implemented"
        exit 1
    fi

    if [[ -z "$definition" ]]; then
        echo "Word Not Found"
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
        "$back_field": "$definition",
        "$source_field": "<a href=\"${POPCLIP_BROWSER_URL}\">${POPCLIP_BROWSER_TITLE}</a>"
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
        exit 2
    else
        exit 0
    fi
}


## main
main()
{
    local definition
    definition=$(look_up $safe_entry) || exit 1
    payload=$(gen_post_data "$definition")
    res=$(curl -sX POST -d "$payload" "localhost:8765")
    check_result "$res" "$definition"
}


main


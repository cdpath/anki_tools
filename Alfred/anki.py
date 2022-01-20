#!/usr/bin/python
# encoding: utf-8

import sys
import json

from workflow.notify import notify
from workflow import Workflow3, web


## AnkiConnect ##
def findCards_(query):
    return {
        "action": "findCards",
        "version": 6,
        "params": {
          "query": query
        }
    }


def cardsInfo_(card_ids):
    return {
        "action": "cardsInfo",
        "version": 6,
        "params": {
            "cards": card_ids
        }
    }


def invoke(j):
    res = web.post(
        "http://localhost:8765",
        data=json.dumps(j)
    ).json()
    if res["error"]:
        notify("AnkiConnect Error", json.dumps(res)[:20])
    return res["result"]


def search_in_anki(q):
    card_ids = invoke(findCards_(q))
    card_ids = card_ids[:8]
    cards = invoke(cardsInfo_(card_ids))
    return cards


def extract_field(card, field_name):
    return card["fields"][field_name]["value"]


def main(wf):
    args, field_name = wf.args
    try:
        cards = search_in_anki(args)
    except Exception as e:
        notify("Did you opened Anki?", "open it!")

    for card in cards:
        try:
            title = extract_field(card, field_name)
        except KeyError:
            continue
        else:
            wf.add_item(title, card["cardId"], valid=True, arg=card["cardId"])
    wf.send_feedback()


if __name__ == '__main__':
    wf = Workflow3()
    wf.run(main)

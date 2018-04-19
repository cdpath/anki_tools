#!/usr/bin/python
# -*- coding: utf-8 -*-
import csv
import sys

import requests
from bs4 import BeautifulSoup

reload(sys)
sys.setdefaultencoding('utf8')

target_classes = [
    'wotd-word',
    'wotd-pronunciation',
    'wotd-function',
    'wotd-passage',
    'wotd-definition',
    'wotd-synonyms',
    'wotd-source',
    'wotd-published'
]


def fetch_data(url):
    resp = requests.get(url)
    if not resp.ok:
        resp.raise_for_status()
    return BeautifulSoup(resp.content, 'html.parser')


def update_urls():
    soup = fetch_data('https://gre.economist.com/gre-vocabulary')
    hrefs = soup.find_all('a', class_=['wotd-view-link', 'wotd-teaser-stub'])
    return ["https://gre.economist.com%s" % h['href'] for h in hrefs]


def parse_data(soup):
    article = soup.find('article')
    tags = article.find_all(class_=target_classes)
    result = {}
    for tag in tags:
        if tag.has_attr('class'):
            k = tag.attrs['class'][0]
            if k == 'wotd-source':
                # reserve href for source
                v = str(tag.contents[1])
            else:
                v = tag.text
            result[k] = v
    return result


def write_csv(output_f):
    with open(output_f, 'w') as f:
        csv_writer = csv.writer(f)
        for url in update_urls():
            print("Working on %s" % url)
            soup = fetch_data(url)
            word_info = parse_data(soup)
            row = [word_info.get(k) for k in target_classes]
            row = [i.strip() if i is not None else i for i in row]
            csv_writer.writerow(row)


def main():
    try:
        output_filename = sys.argv[1]
    except IndexError:
        output_filename = './economist_gre_vocab.py'
        print("Save to ./economist_gre_vocab.py")
    write_csv(output_filename)


if __name__ == '__main__':
    main()

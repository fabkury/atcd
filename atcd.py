import requests
from bs4 import BeautifulSoup
import pandas as pd
import numpy as np
import os
import re
import csv
import sys
from io import StringIO
from time import sleep

sys.setrecursionlimit(10000)

def ensure_directory(dir_path):
    if not os.path.exists(dir_path):
        os.makedirs(dir_path)
    return dir_path

out_dir = ensure_directory('output')

atc_roots = ['A', 'B', 'C', 'D', 'G', 'H', 'J', 'L', 'M', 'N', 'P', 'R', 'S', 'V']

atc_code_pattern = re.compile(r'(^[A-Z]$)|(^[A-Z][^a-z][0-9]{1,2}$)|(^[A-Z][^a-z][0-9]{1,2}[A-Z]{1,2}$)|(^[A-Z][^a-z][0-9]{1,2}[A-Z]{1,2}[0-9]{1,2}$)')

def is_valid_atc_code(code):
    return bool(atc_code_pattern.match(code))

def scrape_who_atc(root_atc_code, writer, f_out):
    """
    Scrapes https://atcddd.fhi.no/atc_ddd_index/ for the given ATC code and
    all its subcodes, writing rows to the given csv.writer.
    """
    if not is_valid_atc_code(root_atc_code):
        return

    web_address = 'https://atcddd.fhi.no/atc_ddd_index/?code={}&showdescription=no'.format(root_atc_code)
    print('Scraping', web_address)
    atc_code_length = len(root_atc_code)
    sleep(0.5)
    response = requests.get(web_address)
    if response.status_code != 200:
        print('Error fetching', web_address)
        return
    soup = BeautifulSoup(response.content, 'html.parser')

    if atc_code_length < 5:
        if atc_code_length == 1:
            root_atc_code_name_elements = soup.select('#content a')
            if len(root_atc_code_name_elements) >= 3:
                root_atc_code_name = root_atc_code_name_elements[2].get_text()
            else:
                root_atc_code_name = ''
            writer.writerow([root_atc_code, root_atc_code_name, '', '', '', ''])

        content_p = soup.select_one('#content > p:nth-of-type(2n)')
        if content_p is None:
            return
        scraped_strings = [s.strip() for s in content_p.get_text().split('\n') if s.strip()]
        if not scraped_strings:
            return

        for scraped_string in scraped_strings:
            match = re.match(r'^(\S+)\s+(.*)$', scraped_string)
            if not match:
                continue
            atc_code = match.group(1)
            atc_name = match.group(2)
            if not is_valid_atc_code(atc_code):
                continue
            writer.writerow([atc_code, atc_name, '', '', '', ''])
            f_out.flush()
            scrape_who_atc(atc_code, writer, f_out)
    else:
        table = soup.select_one('ul > table')
        if table is None:
            return
        df_list = pd.read_html(StringIO(str(table)), header=0)
        if not df_list:
            return
        df = df_list[0]
        df = df.rename(columns={'ATC code': 'atc_code', 'Name': 'atc_name', 'DDD': 'ddd',
                                'U': 'uom', 'Adm.R': 'adm_r', 'Note': 'note'})
        df = df.replace('', np.nan)
        df['atc_code'] = df['atc_code'].ffill()
        df['atc_name'] = df['atc_name'].ffill()
        df = df[['atc_code', 'atc_name', 'ddd', 'uom', 'adm_r', 'note']]
        df.to_csv(f_out, index=False, header=False, lineterminator='\n')

out_file_name = os.path.join(out_dir, 'WHO ATC-DDD {}.csv'.format(pd.Timestamp.now().strftime('%Y-%m-%d')))
print('Writing results to', out_file_name)
if os.path.exists(out_file_name):
    print('Warning: file already exists. Will be overwritten.')

with open(out_file_name, 'w', encoding='utf-8', newline='') as f_out:
    writer = csv.writer(f_out, quoting=csv.QUOTE_MINIMAL, lineterminator='\n')
    writer.writerow(['atc_code', 'atc_name', 'ddd', 'uom', 'adm_r', 'note'])
    for atc_root in atc_roots:
        scrape_who_atc(atc_root, writer, f_out)
        f_out.flush()

print('Script execution completed.')

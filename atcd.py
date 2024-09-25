import requests
from bs4 import BeautifulSoup
import pandas as pd
import numpy as np
import os
import re
from time import sleep
# Increase recursion limit to handle deep recursion
import sys
from io import StringIO
sys.setrecursionlimit(10000)

# Function to ensure a directory exists
def ensure_directory(dir_path):
    if not os.path.exists(dir_path):
        os.makedirs(dir_path)
    return dir_path

# Set up output directories
out_dir = ensure_directory('output')

# Define the ATC roots
atc_roots = ['A', 'B', 'C', 'D', 'G', 'H', 'J', 'L', 'M', 'N', 'P', 'R', 'S', 'V']

atc_code_pattern = re.compile(r'(^[A-Z]$)|(^[A-Z][^a-z][0-9]{1,2}$)|(^[A-Z][^a-z][0-9]{1,2}[A-Z]{1,2}$)|(^[A-Z][^a-z][0-9]{1,2}[A-Z]{1,2}[0-9]{1,2}$)')

# Function to validate ATC codes
def is_valid_atc_code(code):
    return bool(atc_code_pattern.match(code))

# Function to scrape ATC data recursively and write to file
def scrape_who_atc(root_atc_code, f_out):
    """
    This function scrapes and writes all data available from
    https://www.whocc.no/atc_ddd_index/ for the given ATC code and all its subcodes.
    """
    # Validate the ATC code before proceeding
    if not is_valid_atc_code(root_atc_code):
        return
    
    web_address = 'https://www.whocc.no/atc_ddd_index/?code={}&showdescription=no'.format(root_atc_code)
    print('Scraping', web_address)
    atc_code_length = len(root_atc_code)
    response = requests.get(web_address)
    if response.status_code != 200:
        print('Error fetching', web_address)
        return
    html_data = response.content
    soup = BeautifulSoup(html_data, 'html.parser')

    if atc_code_length < 5:
        # Add the root node if needed
        if atc_code_length == 1:
            root_atc_code_name_elements = soup.select('#content a')
            if len(root_atc_code_name_elements) >= 3:
                root_atc_code_name = root_atc_code_name_elements[2].get_text()
            else:
                root_atc_code_name = ''
            f_out.write('{}\t{}\t\t\t\t\n'.format(root_atc_code, root_atc_code_name))
        # Process higher-level codes
        content_p = soup.select_one('#content > p:nth-of-type(2n)')
        if content_p is None:
            return
        scraped_strings = content_p.get_text().split('\n')
        scraped_strings = [s.strip() for s in scraped_strings if s.strip()]
        if not scraped_strings:
            return
        for scraped_string in scraped_strings:
            match = re.match(r'^(\S+)\s+(.*)$', scraped_string)
            if match:
                sleep(1)
                atc_code = match.group(1)
                atc_name = match.group(2)
                # Check ATC code validity
                if not is_valid_atc_code(root_atc_code):
                    return
                # Write the data to the file
                f_out.write('{}\t{}\t\t\t\t\n'.format(atc_code, atc_name))
                # Recurse into subcodes
                scrape_who_atc(atc_code, f_out)
            else:
                continue
    else:
        # Process detailed codes
        table = soup.select_one('ul > table')
        if table is None:
            return
        df_list = pd.read_html(StringIO(str(table)), header=0)
        if len(df_list) == 0:
            return
        df = df_list[0]
        df = df.rename(columns={'ATC code': 'atc_code', 'Name': 'atc_name', 'DDD': 'ddd',
                                'U': 'uom', 'Adm.R': 'adm_r', 'Note': 'note'})
        df = df.replace('', np.nan)
        # Fill in missing atc_code and atc_name
        df['atc_code'] = df['atc_code'].ffill()
        df['atc_name'] = df['atc_name'].ffill()
        # Write the DataFrame to the file without the header
        df.to_csv(f_out, sep='\t', index=False, header=False, lineterminator='\n')

# Write results to a tab-separated CSV file continuously
out_file_name = os.path.join(out_dir, 'WHO ATC-DDD {}.csv'.format(pd.Timestamp.now().strftime('%Y-%m-%d')))
print('Writing results to', out_file_name)
if os.path.exists(out_file_name):
    print('Warning: file already exists. Will be overwritten.')

with open(out_file_name, 'w', encoding='utf-8') as f_out:
    # Write the header
    f_out.write('atc_code\tatc_name\tddd\tuom\tadm_r\tnote\n')
    # Request all codes and subcodes within atc_roots
    i = 0
    for atc_root in atc_roots:
        scrape_who_atc(atc_root, f_out)
        f_out.flush()
        i += 1

print('Script execution completed.')

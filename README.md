### Scrape Anatomical-Therapeutic-Chemical (ATC) classes from the WHO Collaborating Centre for Drug Statistics Methodology website
###### codename: atcd
This repository scrapes the World Health Organization's ATC website (https://atcddd.fhi.no/atc_ddd_index/, formerly hosted at https://www.whocc.no/atc_ddd_index/). It reads ATC classes and their information, and writes to one flat CSV file.

The code runs recursively down the hierarchy from an input ATC code. For example, if provided with "C10", it will download C10 and all subcodes under C10.
  
From ATC levels 1 to 4, you get the codes and names of all classes. At ATC level 5, some but not all classes have the additional fields Administration Route, Defined Daily Dose (DDD), and Note; these will also be scraped if present.

The repository ships two equivalent scrapers:
- **`atcd.R`** — the original implementation (R + `rvest` + `dplyr`).
- **`atcd.py`** — a Python port (`requests` + `BeautifulSoup` + `pandas`).

Both produce the same CSV schema (`atc_code,atc_name,ddd,uom,adm_r,note`). A separate **`atcd_combinations.R`** scrapes the WHO list of DDDs for combination products (see below). Both R scripts pause `Sys.sleep(0.5)` between requests to be polite to the WHO server.

To run from a browser without installing R locally, open **`atcd_colab.ipynb`** in [Google Colab](https://colab.research.google.com/) — it clones this repo and runs `atcd.R` end-to-end.
  
#### Scraping results
As of April 25th, 2026 there are **6,996** unique ATC codes and 6,143 unique names in the WHO website. Here is a breakdown by ATC level: 
| ATC level | Codes | Names |
|:----------|------:|------:|
| Level 1   | 14    | 14    |
| Level 2   | 94    | 94    |
| Level 3   | 271   | 266   |
| Level 4   | 939   | 868   |
| Level 5   | 5678  | 4937  |
  
An example of a name with multiple codes is "miconazole", which has codes [A01AB09](https://atcddd.fhi.no/atc_ddd_index/?code=A01AB09&showdescription=no), [A07AC01](https://atcddd.fhi.no/atc_ddd_index/?code=A07AC01&showdescription=no), [D01AC02](https://atcddd.fhi.no/atc_ddd_index/?code=D01AC02&showdescription=no), [G01AF04](https://atcddd.fhi.no/atc_ddd_index/?code=G01AF04&showdescription=no), [J02AB01](https://atcddd.fhi.no/atc_ddd_index/?code=J02AB01&showdescription=no), [S02AA13](https://atcddd.fhi.no/atc_ddd_index/?code=S02AA13&showdescription=no).  
  
For curiosity, the name with the most codes is "combinations" (38 codes), followed by "betamethasone" (11 codes), "dexamethasone" (11 codes) and "prednisolone" (11 codes); while the ATC codes with the most DDD-UoM-Adm. route combinations are [G03CA03](https://atcddd.fhi.no/atc_ddd_index/?code=G03CA03&showdescription=no) (10), [G03BA03](https://atcddd.fhi.no/atc_ddd_index/?code=G03BA03&showdescription=no) (6), [N02CA02](https://atcddd.fhi.no/atc_ddd_index/?code=N02CA02&showdescription=no) (5), [N07BA01](https://atcddd.fhi.no/atc_ddd_index/?code=N07BA01&showdescription=no) (5). Of all level-5 ATC codes, 2,229 carry at least one DDD; oral (O) is by far the most common route (1,669 entries), followed by parenteral (P, 817), and the most common units of measure are grams (1,331) and milligrams (1,277).

**If you just need all ATC classes and data in one big table, you can download the CSV file in this repository.** However, remember that the WHO website is updated over time. The repository keeps prior snapshots so you can diff over time:
- `WHO ATC-DDD 2026-04-25.csv` (latest, this run)
- `WHO ATC-DDD 2025-06-14.csv` (contributed by [@stabgan](https://github.com/stabgan))
- `WHO ATC-DDD 2024-07-31.csv`
- `WHO ATC-DDD 2021-12-03.csv`

#### Combination-product DDDs
Some combination products (e.g. fixed-dose antimicrobials like J01EE01, J04AM02) do not have a DDD listed on the main ATC index — instead they live in a separate WHO list at https://atcddd.fhi.no/ddd/list_of_ddds_combined_products/, which uses different units (`UD` = unit doses, e.g. tablets) and additional columns (brand name, dosage form, ingredients).

Run **`atcd_combinations.R`** to produce the sibling file `WHO ATC-DDD-combinations <date>.csv` with the schema `atc_code,brand_name,dosage_form,ingredients,ddd_comb`. The current snapshot is **`WHO ATC-DDD-combinations 2026-04-25.csv`** (244 rows covering 130 unique ATC codes, of which 128 are level-5 codes that have empty DDD fields in the main CSV).

#### About the license of the ATC-DDD data  
The WHO Collaborating Centre for Drug Statistics (WHOCC) sells electronic files (e.g. Excel spreadsheet) containing the entire ATC-DDD index for the price of €200 (https://atcddd.fhi.no/atc_ddd_index_and_guidelines/order/). They also publish the same data for free on their website. Their copyright disclaimer (https://atcddd.fhi.no/copyright_disclaimer/), in my layman's opinion, seems to permit web scraping as long as no commercial activity is involved. The license of this GitHub repository precludes commercial use, and in addition to that the contents of the WHOCC website are not being modified but just written as-is to a file. Therefore, to my understanding, there is no violation of the WHOCC website's copyright statement.

#### License
All contents of this repository for which the author (Fabrício Kury) claims copyright are hereby released under the Attribution-ShareAlike-NonCommercial 4.0 International license by Creative Commons, please see details at http://creativecommons.org/licenses/by-nc-sa/4.0/.   
Please feel free to contact me about this work! Reading and reusing code can be made so much easier after a quick text or voice talk with the original author.

_Search engine tags and keywords:  
ATC download complete ATC with DDD ATC hierarchy ATC database all ATC classes with defined daily dose atc code list excel all atc codes csv download atc codes free download atc classification of drugs DDD combinations combined products list_

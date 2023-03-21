### Scrape Anatomical-Therapeutic-Chemical (ATC) classes from the WHO Collaborating Centre for Drug Statistics Methodology website
###### codename: atcd
This script scrapes the World Health Organization's ATC website (https://www.whocc.no/atc_ddd_index/). It reads ATC classes and their information, and writes to one flat CSV file.

The code runs recursively down the hierarchy from an input ATC code. For example, if provided with "C10", it will download C10 and all subcodes under C10.
  
From ATC levels 1 to 4, you get the codes and names of all classes. At ATC level 5, some but not all classes have the additional fields Administration Route, Defined Daily Dose (DDD), and Note; these will also be scraped if present.
  
#### Scraping results
As of May 7th, 2020 there are **6,331** unique ATC codes and 5,517 unique names in the WHO website. Here is a breakdown by ATC level: 
| ATC level | Codes | Names |
|:----------|------:|------:|
| Level 1   | 14    | 14    |
| Level 2   | 94    | 94    |
| Level 3   | 267   | 262   |
| Level 4   | 889   | 819   |
| Level 5   | 5067  | 4363  |
  
An example of a name with multiple codes is "miconazole", which has codes [A01AB09](https://www.whocc.no/atc_ddd_index/?code=A01AB09&showdescription=no), [A07AC01](https://www.whocc.no/atc_ddd_index/?code=A07AC01&showdescription=no), [D01AC02](https://www.whocc.no/atc_ddd_index/?code=D01AC02&showdescription=no), [G01AF04](https://www.whocc.no/atc_ddd_index/?code=G01AF04&showdescription=no), [J02AB01](https://www.whocc.no/atc_ddd_index/?code=J02AB01&showdescription=no), [S02AA13](https://www.whocc.no/atc_ddd_index/?code=S02AA13&showdescription=no).  
  
For curiosity, the name with the most codes is "combinations" (39 codes), followed by "betamethasone" (11 codes), "dexamethasone" (11 codes) and "prednisolone" (10 codes); while the ATC codes with the most DDD-UoM-Adm. route combinations are [G03CA03](https://www.whocc.no/atc_ddd_index/?code=G03CA03&showdescription=no) (10), [G03BA03](https://www.whocc.no/atc_ddd_index/?code=G03BA03&showdescription=no) (6), [N02CA02](https://www.whocc.no/atc_ddd_index/?code=N02CA02&showdescription=no) (5), [N07BA01](https://www.whocc.no/atc_ddd_index/?code=N07BA01&showdescription=no) (5).
  
**If you just need all ATC classes and data in one big table, you can download the CSV file in this repository.** However, remember that the WHO website is updated over time.  
  
#### About the license of the ATC-DDD data  
The WHO Collaborating Centre for Drug Statistics (WHOCC) sells electronic files (e.g. Excel spreadsheet) containing the entire ATC-DDD index for the price of €200 (https://www.whocc.no/atc_ddd_index_and_guidelines/order/). They also publish the same data for free on their website. Their copyright disclaimer (https://www.whocc.no/copyright_disclaimer/), in my layman's opinion, seems to permit web scraping as long as no commercial activity is involved. The license of this GitHub repository precludes commercial use, and in addition to that the contents of the WHOCC website are not being modified but just written as-is to a file. Therefore, to my understanding, there is no violation of the WHOCC website's copyright statement.

#### License
All contents of this repository for which the author (Fabrício Kury) claims copyright are hereby released under the Attribution-ShareAlike-NonCommercial 4.0 International license by Creative Commons, please see details at http://creativecommons.org/licenses/by-nc-sa/4.0/.   
Please feel free to contact me about this work! Reading and reusing code can be made so much easier after a quick text or voice talk with the original author.

_Search engine tags and keywords:  
ATC download complete ATC with DDD ATC hierarchy ATC database all ATC classes with defined daily dose atc code list excel all atc codes csv download atc codes free download atc classification of drugs_

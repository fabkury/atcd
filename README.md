### Scrape Anatomical-Therapeutic-Chemical (ATC) classes from the WHO Collaborating Centre for Drug Statistics Methodology website
###### codename: atcd
This script scrapes the ATC website, that is, it reads ATC classes and their information, and writes into one flat CSV file.

The code runs recursively down the hierarchy from an input ATC code. For example, if provided with "C10", it will download C10 and all codes and subcodes under C10.
  
From ATC levels 1 to 4, what you get are the codes and names of all classes. At ATC level 5, some but not all classes have the additional fields Administration Route, Defined Daily Dose (DDD), and Note; these will also be downloaded if present. 
  
**If you just need all the ATC classes and data in one big table, you can download the CSV file in this repository.** However, remember that the data is continuously updated.  
  
#### About the license of the ATC-DDD data  
The WHO Collaborating Centre for Drug Statistics (WHOCC) sells electronic files (e.g. Excel spreadsheet) containing the entire ATC-DDD index for the price of €200 (https://www.whocc.no/atc_ddd_index_and_guidelines/order/). They also publish the same data for free on the website. The copyright disclaimer on the website (https://www.whocc.no/copyright_disclaimer/) does not seem, in my layman's opinion, to preclude web scraping as long as no commercial activity is involved. This license of the contents of this GitHub repository precludes commercial use, and the contents of the WHOCC website are in no way being modified, therefore, to my understanding, there is no violation of the WHOCC website's copyright statement.

#### License
All contents of this repository are under an Attribution-ShareAlike-NonCommercial 4.0 International license. Please see details at http://creativecommons.org/licenses/by-nc-sa/4.0/. Please feel free to contact me about this work! Reading and reusing code can be made so much easier after a quick text or voice talk with the original author.

_Search engine tags:  
ATC download ATC-DDD complete hierarchy database all classes defined daily dose_

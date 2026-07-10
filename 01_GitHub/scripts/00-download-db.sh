#!/bin/bash

#wget "https://rest.uniprot.org/uniprotkb/stream?compressed=true&format=fasta&query=%28glucocorticoid-responsive+genes%29" -O 01_GitHub/data/db.fasta.gz        # UniProt was failing at the time of the workshop - stream error
zcat 01_GitHub/data/db.fasta.gz | awk '{print $1}' | gzip > 01_GitHub/data/db_trimmed.fasta.gz
diamond makedb --in 01_GitHub/data/db_trimmed.fasta.gz -d 01_GitHub/data/db_trimmed.dmnd

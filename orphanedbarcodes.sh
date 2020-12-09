#!/bin/bash

#set up our environment
PSQL="/usr/bin/psql"
DB_USER="evergreen"
DB_HOST="db03"
OUTPUT_FILE="orphaned_barcodes_`date +%Y_%m_%d_%H%M%S`.csv"
REPORT_EMAIL="tlittle@georgialibraries.org"

read -r -d '' REPORT_QUERY << HERE
select shortname as circ_lib, asset.copy.barcode as barcode, asset.copy.create_date as creation_date
from acq.lineitem_detail
right join asset.copy on asset.copy.id=acq.lineitem_detail.eg_copy_id
right join actor.org_unit on actor.org_unit.id=asset.copy.circ_lib
where asset.copy.barcode like '%ACQ%' and
deleted='f' and
eg_copy_id is null
order by circ_lib
HERE

$PSQL -U $DB_USER -h $DB_HOST -o $OUTPUT_FILE -F ',' -c $REPORT_QUERY

echo "Report file $OUTPUT_FILE attached" | mutt -s "Orphaned barcodes report" $REPORT_EMAIL -a $OUTPUT_FILE
~                                                                                                           

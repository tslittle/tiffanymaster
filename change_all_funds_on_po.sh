#!/bin/bash

# Use this script to update the fund on multiple line item details on a purchase order

#set up our environment
PSQL="/usr/bin/psql"
DB_USER="evergreen"
DB_HOST="db01"
BACKUP_TABLE="tlittle.changed_funds_`date +%Y_%m_%d_%H%M%S`"
OUTPUT_FILE="tlittle_changed_funds_`date +%Y_%m_%d_%H%M%S`.csv"
REPORT_EMAIL="tlittle@georgialibraries.org"

#Usage() {
#echo "Usage: $0 [-of <old fund ID>] [-nf <new fund ID] [-po <purchase order>]"
#}


read -p "What is the purchase order ID to be affected? " POID
echo "You entered $POID for the purchase order to modify."
read -p "What is the ID of the old fund to be replaced? " OLDFUND
echo "You entered $OLDFUND for the fund to be replaced."
read -p "What is the ID of the new fund to use for these lineitem details? " NEWFUND
echo "You entered $NEWFUND to use as the correct new fund."
echo "Confirming that all line item details on $POID using $OLDFUND will be modified to use $NEWFUND. (Ctrl-C within 5 seconds to exit)"
sleep 5

#select out the ids for lineitem details to be edited
read -r -d '' LID_IDS_QUERY << EOF
SELECT lid.id INTO $BACKUP_TABLE FROM acq.lineitem_detail lid
    JOIN acq.lineitem li ON li.id=lid.lineitem
    WHERE li.purchase_order=$POID and
    lid.fund=$OLDFUND
EOF



#do something
$PSQL -U $DB_USER -h $DB_HOST -1 -c "$LID_IDS_QUERY"
$PSQL -U $DB_USER -h $DB_HOST -1 -c "UPDATE acq.lineitem_detail SET fund = $NEWFUND where id IN (SELECT id FROM $BACKUP_TABLE)"
$PSQL -U $DB_USER -h $DB_HOST -1 -c "UPDATE acq.fund_debit SET fund = $NEWFUND where id IN (SELECT fund_debit FROM acq.lineitem_detail WHERE id IN (SELECT id FROM $BACKUP_TABLE))"

read -r -d '' REPORT_QUERY << HEY
select  lid.id as "Lineitem Detail ID",
        li.id as "Lineitem ID",
        fund.id as "Fund ID",
        fd.id as "Fund Debit ID"
from    acq.lineitem_detail lid
        JOIN acq.lineitem li on (lid.lineitem = li.id)
        JOIN acq.fund fund on (lid.fund = fund.id)
        LEFT OUTER JOIN acq.fund_debit fd on (lid.fund_debit = fd.id)
where   lid.id in (SELECT id FROM $BACKUP_TABLE)
HEY

$PSQL -U $DB_USER -h $DB_HOST -o $OUTPUT_FILE -F ',' -c $REPORT_QUERY

echo "Report file $OUTPUT_FILE attached" | mutt -s "Changed Funds on Lineitem Details Report" $REPORT_EMAIL -a $OUTPUT_FILE

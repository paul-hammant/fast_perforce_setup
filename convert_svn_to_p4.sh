#!/bin/bash

# if  [ ! -d .p4root ]; then echo "no .p4root folder - do 'p4 init'"; exit 10; fi
if  [ ! -d .svn ]; then echo "no .svn folder - checkout the trunk of some subversion repo"; exit 10; fi
[ ! -d ../svn_to_p4_commits ] && mkdir ../svn_to_p4_commits
# p4 edit .p4ignore 
# echo -e ".svn\nsvn_to_p4_commits\nsvn_to_p4_revision.txt\nsvn_to_p4_revisions.txt" >> .p4ignore

svn log | grep '^r[0-9]* ' | cut -d' ' -f 1 | cut -d'r' -f 2 | sort -n > ../svn_to_p4_revisions.txt
prefix=$(svn info | grep "^Relative URL:" | sed 's/Relative URL: ^//' | sed 's#/trunk##')

while ((i++)); read -r rev; do
    trap "echo Exited!; exit;" SIGINT SIGTERM

    # if [ "$rev" != "366" ]; then continue; fi

    svn log -v -r $rev > ../svn_to_p4_revision.txt

    revisionLine=$(cat ../svn_to_p4_revision.txt | grep '^r[0-9]* ')
    author=$(echo $revisionLine | cut -d'|' -f2 | sed 's/(no author)/none/' | cut -d' ' -f2 | sed "s/^$/none/")
    date=$(echo $revisionLine | cut -d'|' -f3 | cut -d'(' -f1)
    messageText=$(cat ../svn_to_p4_revision.txt | awk '/^$/ {do_print=1} do_print==1 {print} NF==3 {do_print=0}' | sed '/------/d' | sed 's/\"/\\\"/g') 

    svn up --force -r $rev | sed '/^At revision/d' | sed '/^Updating /d' | sed '/^[AUD]  /d' | sed '/^ U/d' | sed '/^Updated to/d' | sed '/^Restored /d'
    p4 reconcile  2>&1 | sed '/opened for add$/d' | sed '/opened for move$/d' | sed '/opened for delete$/d' | sed '/opened for edit$/d' | sed '/opened for move\/add$/d' | sed '/opened for move\/delete$/d' | sed '/^\.\.\. moved from/d' > ../svn_to_p4_reconcile_output

    if ! grep -Fq "No file(s) to reconcile." ../svn_to_p4_reconcile_output; then
        p4 submit -d "Svn Rev: ${rev}.${messageText}" > ../svn_to_p4_commits/"${rev}".txt 2>&1
        p4Rev=$(p4 changes -m 1 | cut -d' ' -f2)
        # p4 change -f -U $author $p4Rev
        # --date "\"${date}\"" 
        echo "Svn revision ${rev} on $(echo $date | cut -d' ' -f 1,2) is Perforce # $p4Rev"    
    fi

    # if [ "$rev" == "380" ]; then break; fi

done < ../svn_to_p4_revisions.txt
echo "ALL DONE WITH A P4 REPO SIZE OF $(du -h -d 0 .p4root | cut -f1)."

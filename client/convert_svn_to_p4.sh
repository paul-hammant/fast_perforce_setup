#!/bin/bash

if  [ ! -d .git ]; then echo "no .git folder - do 'git init'"; exit 10; fi
if  [ ! -d .svn ]; then echo "no .svn folder - checkout the trunk of some subversion repo"; exit 10; fi
[ ! -d svn_to_p4_commits ] && mkdir svn_to_p4_commits
echo -e ".svn\nsvn_to_p4_commits\nsvn_to_p4_revision.txt\nsvn_to_p4_revisions.txt" > .gitignore
git add .gitignore > /dev/null

svn log | grep '^r\d' | cut -d' ' -f 1 | cut -d'r' -f 2 | sort -n > svn_to_p4_revisions.txt
prefix=$(svn info | grep "^Relative URL:" | sed 's/Relative URL: ^//' | sed 's#/trunk##')

while ((i++)); read -r rev; do
    trap "echo Exited!; exit;" SIGINT SIGTERM

    svn up --force -r $rev | sed '/^At revision/d' | sed '/^Updating /d' | sed '/^[AUD]  /d' | sed '/^ U/d' | sed '/^Updated to/d'
    svn log -v -r $rev > svn_to_p4_revision.txt

    revisionLine=$(cat svn_to_p4_revision.txt | grep '^r\d')
    author=$(echo $revisionLine | cut -d'|' -f2 | sed 's/(no author)/none/' | cut -d' ' -f2 | sed "s/^$/none/")
    date=$(echo $revisionLine | cut -d'|' -f3 | cut -d'(' -f1)
    messageText=$(cat svn_to_p4_revision.txt | awk '/^$/ {do_print=1} do_print==1 {print} NF==3 {do_print=0}' | sed '/------/d') | sed 's/\"/\\\"/g'

    cat svn_to_p4_revision.txt | sed "s/^ *//" | sed 's/(.*)$//' | sed "s/ *$//" | grep "${prefix}/trunk/" | sed "s#${prefix}/trunk/##" | sponge svn_to_p4_revision.txt
    grep "^[AMR]" svn_to_p4_revision.txt | cut -d' ' -f 2-99 | xargs -I {} git add "{}"
    grep "^D" svn_to_p4_revision.txt | cut -d' ' -f 2-99 | xargs -I {} git rm -q --ignore-unmatch -r "{}"
    git commit --author "\"${author} <${author}@unsure>\"" --date "\"${date}\"" -m "\"Svn Rev: ${rev}.${messageText}\"" > svn_to_p4_commits/"${rev}".txt

    echo "Svn revision ${rev} on $(echo $date | cut -d' ' -f 1,2)."
    
    if [[ $(( rev % 4000 )) == 0 ]]; then
        time -p sh -c 'git repack; git gc'
    fi 
done < svn_to_p4_revisions.txt

time -p sh -c 'git repack; git gc'
echo "ALL DONE WITH A GIT REPO SIZE OF $(du -h -d 0 .git | cut -f1)."

#!/bin/bash

if  [ ! -d .git ]; then echo "no .git folder - do 'git init'"; exit 10; fi
if  [ ! -d .svn ]; then echo "no .svn folder - checkout the trunk of some subversion repo"; exit 10; fi

svn log | grep '^r\d' | cut -d' ' -f 1 | cut -d'r' -f 2 | sort -n > svn_to_p4_revisions.txt

prefix=$(svn info | grep "^Relative URL:" | sed 's/Relative URL: ^//' | sed 's#/trunk##')

echo -e ".svn\nsvn_to_p4_commits\nsvn_to_p4_adds_mods.txt\nsvn_to_p4_deletes.txt\nsvn_to_p4_revision.txt\nsvn_to_p4_revisions.txt" > .gitignore
git add .gitignore > /dev/null

mkdir svn_to_p4_commits 2>&1 > /dev/null

while ((i++)); read -r rev; do

    trap "echo Exited!; exit;" SIGINT SIGTERM

    svn up --force -r $rev | sed '/^At revision/d' | sed '/^Updating /d' | sed '/^[AUD]  /d' | sed '/^ U/d' | sed '/^Updated to/d'
    svn log -v -r $rev > svn_to_p4_revision.txt

    revision=$(cat svn_to_p4_revision.txt | grep '^r\d')

    author=$(echo $revision | cut -d'|' -f 2 | cut -d' ' -f2)
    if ! [ -n "$author" ]; then
        author="none"
    fi
    date=$(echo $revision | cut -d'|' -f 3 | cut -d'(' -f 1)

    grep "[AMRD] ${prefix}/trunk/" svn_to_p4_revision.txt  | sed "s/^[ ]*//" | sed 's/(.*)$//' | sed "s/[ ]*$//" | sed "s#${prefix}/trunk/##" > svn_to_p4_adds_mods.txt
    while read l; do
        f=$(echo "$l" | cut -d' ' -f 2)
        if echo "$l" | grep -q '^D '; then
            git rm -q --ignore-unmatch -r "$f"
        else
            git add "$f"
        fi
    done <svn_to_p4_adds_mods.txt

    messageText=$(cat svn_to_p4_revision.txt | awk '/^$/ {do_print=1} do_print==1 {print} NF==3 {do_print=0}' | sed '/------/d') | sed 's/\"/\\\"/g'
    headers="Svn Rev: ${rev}."
    cmd="git commit --author \"${author} <${author}@unsure>\" --date \"${date}\" -m \"${headers}${messageText}\""
    eval "$cmd" > svn_to_p4_commits/"${rev}".txt

    echo "Svn revision ${rev} on $(echo $date | cut -d' ' -f 1,2)."
    
    if [[ $(( rev % 4000 )) == 0 ]]; then
        time -p sh -c 'git repack; git gc'
    fi 
    
done < svn_to_p4_revisions.txt

time -p sh -c 'git repack; git gc'
echo "ALL DONE."

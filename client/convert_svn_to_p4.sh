#!/bin/bash

if  [ ! -d .git ]; then echo "no .git folder - do 'git init'"; exit 10; fi
if  [ ! -d .svn ]; then echo "no .svn folder - checkout the trunk of some subversion repo"; exit 10; fi

svn log --xml | xmlstarlet sel -t -m 'log/logentry' -v "concat(@revision, '|', author, '|', date )" -n | sort -n > svn_to_p4_revisions.txt

prefix=$(svn info | grep "^Relative URL:" | sed 's/Relative URL: ^//' | sed 's#/trunk##')

echo -e ".svn\nsvn_to_p4_commits\nsvn_to_p4_adds_mods.txt\nsvn_to_p4_deletes.txt\nsvn_to_p4_gitadd_output.txt\nsvn_to_p4_revision.txt\nsvn_to_p4_revisions.txt\nsvn_to_p4_rm_output.txt\nsvn_to_p4_up.txt" > .gitignore
git add .gitignore > /dev/null
git commit -m "ignore some temp files used in svn conversion process" > /dev/null

mkdir svn_to_p4_commits 2>&1 > /dev/null

while ((i++)); read -r revision; do

    trap "echo Exited!; exit;" SIGINT SIGTERM
    rev=$(echo $revision | cut -d'|' -f 1)
    author=$(echo $revision | cut -d'|' -f 2)
    if ! [ -n "$author" ]; then
        author="none"
    fi
    date=$(echo $revision | cut -d'|' -f 3)
    echo "Svn revision ${rev} on $(echo $date | cut -d'T' -f 1)."
    svn up --force -r $rev | sed '/^At revision/d' | sed '/^Updating /d' > svn_to_p4_up.txt
    svn log -v -r $rev > svn_to_p4_revision.txt
    grep "^   [AMR]" svn_to_p4_revision.txt | grep "[AMR] ${prefix}/trunk/" | sed "s/^[ ]*//" | sed 's/(.*)//' | sed "s/[ ]*$//" | sed "s#[AMR] ${prefix}/trunk/##" > svn_to_p4_adds_mods.txt
    while read add_mod; do
        cmd="git add \"$add_mod\""
        eval "$cmd" 
    done <svn_to_p4_adds_mods.txt
    grep "^   D" svn_to_p4_revision.txt | grep "D ${prefix}/trunk" | sed "s#D ${prefix}/trunk/##" | sed "s/^[ ]*//" | sed "s/[ ]*$//" > svn_to_p4_deletes.txt
    while read del; do
        cmd="git rm -q --ignore-unmatch -r \"$del\""
        eval "$cmd" 2>&1 > svn_to_p4_rm_output.txt
        cat svn_to_p4_rm_output.txt 2>&1 | sed "/^fatal: pathspec.*/d" 
    done <svn_to_p4_deletes.txt

    messageText=$(cat svn_to_p4_revision.txt | awk '/^$/ {do_print=1} do_print==1 {print} NF==3 {do_print=0}' | sed '/------/d') | sed 's/\"/\\\"/g'
    headers="Svn Rev: ${rev}."
    cmd="git commit --author \"${author} <${author}@unsure>\" --date \"${date}\" -m \"${headers}${messageText}\""
    eval "$cmd" > svn_to_p4_commits/"${rev}".txt
    
    if [[ $(( rev % 4000 )) == 0 ]]; then
        echo "Git repack & gc"..
        time git repack 
        time git gc
    fi 
    
done < svn_to_p4_revisions.txt

time git repack 
time git gc

echo "ALL DONE."

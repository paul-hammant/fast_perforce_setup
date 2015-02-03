#!/bin/sh

svn log --xml | xmlstarlet sel -t -m 'log/logentry' -v "concat(@revision, '|', author, '|', date )" -n | sort -n > svn_to_p4_revisions.txt

prefix="/trunk/"

for revision in `cat svn_to_p4_revisions.txt`; do
	trap "echo Exited!; exit;" SIGINT SIGTERM
	rev=$(echo $revision | cut -d'|' -f 1)
	author=$(echo $revision | cut -d'|' -f 2)
	date=$(echo $revision | cut -d'|' -f 3)
	echo "rev: ${rev}"
	svn up --force --quiet -r $rev | sed '/^At revision/d' | sed '/^Updating /d'
	svn log -v -r $rev > svn_to_p4_revision.txt
	grep "^   M" svn_to_p4_revision.txt | grep "/trunk" | sed 's#M /trunk/##' > svn_to_p4_adds_mods.txt
	grep "^   A" svn_to_p4_revision.txt | grep "/trunk" | sed 's#A /trunk/##' >> svn_to_p4_adds_mods.txt
	for add_mod in `cat svn_to_p4_adds_mods.txt`; do
		if [ -f $add_mod ]; then
			git add $add_mod
		fi
	done
	grep "^   D" svn_to_p4_revision.txt | grep "/trunk" | sed 's#D /trunk/##' > svn_to_p4_deletes.txt
	for del in `cat svn_to_p4_deletes.txt`; do
		git rm --quiet $del
	done
	messageText=$(cat svn_to_p4_revision.txt | awk '/^$/ {do_print=1} do_print==1 {print} NF==3 {do_print=0}' | sed '/------/d')
	headers=$"Rev: ${rev}. Auth: ${author}. Date: ${date}"$'\n'
	commitMessage=${headers}${messageText}
	git commit --quiet -m "${commitMessage}" | sed '/^ create mode/d'
done
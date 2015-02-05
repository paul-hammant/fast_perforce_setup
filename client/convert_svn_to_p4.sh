#!/bin/sh

svn log --xml | xmlstarlet sel -t -m 'log/logentry' -v "concat(@revision, '|', author, '|', date )" -n | sort -n > svn_to_p4_revisions.txt

rm svn_to_p4_fatal_pathspecs.txt

for revision in `cat svn_to_p4_revisions.txt`; do

	trap "echo Exited!; exit;" SIGINT SIGTERM
	rev=$(echo $revision | cut -d'|' -f 1)
	author=$(echo $revision | cut -d'|' -f 2)
	date=$(echo $revision | cut -d'|' -f 3)
	echo "rev: ${rev} ${date}"
	svn up --force -r $rev | sed '/^At revision/d' | sed '/^Updating /d' > svn_to_p4_up.txt

	svn log -v -r $rev > svn_to_p4_revision.txt
	grep "^   [AMR]" svn_to_p4_revision.txt | grep "[AMR] .*/trunk/" | sed "s/^[ ]*//" | sed 's/(.*)//' | sed "s/[ ]*$//" | sed 's#.*/trunk/##' > svn_to_p4_adds_mods.txt
	while read add_mod; do
		cmd="git add \"$add_mod\""
		eval $cmd > svn_to_p4_gitadd_output.txt
		cat svn_to_p4_gitadd_output.txt | grep "fatal: pathspec" | sed "s/fatal/${rev} (add): fatal/" >> svn_to_p4_fatal_pathspecs.txt

    done <svn_to_p4_adds_mods.txt
	grep "^   D" svn_to_p4_revision.txt | grep "D .*/trunk" | sed 's#D .*/trunk/##' | sed "s/^[ ]*//" | sed "s/[ ]*$//" > svn_to_p4_deletes.txt
	while read del; do
		cmd="git rm -r \"$del\""
		eval $cmd > svn_to_p4_gitrm_output.txt
		cat svn_to_p4_gitrm_output.txt | grep "fatal: pathspec" | sed "s/fatal/${rev} (rm): fatal/" >> svn_to_p4_fatal_pathspecs.txt
    done <svn_to_p4_deletes.txt
	messageText=$(cat svn_to_p4_revision.txt | awk '/^$/ {do_print=1} do_print==1 {print} NF==3 {do_print=0}' | sed '/------/d')
	headers=$"Rev: ${rev}. Auth: ${author}. Date: ${date}"$'\n'
	commitMessage=${headers}${messageText}
	git commit --quiet -m "${commitMessage}" | sed '/^ create mode/d' > svn_to_p4_commit_output.txt

    if grep -q "Changes not staged for commit" svn_to_p4_commit_output.txt; then
       echo "Changes not staged for commit"
       break
    fi

    #if [ $rev -eq 143229 ]; then
    #   break
    #fi

	rm svn_to_p4_revision.txt svn_to_p4_deletes.txt svn_to_p4_gitadd_output.txt svn_to_p4_up.txt svn_to_p4_gitrm_output.txt 2>&1 | sed '/No such file or directory/d'
done

echo "FATAL PATHSPECS (if any)"
cat svn_to_p4_fatal_pathspecs.txt
echo "ALL DONE."
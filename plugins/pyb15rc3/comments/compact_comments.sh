#!/bin/bash
#  or
#!/usr/bin/env bash
#
# compact_comments.sh
# Copyright 2008 Ryan Barrett
#
# Compacts PyBlosxom comment files generated by comments.py into a single file,
# per entry. This makes rendering more efficient, particularly for entries with
# many comments, since fewer distinct files need to be statted and read from disk.
#
# For entry XXX, the all comment file will be named XXX-all.cmt.
#
# Operates on comment files in the current directory. Renames compacted
# comment files from *.cmt to *.cmt.compacted, but does not delete them.
#
# Currently, the .txt entry file suffix and .cmt comment file suffix are hard
# coded. If there's demand, they could easily be parameterized.
#
#
# Requires:
#
# - rename(1) that takes a perl expression, as opposed to fixed before and after
#   patterns.
#
# - xargs(1) that supports the -0 option.
#
# - find(1) that supports the -print0 option.
#
# - sed(1), head(1), tail(1), wc(1), expr(1)

echo 'Compacting all comments...'

for file in *.txt; do
  # filenames and patterns for the comment files for this entry
  all_cmt_file=`sed 's/.txt$/-all.cmt/' <<<"$file"`
  new_all_cmt_file="${all_cmt_file}.new"
  cmt_glob=`sed 's/.txt$/-????*.cmt/' <<<"$file"`

  # enumerate the comment files ahead of time, so that there's no race condition
  # in the globbing for copying their contents and for deleting them.
  cmt_files=`find . -maxdepth 1 -name "$cmt_glob"`

  if [ ! "$cmt_files" ]; then
    # no comment files for this entry to compact. skip it.
    continue
  fi

  # we know we're going to compact this entry's comments now.
  echo "$cmt_files"

  # write all of the comment files, including any existing -all.cmt file, to an
  # -all.cmt.new file.
  cat > "$new_all_cmt_file" <<-EOF
	<?xml version="1.0" encoding="utf-8"?>
	<items>
	EOF

  if [ -f "$all_cmt_file" ]; then
    # strip the leading <xml ...> and <items> and trailing </items> lines
    lines=`cat "$all_cmt_file" | wc -l`
    head -n `expr $lines - 1` "$all_cmt_file" \
      | tail -n `expr $lines - 3` \
      >> "$new_all_cmt_file"
  fi

  
  echo "$cmt_files" | while read cmt_file; do
    # strip the leading <xml ...> line
    lines=`cat "$cmt_file" | wc -l`
    tail -n `expr $lines - 1` "$cmt_file" >> "$new_all_cmt_file" 
  done

  cat >> "$new_all_cmt_file" <<-EOF
	</items>
	EOF

  # rename the existing *.cmt files to *.cmt.compacted.
  echo "$cmt_files" | while read cmt_file; do
    mv "$cmt_file" "${cmt_file}.compacted"
  done

  if [ -f "$all_cmt_file" ]; then
    mv "$all_cmt_file" "${all_cmt_file}.compacted"
  fi

  # finally, rename the -all.cmt.new file to -all.cmt.
  mv "${new_all_cmt_file}" "${all_cmt_file}"
done

echo '...done! Consider archiving or deleting *.compacted.'

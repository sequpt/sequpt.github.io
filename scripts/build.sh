#!/bin/sh
# SPDX-License-Identifier: 0BSD
################################################################################
## @file
## @date 18.04.2025
## @license
## BSD Zero Clause License
##
## Copyright (c) 2025 by sequpt
##
## Permission to use, copy, modify, and/or distribute this software for any
## purpose with or without fee is hereby granted.
##
## THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH
## REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY
## AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT,
## INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM
## LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR
## OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR
## PERFORMANCE OF THIS SOFTWARE.
################################################################################
# Exit script on:
# - Error
# - Variable not set
set -e -u
# Set locale to C/POSIX
LC_ALL=C; export LC_ALL
################################################################################
## main() <build-path>
##
## @args
## $1 <build-path> [REQ]: Directory path where the site will be built.
main() {
  build_path="$(realpath "$1")"
  # Return an error if `build_path` exist but isn't a directory.
  if [ -e "$build_path" ] && [ ! -d "$build_path" ]; then
    printf "[ERROR] \`build_path\` exists but isn't a directory.\n"
    return 1
  fi

  mkdir -p "$build_path/site/static"
  cp -r 'src/css' "$build_path/site/static"

  build_home "$build_path"
  build_notes "$build_path"
}
################################################################################
## escape_sed_repl_str() <file-path>
##
## Reads `<file-path>` and returns an escaped string of its content that can be
## used as a replacement string in the sed `s/regexp/replacement/` command.
##
## 1) Escapes ampersand(`&`), slash(`/`) and backslash(`\`).
## 2) Escapes end of lines.
## 3) Removes the backslash from the end of the last line(added at step 2).
##
## @args
## $1 <file-path> [REQ]: Path to the file to read.
escape_sed_repl_str() {
  sed --posix \
    -e 's/[&/\]/\\&/g' \
    -e 's/$/\\/' \
    -e '$s/\\$//' \
    "$1"
}
################################################################################
## markdown_to_html() <markdown-file-path>
##
## Reads `<markdown-file-path>` and returns a string of its content converted
## to html.
##
## $1 <markdown-file-path> [REQ]: Path to the markdown file.
markdown_to_html() {
  pandoc "$1" \
    -f markdown_strict+auto_identifiers+backtick_code_blocks \
    -t html \
    --wrap=preserve
}
################################################################################
## build_home() <output-path>
##
## Builds index and pages for the `/` route.
##
## @args
## $1 <output-path> [REQ]: Directory path where the home will be built.
build_home() {
  output_path="$1/site"; mkdir -p "$output_path"
  index_content="$(escape_sed_repl_str "src/html/index.html")"
  sed --posix \
    -e 's/@PAGE_TITLE@/sequpt/' \
    -e "s/@PAGE_MAIN@/$index_content/" \
    "src/templates/base.html" > "$output_path/index.html"
}
################################################################################
## build_notes() <output-path>
##
## Builds index and pages for the `/notes` route.
##
## @args
## $1 <output-path> [REQ]: Directory path where the notes will be built.
build_notes() {
  output_path="$1/site/notes"; mkdir -p "$output_path"
  tmp_path="$1/tmp/notes"; mkdir -p "$tmp_path"
  # Clone the notes.git repository.
  if [ ! -e "$tmp_path/notes_git" ]; then
    git clone https://github.com/sequpt/notes.git "$tmp_path/notes_git"
  fi
  # Get an alphabetically sorted list of all note markdown files.
  note_md_path_list="$(find "$tmp_path/notes_git/notes" -name '*.md' -type f | sort)"
  # Build note pages
  for note_md_path in $note_md_path_list; do
    note_name="$("basename" "$note_md_path" ".md")"
    markdown_to_html "$note_md_path" > "$tmp_path/$note_name.html"
    note_content="$(escape_sed_repl_str "$tmp_path/$note_name.html")"
    sed --posix \
      -e "s/@PAGE_TITLE@/$note_name | sequpt/" \
      -e "s/@PAGE_MAIN@/$note_content/" \
      "src/templates/base.html" > "$output_path/$note_name.html"
    printf "%s\n" "- [$note_name](/notes/$note_name.html)" >> "$tmp_path/index.md"
  done

  # Build index.html
  markdown_to_html "$tmp_path/index.md" > "$tmp_path/index.html"
  index_content="$(escape_sed_repl_str "$tmp_path/index.html")"
  sed --posix \
    -e 's/@PAGE_TITLE@/Notes | sequpt/' \
    -e "s/@PAGE_MAIN@/$index_content/" \
    "src/templates/base.html" > "$output_path/index.html"
}
################################################################################
main "$@"

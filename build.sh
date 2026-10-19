#!/bin/sh
# Builds index.html (the live tool for the MK Solutions website) and admin.html (the admin page) from src/, adding the database keys.
cd "$(dirname "$0")"
URL="https://abxsiiasnlbotilzfxbb.supabase.co"
KEY="sb_publishable_0oKI0IwXMv2sYpk8906IHw_2lrLmkR5"
SITE="https://www.mksolutionsind.com/free-itinerary-maker/app"
build() { { printf '<!doctype html>\n<html lang="en">\n<head>\n<meta charset="utf-8">\n<meta name="viewport" content="width=device-width,initial-scale=1,viewport-fit=cover">\n<style>body{margin:0}img{max-width:100%%}[hidden]{display:none!important}</style>\n'
  sed -n '1,/^<\/style>/p' "$1"; printf '</head>\n<body>\n'
  sed "1,/^<\/style>/d" "$1" | sed "s#const MK_CONFIG={supabaseUrl:\"\",supabaseAnonKey:\"\",siteUrl:\"\"};#const MK_CONFIG={supabaseUrl:\"$URL\",supabaseAnonKey:\"$KEY\",siteUrl:\"$SITE\"};#"
  printf '</body>\n</html>\n'; } > "$2"; }
build src/index.html index.html
build src/admin.html admin.html

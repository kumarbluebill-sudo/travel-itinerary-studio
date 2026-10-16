#!/bin/sh
# Builds index.html (the live tool for the MK Solutions website) from src/index.html, adding the database keys.
cd "$(dirname "$0")"
URL="https://fcpryoeliiggsyzojvjl.supabase.co"
KEY="sb_publishable_yQtUAa9geBGMZpRm_Z3wbw_KnfALbyV"
SITE="https://www.mksolutionsind.com/free-itinerary-maker/app"
{ printf '<!doctype html>\n<html lang="en">\n<head>\n<meta charset="utf-8">\n<meta name="viewport" content="width=device-width,initial-scale=1,viewport-fit=cover">\n<style>body{margin:0}img{max-width:100%%}[hidden]{display:none!important}</style>\n'
  sed -n '1,/^<\/style>/p' src/index.html; printf '</head>\n<body>\n'
  sed "1,/^<\/style>/d" src/index.html | sed "s#const MK_CONFIG={supabaseUrl:\"\",supabaseAnonKey:\"\",siteUrl:\"\"};#const MK_CONFIG={supabaseUrl:\"$URL\",supabaseAnonKey:\"$KEY\",siteUrl:\"$SITE\"};#"
  printf '</body>\n</html>\n'; } > index.html

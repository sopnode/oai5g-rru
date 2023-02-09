- possibly (in case of new oai-cn5g-fed version) retrieve original oai_db-basic.sql
  cp /Users/turletti/git/oai-cn5g-fed/charts/oai-5g-core/mysql/initialization/oai_db-basic.sql ./oai_db-basic-orig.sql
- make your changes and save it to oai_db-basic-new.sql (the new desired mysql config)
- create the patch file with:
  diff -u oai_db-basic-orig.sql oai_db-basic-new.sql > patch-oai_db-basic
- insert-file patch-oai_db-basic within mysql patch section of demo-oai.sh

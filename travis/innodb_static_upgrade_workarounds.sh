# Expects: 
# - BASEDIR (mandatory)
# - SERVER_BRANCH (mandatory)
# - OLD (mandatory, old version, major or minor)
# - socket (mandatory)


case $SERVER_BRANCH in
*10.[2-4]*)
  case $OLD in
  10.[01]*)
    echo "#################################################################"
    echo "# MDEV-18084"
    echo "# Server crashes in row_upd_changes_some_index_ord_field_binary"
    echo "# or Assertion pos < index->n_def' failed in dict_index_get_nth_field"
    echo "# upon UPDATE after upgrade from 10.1/10.0"
    echo "#################################################################"
    echo ""
    echo "Trying to remove all virtual columns before running test flow"
    echo ""
    $BASEDIR/bin/mysql -uroot --socket=$SOCKET --silent -e "SELECT CONCAT('ALTER TABLE ', table_schema, '.', table_name, ' DROP ', column_name, ';') FROM information_schema.columns WHERE IS_GENERATED = 'ALWAYS' AND table_schema NOT IN ('mysql','information_schema','performance_schema')" > /tmp/mdev18084.sql
    cat /tmp/mdev18084.sql | $BASEDIR/bin/mysql -uroot --socket=$SOCKET
    ;;
  esac
  ;;
esac

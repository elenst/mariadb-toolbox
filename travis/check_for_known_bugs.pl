#!/usr/bin/perl

use strict;

# If a file with an exact name does not exist, it will prevent grep from working.
# So, we want to exclude such files

my @expected_files= glob "@ARGV";
my @files;
map { push @files, $_ if -e $_ } @expected_files;

my %found_mdevs= ();
my %fixed_mdevs= ();
my $matches_info= '';

my $mdev;
my $pattern;

while (<DATA>) {

  if (/^\# Weak matches/) {
    # Don't search for weak matches if strong ones have been found
    if ($matches_info) {
      print "--- STRONG matches -----------------------\n";
      print $matches_info;
      $matches_info= '';
      last;
    }
    $mdev= undef;
    next;
  }

  if(/^\s*(MDEV-\d+):\s*(.*)/) {
    $mdev= $1;
    next;
  }
  elsif (/^(\-e.*)/) {
    next if $found_mdevs{$mdev}; # Don't search for other MDEV patterns if one was already found
    $pattern= $1;
  }
  else {
    # Skip comments and whatever else
    next;
  }

  chomp $pattern;
  $pattern=~ s/-e '/grep -h -E -e '/g;
  system("$pattern @files > /dev/null 2>&1");
  unless ($?) {
    $found_mdevs{$mdev}= 1;

    unless (-e "/tmp/$mdev.resolution") {
      system("wget https://jira.mariadb.org//rest/api/2/issue/$mdev?fields=resolution -O /tmp/$mdev.resolution -o /dev/null");
    }

    my $resolution= `cat /tmp/$mdev.resolution`;
    my $resolutiondate;
    if ($resolution=~ s/.*\"name\":\"([^\"]+)\".*/$1/) {
      unless (-e "/tmp/$mdev.resolutiondate") {
        system("wget https://jira.mariadb.org//rest/api/2/issue/$mdev?fields=resolutiondate -O /tmp/$mdev.resolutiondate -o /dev/null");
      }
      $resolution= uc($resolution);
      $resolutiondate= `cat /tmp/$mdev.resolutiondate`;
      unless ($resolutiondate=~ s/.*\"resolutiondate\":\"(\d\d\d\d-\d\d-\d\d).*/$1/) {
        $resolutiondate= '';
      }
    } else {
      $resolution= 'Unresolved';
    }

    $fixed_mdevs{$mdev} = $resolutiondate if $resolution eq 'FIXED';

    unless (-e "/tmp/$mdev.summary") {
      system("wget https://jira.mariadb.org//rest/api/2/issue/$mdev?fields=summary -O /tmp/$mdev.summary -o /dev/null");
    }

    my $summary= `cat /tmp/$mdev.summary`;
    if ($summary =~ /\{\"summary\":\"(.*?)\"\}/) {
      $summary= $1;
    }
    
    if ($resolution eq 'FIXED' and not -e "/tmp/$mdev.fixVersions") {
      system("wget https://jira.mariadb.org//rest/api/2/issue/$mdev?fields=fixVersions -O /tmp/$mdev.fixVersions -o /dev/null");
    }

    unless (-e "/tmp/$mdev.affectsVersions") {
      system("wget https://jira.mariadb.org//rest/api/2/issue/$mdev?fields=versions -O /tmp/$mdev.affectsVersions -o /dev/null");
    }

    my $affectsVersions= `cat /tmp/$mdev.affectsVersions`;
    my @affected = ($affectsVersions =~ /\"name\":\"(.*?)\"/g);

    $matches_info .= "$mdev: $summary\n";

    if ($resolution eq 'FIXED') {
      my $fixVersions= `cat /tmp/$mdev.fixVersions`;
      my @versions = ($fixVersions =~ /\"name\":\"(.*?)\"/g);
      $matches_info .= "Fix versions: @versions ($resolutiondate)\n";
    }
    else {
      $matches_info .= "RESOLUTION: $resolution". ($resolutiondate ? " ($resolutiondate)" : "") . "\n";
      $matches_info .= "Affects versions: @affected\n";
    }
    $matches_info .= "-------------\n";
  }
}

# If it's non-empty at this point, it's weak matches
if ($matches_info) {
  print "--- WEAK matches ---------------------\n";
  print $matches_info;
  print "--------------------------------------\n";
}

if (keys %fixed_mdevs) {
  print "\n--- ATTENTION! FOUND FIXED MDEVs: ----\n";
  foreach my $m (sort keys %fixed_mdevs) {
    print "\t$m: $fixed_mdevs{$m}\n";
  }
  print "--------------------------------------\n";
}

__DATA__

# Strong matches

MDEV-18467:
-e 'fix_semijoin_strategies_for_picked_join_order'

MDEV-18461:
-e 'sure_page <= last_page'
-e 'head_length == row_pos->length'

MDEV-18460:
-e 'THD::create_tmp_table_def_key'

MDEV-18459:
-e 'fil_op_write_log'

MDEV-18458:
-e 'EVP_MD_CTX_cleanup'

MDEV-18457:
-e 'bitmap->full_head_size'

MDEV-18456:
-e 'item->maybe_null'

MDEV-18454:
-e 'ReadView::check_trx_id_sanity'

MDEV-18452:
-e 'Field::set_default'

MDEV-18451:
-e 'maria_create_trn_for_mysql'

MDEV-18449:
-e 'my_strnncollsp_simple'

MDEV-18447:
-e 'Timestamp_or_zero_datetime::tv'

MDEV-18441:
-e 'tables_opened == 1'

MDEV-18421:
-e 'foreign->foreign_table'

MDEV-18418:
-e 'mdl_ticket->m_type == MDL_SHARED_UPGRADABLE'

MDEV-18414:
-e 'Value_source::Converter_strntod::Converter_strntod'

MDEV-18388:
-e 'thd->spcont'

MDEV-18381:
-e 'ha_innobase::store_lock'

MDEV-18377:
-e 'recv_sys->mlog_checkpoint_lsn'

MDEV-18371:
-e 'ha_innobase::cmp_ref'

MDEV-18369:
-e 'wsrep_handle_SR_rollback'

MDEV-18343:
-e 'Mutex RW_LOCK_LIST created sync0debug.cc'

MDEV-18339:
-e 'Item_exists_subselect::is_top_level_item'

MDEV-18316:
-e 'dict_col_t::instant_value'

MDEV-18315:
-e 'col->same_format'

MDEV-18310:
-e 'Got error 121 when executing undo undo_key_delete'

MDEV-18300:
-e 'Field_blob::get_key_image'

MDEV-18291:
-e 'dict_mem_table_free'
-e 'ha_innobase_inplace_ctx::'

MDEV-18286:
-e 'pagecache->cnt_for_resize_op == 0'

MDEV-18274:
-e 'new_clustered =='

MDEV-18272:
-e 'cursor->index->is_committed'

MDEV-18259:
-e 'get_foreign_key_info'

MDEV-18258:
-e 'append_identifier'

MDEV-18244:
-e 'ha_partition::update_next_auto_inc_val'

MDEV-18239:
-e 'mark_unsupported_function'

MDEV-18220:
-e 'fts_get_table_name_prefix'

MDEV-18219:
-e 'index->n_core_null_bytes <='

MDEV-18216:
-e 'Query_arena::set_query_arena'

MDEV-18213:
-e 'Error: failed to execute query BACKUP STAGE BLOCK_COMMIT: Deadlock found when trying to get lock'

MDEV-18209:
-e 'Enabling keys got errno 0 on'

MDEV-18205:
-e 'str_length < len'

MDEV-18204:
-e 'RocksDB: Problems validating data dictionary against .frm files, exiting'

MDEV-18203:
-e 'error 126 when executing undo undo_key_insert'

MDEV-18200:
-e 'InnoDB: Failing assertion: success'

MDEV-18187:
-e 'error 192 when executing record redo_index_new_page'

MDEV-18173:
-e 'col.vers_sys_end'
-e 'o->ind == vers_end'
-e 'o->ind == vers_start'

MDEV-18171:
-e '_ma_write_blob_record'

MDEV-18170:
-e 'pcur.old_rec_buf'

MDEV-18169:
-e 'n_fields <= ulint'

MDEV-18167:
-e 'table->s->reclength'

MDEV-18166:
-e 'table->s->reclength'

MDEV-18160:
-e 'index->n_fields >= n_core'

MDEV-18157:
-e 'Explain_node::print_explain_for_children'

MDEV-18152:
-e 'num_fts_index <= 1'

MDEV-18150:
-e 'decimals_to_set <= 38'

MDEV-18147:
-e 'templ->mysql_col_len >= len'

MDEV-18146:
-e 'field_ref + 12U'

MDEV-18122:
-e '== m_prebuilt->table->versioned'

MDEV-18121:
-e 'type.vers_sys_end'

MDEV-18090:
-e 'table->s->fields + 3'

MDEV-18088:
-e 'share->in_trans == 0'

MDEV-18085:
-e 'len >= col->mbminlen'

MDEV-18084:
-e 'pos < index->n_def'
-e 'pos < table->n_v_def'

MDEV-18083:
-e 'Field::set_warning_truncated_wrong_value'

MDEV-18082:
-e 'Diagnostics_area::disable_status'

MDEV-18078:
-e 'trnman_has_locked_tables'

MDEV-18077:
-e 'n < tuple->n_fields'

MDEV-18070:
-e 'nanoseconds <= 1000000000'

MDEV-18068:
-e 'this == ticket->get_ctx'

MDEV-18067:
-e 'ticket->m_duration == MDL_EXPLICIT'

MDEV-18057:
-e 'node->state == 5'

MDEV-18054:
-e 'ret > 0'

MDEV-18047:
-e 'index->magic_n == 76789786'
-e 'pos < index->n_def'

MDEV-18046:
-e 'var_header_len >= 2'

MDEV-18039:
-e 'index->table->name.m_name'

MDEV-18033:
-e 'n < update->n_fields'

MDEV-18020:
-e 'prebuilt->trx->check_foreigns'
-e 'ctx->prebuilt->trx->check_foreigns'
-e 'm_prebuilt->trx->check_foreigns'

MDEV-18018:
-e 'TABLE_LIST::reinit_before_use'

MDEV-18017:
-e 'index->to_be_dropped'

MDEV-18016:
-e 'storage/innobase/dict/dict0dict.cc line 6199'
-e 'storage/innobase/dict/dict0dict.cc line 6346'
-e 'storage/innobase/dict/dict0dict.cc line 6181'

MDEV-18003:
-e 'grantee->counter > 0'

MDEV-17977:
-e 'Count >= rest_length'

MDEV-17976:
-e 'lock->magic_n == 22643'

MDEV-17969:
-e 'THD::push_warning_truncated_value_for_field'

MDEV-17964:
-e 'status == 0'

MDEV-17959:
-e 'thd->lex->select_stack_top == 0'

MDEV-17939:
-e '++loop_count < 2'

MDEV-17912:
-e 'Aria engine: Redo phase failed'

MDEV-17895:
-e 'trx->dict_operation != TRX_DICT_OP_NONE'

MDEV-17893:
-e 'nulls < null_mask'

MDEV-17892:
-e 'index->was_not_null'

MDEV-17891:
-e 'thd->transaction.stmt.modified_non_trans_table'

MDEV-17854:
-e 'decimals <= 6'

MDEV-17843:
-e 'page_rec_is_leaf'

MDEV-17838:
-e 'in Item_field::rename_fields_processor'

MDEV-17821:
-e 'page_rec_is_supremum'

MDEV-17816:
-e 'trx->dict_operation_lock_mode == RW_X_LATCH'

MDEV-17815:
-e 'index->table->name.m_name'

MDEV-17763:
-e 'len == 20U'

MDEV-17759:
-e 'precision > 0'

MDEV-17596:
-e 'block->page.flush_observer == __null'

MDEV-17576:
-e 'share->reopen == 1'

MDEV-17551:
-e '_ma_state_info_write'

MDEV-17479:
-e 'mysql_socket.fd != -1'

MDEV-17333:
-e 'next_insert_id >= auto_inc_interval_for_cur_row.minimum'

MDEV-17319:
-e 'ts_type != MYSQL_TIMESTAMP_TIME'

MDEV-17225:
-e 'log_descriptor.bc.buffer->prev_last_lsn'

MDEV-17223:
-e 'thd->killed != 0'

MDEV-17199:
-e 'pos < table->n_v_def'

MDEV-17091:
-e 'part_id == m_last_part'
-e 'old_part_id == m_last_part'

MDEV-17054:
-e 'InnoDB needs charset 0 for doing a comparison, but MySQL cannot find that charset'

MDEV-17015:
-e 'm_year <= 9999'

MDEV-16994:
-e 'Alloced_length >='

MDEV-16962:
-e 'ot_ctx.can_recover_from_failed_open'

MDEV-16958:
-e 'field_length < 5'

MDEV-16940:
-e 'unsafe_key_update'

MDEV-16903:
-e 'auto_increment_field_not_null'

MDEV-16788:
-e 'ls->length < 0xFFFFFFFFL'

MDEV-16659:
-e 'anc_page->org_size == anc_page->size'

MDEV-16654:
-e 'returned 38 for ALTER TABLE'
-e 'ha_innodb::commit_inplace_alter_table'

MDEV-16539:
-e 'THD::mark_tmp_table_as_free_for_reuse'

MDEV-16523:
-e 'level_and_file.second->being_compacted'

MDEV-16501:
-e '->coll->strcasecmp'

MDEV-16500:
-e 'user_table->n_def > table->s->fields'

MDEV-16154:
-e 'in myrocks::ha_rocksdb::load_auto_incr_value_from_index'

MDEV-15912:
-e 'purge_sys.tail.commit <= purge_sys.rseg->last_commi'

MDEV-15878:
-e 'table->file->stats.records > 0'

MDEV-15800:
-e 'next_insert_id >= auto_inc_interval_for_cur_row.minimum'

MDEV-15776:
-e 'user_table->get_ref_count'

MDEV-15744:
-e 'derived->table'

MDEV-15656:
-e 'is_last_prefix <= 0'

MDEV-15653:
-e 'lock_word <= 0x20000000'

MDEV-15481:
-e 'I_P_List_null_counter, I_P_List_fast_push_back'

MDEV-15308:
-e 'ha_alter_info->alter_info->drop_list.elements > 0'

MDEV-15164:
-e 'ikey_.type == kTypeValue'

MDEV-15115:
-e 'dict_tf2_is_valid'

MDEV-15130:
-e 'table->s->null_bytes == 0'

MDEV-14906:
-e 'index->is_instant'

MDEV-14711:
-e 'fix_block->page.file_page_was_freed'

MDEV-14643:
-e 'cursor->index->is_committed'

MDEV-14642:
-e 'table->s->db_create_options == part_table->s->db_create_options'

MDEV-14557:
-e 'm_sp == __null'

MDEV-14410:
-e 'table->pos_in_locked_tables->table == table'

MDEV-14126:
-e 'page_get_page_no'

MDEV-13644:
-e 'prev != 0 && next != 0'

MDEV-13202:
-e 'ltime->neg == 0'

MDEV-12978:
-e 'log_calc_max_ages'

MDEV-12329:
-e '1024U, trx, rec, block'

MDEV-11783:
-e 'checksum_length == f->ptr'

MDEV-11080:
-e 'table->n_waiting_or_granted_auto_inc_locks > 0'

MDEV-10748:
-e 'ha_maria::implicit_commit'

MDEV-654:
-e 'share->now_transactional'

# Weak matches

MDEV-18485:
-e 'in create_tmp_table'
-e 'in Field::is_null'
-e 'in Field::is_null_in_record'

MDEV-18453:
-e 'rec_get_deleted_flag'

MDEV-18325:
-e 'is in the future'

MDEV-18322:
-e 'wrong page type'

MDEV-18321:
-e 'ha_innodb::commit_inplace_alter_table'
-e 'ha_innobase::commit_inplace_alter_table'

MDEV-18309:
-e 'InnoDB: Cannot open datafile for read-only:'

MDEV-18285:
-e 'Diagnostics_area::disable_status'

MDEV-18272:
-e 'InnoDB: tried to purge non-delete-marked record in index'

MDEV-18260:
-e 'pagecache_unlock_by_link'

MDEV-18256:
-e 'heap->magic_n == MEM_BLOCK_MAGIC_N'
-e 'dict_foreign_remove_from_cache'

MDEV-18255:
-e 'Item_field::update_table_bitmaps'

MDEV-18222:
-e 'heap->magic_n == MEM_BLOCK_MAGIC_N'
-e 'innobase_rename_column_try'
-e 'dict_foreign_remove_from_cache'

MDEV-18217:
-e 'InnoDB: Summed data size'
-e 'row_sel_field_store_in_mysql_format_func'

MDEV-18207:
-e '_ma_get_status'

MDEV-18195:
-e 'Item::eq'
-e 'lex_string_cmp'

MDEV-18194:
-e 'which is outside the tablespace bounds'

MDEV-18185:
-e 'rename_table_in_prepare'

MDEV-18168:
-e 'general_log_write'

MDEV-18162:
-e 'dict_index_t::reconstruct_fields'

MDEV-18084:
-e 'dict_index_get_nth_field'
-e 'row_upd_changes_some_index_ord_field_binary'

MDEV-18083:
-e 'in intern_close_table'
-e 'tc_purge'

MDEV-18083:
-e 'tc_remove_all_unused_tables'
-e 'make_truncated_value_warning'
-e 'Column_definition::Column_definition'

MDEV-18047:
-e 'dict_foreign_qualify_index'
-e 'InnoDB indexes are inconsistent with what defined'
-e 'cmp_cols_are_equal'

MDEV-17976:
-e 'rec_get_offsets_func'

MDEV-17678:
-e 'in Field::is_null'
-e 'in print_keydup_error'

MDEV-17187:
-e 'failed, the table has missing foreign key indexes'

MDEV-16222:
-e 'InnoDB: tried to purge non-delete-marked record in index'

MDEV-15947:
-e 'Error: Freeing overrun buffer'
-e 'in find_field_in_tables'

MDEV-15776:
-e 'commit_try_rebuild'
-e 'table->get_ref_count'

MDEV-14440:
-e 'pure virtual method called'


MDEV-5628:
-e 'Diagnostics_area::set_ok_status'

MDEV-5791:
-e 'in Field::is_real_null'

MDEV-5924:
-e 'Query_cache::register_all_tables'

MDEV-6453:
-e 'int handler::ha_rnd_init'

MDEV-8203:
-e 'rgi->tables_to_lock'

MDEV-9137:
-e 'in _ma_ck_real_write_btree'

MDEV-10945:
-e 'Diagnostics_area::set_ok_status'

MDEV-11015:
-e 'precision > 0'

MDEV-11539:
-e 'mi_open.c:67: test_if_reopen'

MDEV-12059:
-e 'precision > 0'

MDEV-13024:
-e 'in multi_delete::send_data'

MDEV-13103:
-e 'fil0pagecompress.cc:[0-9]+: void fil_decompress_page'

MDEV-13231:
-e 'in _ma_unique_hash'

MDEV-13699:
-e '== new_field->field_name.length'

MDEV-13828:
-e 'in handler::ha_index_or_rnd_end'

MDEV-14040:
-e 'in Field::is_real_null'

MDEV-14041:
-e 'in String::length'

MDEV-14264:
-e 'binlog_cache_data::reset'

MDEV-14407:
-e 'trx_undo_rec_copy'

MDEV-14472:
-e 'is_current_stmt_binlog_format_row'

MDEV-14693:
-e 'clust_index->online_log'

MDEV-14697:
-e 'in TABLE::mark_default_fields_for_write'

MDEV-14762:
-e 'has_stronger_or_equal_type'

MDEV-14815:
-e 'in has_old_lock'

MDEV-14825:
-e 'col->ord_part'

MDEV-14833:
-e 'trx->error_state == DB_SUCCESS'

MDEV-14836:
-e 'm_status == DA_ERROR'

MDEV-14846:
-e 'prebuilt->trx, TRX_STATE_ACTIVE'
-e 'state == TRX_STATE_FORCED_ROLLBACK'

MDEV-14862:
-e 'in add_key_equal_fields'

MDEV-14864:
-e 'in mysql_prepare_create_table'
-e 'in mysql_prepare_alter_table'

MDEV-14894:
-e 'tdc_remove_table'
-e 'table->in_use == thd'

MDEV-14905:
-e 'purge_sys->state == PURGE_STATE_INIT'

MDEV-14994:
-e 'join->best_read < double'

MDEV-14996:
-e 'int ha_maria::external_lock'

MDEV-15011:
-e 'decimal2bin'

MDEV-15013:
-e 'trx->state == TRX_STATE_NOT_STARTED'
-e 'virtual ha_rows ha_partition::part_records'

MDEV-15130:
-e 'static void PFS_engine_table::set_field_char_utf8'

MDEV-15161:
-e 'in get_addon_fields'

MDEV-15175:
-e 'Item_temporal_hybrid_func::val_str_ascii'

MDEV-15216:
-e 'm_can_overwrite_status'

MDEV-15217:
-e 'transaction.xid_state.xid.is_null'

MDEV-15226:
-e 'Could not get index information for Index Number'

MDEV-15245:
-e 'myrocks::ha_rocksdb::position'

MDEV-15255:
-e 'm_lock_type == 2'
-e 'sequence_insert'

MDEV-15257:
-e 'm_status == DA_OK_BULK'

MDEV-15319:
-e 'myrocks::ha_rocksdb::convert_record_from_storage_format'

MDEV-15329:
-e 'in dict_table_check_for_dup_indexes'

MDEV-15330:
-e 'table->insert_values'

MDEV-15336:
-e 'ha_partition::print_error'

MDEV-15374:
-e 'trx_undo_rec_copy'

MDEV-15391:
-e 'join->best_read < double'

MDEV-15401:
-e 'Item_direct_view_ref::used_tables'

MDEV-15458:
-e 'in heap_scan'

MDEV-15464:
-e 'in TrxUndoRsegsIterator::set_next'
-e 'purge_sys.purge_queue.top'

MDEV-15465:
-e 'Item_func_match::cleanup'

MDEV-15468:
-e 'table_events_waits_common::make_row '

MDEV-15470:
-e 'TABLE::mark_columns_used_by_index_no_reset'

MDEV-15471:
-e 'new_clustered == ctx->need_rebuild'

MDEV-15482:
-e 'Type_std_attributes::set'

MDEV-15484:
-e 'element->m_flush_tickets.is_empty'

MDEV-15486:
-e 'String::needs_conversion'

MDEV-15490:
-e 'in trx_update_mod_tables_timestamp'

MDEV-15493:
-e 'lock_trx_table_locks_remove'

MDEV-15533:
-e 'log->blobs'

MDEV-15551:
-e 'share->last_version'

MDEV-15572:
-e 'ha_maria::end_bulk_insert'

MDEV-15576:
-e 'item->null_value'

MDEV-15657:
-e 'file->inited == handler::NONE'

MDEV-15658:
-e 'expl_lock->trx == arg->impl_trx'

MDEV-15742:
-e 'm_lock_type == 1'

MDEV-15753:
-e 'thd->is_error'

MDEV-15802:
-e 'Item::delete_self'

MDEV-15812:
-e 'virtual handler::~handler'

MDEV-15816:
-e 'm_lock_rows == RDB_LOCK_WRITE'

MDEV-15873:
-e 'precision > 0'

MDEV-15907:
-e 'in fill_effective_table_privileges'

MDEV-15949:
-e 'space->n_pending_ops == 0'

MDEV-15950:
-e 'find_dup_table'
-e 'find_table_in_list'

MDEV-15977:
-e 'thd->in_sub_stmt'

MDEV-16060:
-e 'Failing assertion: ut_strcmp'

MDEV-16131:
-e 'id == DICT_INDEXES_ID'

MDEV-16169:
-e 'space->referenced'

MDEV-16170:
-e 'Item_null_result::type_handler'

MDEV-16171:
-e 'in setup_table_map'

MDEV-16184:
-e 'nest->counter > 0'

MDEV-16190:
-e 'in Item_null_result::field_type'

MDEV-16240:
-e 'row_sel_convert_mysql_key_to_innobase'
-e 'Slave worker thread retried transaction'

MDEV-16242:
-e 'Can't find record'

MDEV-16292:
-e 'Item_func::print'

MDEV-16397:
-e 'Can't find record in'

MDEV-16407:
-e 'in MDL_key::mdl_key_init'
-e 'Error: Freeing overrun buffer'

MDEV-16499:
-e 'from the internal data dictionary of InnoDB though the .frm file for the table exists'
-e 'is corrupted. Please drop the table and recreate'

MDEV-16501:
-e 'in dict_mem_table_col_rename'

MDEV-16635:
-e 'sequence_insert'

MDEV-16549:
-e 'Item_direct_view_ref::fix_fields'

MDEV-16699:
-e 'my_strnncollsp_binary'

MDEV-16738:
-e '== Item_func::MULT_EQUAL_FUNC'

MDEV-16745:
-e 'thd->transaction.stmt.is_empty'

MDEV-16789:
-e 'in insert_fields'

MDEV-16792:
-e 'in Diagnostics_area::sql_errno'

MDEV-16794:
-e 'thd->transaction.stmt.is_empty'

MDEV-16905:
-e 'TABLE::verify_constraints'

MDEV-16929:
-e 'thd->transaction.stmt.is_empty'

MDEV-16932:
-e 'Well_formed_prefix_status::Well_formed_prefix_status'
-e 'lex_string_cmp'
-e 'my_strcasecmp_utf8'

MDEV-16957:
-e 'Field_iterator_natural_join::next'

MDEV-16971:
-e 'adjust_time_range_or_invalidate'

MDEV-16980:
-e '== table_name_arg->length'

MDEV-16982:
-e 'in mem_heap_dup'
-e 'row_mysql_convert_row_to_innobase'

MDEV-16992:
-e 'Field_iterator_table_ref::set_field_iterator'

MDEV-16994:
-e 'in base_list_iterator::next'
-e 'partition_info::prune_partition_bitmaps'

MDEV-17004:
-e 'in innobase_get_fts_charset'

MDEV-17005:
-e 'innobase_get_computed_value'

MDEV-17016:
-e 'auto_increment_safe_stmt_log_lock'

MDEV-17019:
-e 'multi_delete::~multi_delete'

MDEV-17020:
-e 'length > 0'

MDEV-17051:
-e 'sec_mtr->has_committed'

MDEV-17053:
-e 'sync_check_iterate'

MDEV-17054:
-e 'in innobase_get_fts_charset'

MDEV-17055:
-e 'find_order_in_list'

MDEV-17107:
-e 'table_list->table'

MDEV-17120:
-e 'base_list::push_back'

MDEV-17216:
-e '!dt->fraction_remainder'

MDEV-17217:
-e 'in make_sortkey'

MDEV-17257:
-e 'in get_datetime_value'
-e 'in Item::field_type_for_temporal_comparison'

MDEV-17275:
-e 'Diagnostics_area::set_ok_status'

MDEV-17307:
-e 'Incorrect key file for table'

MDEV-17319:
-e 'int Field_temporal::store_invalid_with_warning'
MDEV_17344:
-e 'Prepared_statement::~Prepared_statement'

MDEV-17356:
-e 'table->read_set, field_index'

MDEV-17361:
-e 'in Query_arena::set_query_arena'
-e 'THD::set_n_backup_active_arena'

MDEV-17464:
-e 'Operating system error number 2'

MDEV-17466:
-e 'dfield2->type.mtypex'

MDEV-17485:
-e 'Operating system error number 80 in a file operation'

MDEV-17538:
-e '== UNALLOCATED_PAGE'

MDEV-17539:
-e 'Protocol::end_statement'

MDEV-17540:
-e 'dict_table_get_first_index'

MDEV-17556:
-e 'bitmap_is_set_all'
-e 'table->s->all_set'

MDEV-17580:
-e 'Diagnostics_area::set_ok_status'

MDEV-17582:
-e 'status_var.local_memory_used == 0'

MDEV-17583:
-e 'next_mrec == next_mrec_end'

MDEV-17595:
-e 'copy_data_between_tables'
-e 'Open_tables_state::BACKUPS_AVAIL'
-e 'close_tables_for_reopen'

MDEV-17619:
-e 'Index file is crashed'
-e 'Table is crashed and last repair failed'
-e 'Incorrect key file for table'
-e 'Got an error from thread_id='
-e 'Couldn't repair table'

MDEV-17622:
-e 'type == PAGECACHE_LSN_PAGE'

MDEV-17627:
-e 'handler::ha_rnd_end'

MDEV-17636:
-e 'pagecache->block_root'

MDEV-17659:
-e 'File too short; Expected more data in file'

MDEV-17665:
-e 'share->page_type == PAGECACHE_LSN_PAGE'

MDEV-17711:
-e 'arena_for_set_stmt== 0'

MDEV-17725:
-e 'm_status == DA_OK_BULK'

MDEV-17738:
-e 'Item::delete_self'
-e 'st_select_lex::fix_prepare_information'
-e 'TABLE_LIST::change_refs_to_fields'
-e 'in change_group_ref'

MDEV-17741:
-e 'thd->Item_change_list::is_empty'

MDEV-17760:
-e 'table->read_set, field_index'

MDEV-17717:
-e 'table->pos_in_locked_tables'

MDEV-17814:
-e 'is_current_stmt_binlog_format_row'

MDEV-17818:
-e 'parse_vcol_defs'

MDEV-17820:
-e '== BTR_NO_LOCKING_FLAG'

MDEV-17826:
-e 'dfield_is_ext'

MDEV-17830:
-e 'Item_null_result::field_type'

MDEV-17831:
-e 'supports_instant'

MDEV-17834:
-e 'row_upd_build_difference_binary'

MDEV-17837:
-e 'm_status == DA_OK_BULK'

MDEV-17842:
-e 'pfs_lock::allocated_to_free'

MDEV-17843:
-e 'lock_rec_queue_validate'

MDEV-17844:
-e 'rec_offs_validate'

MDEV-17857:
-e 'TIME_from_longlong_datetime_packed'

MDEV-17884:
-e 'is marked as crashed and should be repaired'

MDEV-17890:
-e 'row_upd_sec_index_entry'
-e 'row_upd_build_difference_binary'

MDEV-17896:
-e 'pfs->get_refcount'

MDEV-17897:
-e 'block->frame'

MDEV-17904:
-e 'fts_is_sync_needed'

MDEV-17923:
-e 'trx_undo_page_report_modify'

MDEV-17932:
-e 'get_username'

MDEV-17936:
-e 'Field::is_null'

MDEV-17962:
-e 'setup_jtbm_semi_joins'

MDEV-17971:
-e 'Field_iterator_table::set'
-e 'Field_iterator_table_ref::set_field_iterator'

MDEV-17972:
-e 'is_valid_value_slow'

MDEV-17974:
-e 'sp_process_definer'

MDEV-17978:
-e 'mysqld_show_create_get_fields'

MDEV-17979:
-e 'Item::val_native'

MDEV-17998:
-e 'table->pos_in_locked_tables'

MDEV-17999:
-e 'Invalid roles_mapping table entry user'

MDEV-18016:
-e 'dict_table_check_for_dup_indexes'

MDEV-18042:
-e 'mysql_alter_table'

MDEV-18046:
-e 'in Rotate_log_event::Rotate_log_event'
-e 'binlog_get_uncompress_len'
-e 'm_field_metadata_size <='
-e 'in inline_mysql_mutex_destroy'
-e 'Update_rows_log_event::~Update_rows_log_event'

MDEV-18054:
-e 'mach_read_from_1'

MDEV-18058:
-e 'trx0i_s.cc line'

MDEV-18062:
-e 'ha_innobase::innobase_get_index'

MDEV-18063:
-e 'is corrupt; try to repair it'

MDEV-18065:
-e 'Fatal error: Can't open and lock privilege tables'

MDEV-18067:
-e 'backup_end'

MDEV-18069:
-e 'MDL_lock::incompatible_granted_types_bitmap'
-e 'MDL_ticket::has_stronger_or_equal_type'

MDEV-18086:
-e 'rec_get_converted_size_comp_prefix_low'

MDEV-18087:
-e 'mach_read_from_n_little_endian'

MDEV-18139:
-e 'Table rename would cause two FOREIGN KEY constraints'

MDEV-18141:
-e 'Can't find record in'

MDEV-18145:
-e 'Item_singlerow_subselect::val_native'

MDEV-18146:
-e 'btr_page_reorganize_low'
-e 'merge_page, index'

MDEV-18148:
-e 'ha_maria::end_bulk_insert'

MDEV-18149:
-e 'row_parse_int'

MDEV-18151:
-e 'Protocol::end_statement'

MDEV-18153:
-e 'is corrupt; try to repair it'
-e 'was not found on update: TUPLE'
-e 'row_upd_sec_index_entry'

MDEV-18156:
-e 'is corrupt; try to repair it'
-e 'was not found on update: TUPLE'
-e 'row_upd_sec_index_entry'

MDEV-18158:
-e 'Can't find record in'

# Fixed:
# MDEV-4312: make_lock_and_pin
# MDEV-10130: share->in_trans == 0
# MDEV-10130: file->trn == trn
# MDEV-11071: thd->transaction.stmt.is_empty
# MDEV-11071: in THD::mark_tmp_table_as_free_for_reuse
# MDEV-11167: Can't find record
# MDEV-11741: table->s->all_set
# MDEV-11741: in ha_heap::rnd_next
# MDEV-11741: in handler::ha_reset
# MDEV-11741: mi_reset
# MDEV-11741: old_top == initial_top
# MDEV-14100: dict_index_get_n_unique_in_tree_nonleaf
# MDEV-14134: dberr_t row_upd_sec_index_entry
# MDEV-14409: page_rec_is_leaf
# MDEV-14440: inited==RND
# MDEV-14440: in ha_partition::external_lock
# MDEV-14695: n < m_size
# MDEV-14743: Item_func_match::init_search
# MDEV-14829: protocol.cc:588: void Protocol::end_statement
# MDEV-14943: type == PAGECACHE_LSN_PAGE
# MDEV-15060: row_log_table_apply_op
# MDEV-15114: mem_heap_dup
# MDEV-15114: dberr_t row_upd_sec_index_entry
# MDEV-15243: in Field_blob::pack
# MDEV-15475: table->read_set, field_index
# MDEV-15537: in mysql_prepare_alter_table
# MDEV-15626: old_part_id == m_last_part
# MDEV-15729: in Field::make_field
# MDEV-15729: Field::make_send_field
# MDEV-15729: send_result_set_metadata
# MDEV-15738: in my_strcasecmp_utf8
# MDEV-15797: thd->killed != 0
# MDEV-15380: is corrupt; try to repair it
# MDEV-15828: num_fts_index <= 1
# MDEV-15855: innobase_get_computed_value
# MDEV-15855: innobase_allocate_row_for_vcol
# MDEV-15872: row_log_table_get_pk_col
# MDEV-15872: in mem_heap_dup
# MDEV-16043: st_select_lex::fix_prepare_information
# MDEV-16043: thd->Item_change_list::is_empty
# MDEV-16153: Apc_target::disable
# MDEV-16166: Can't find record in
# MDEV-16217: table->read_set, field_index
# MDEV-16241: inited==RND
# MDEV-16429: table->read_set, field_index
# MDEV-16512: in find_field_in_tables
# MDEV-16682: == HEAD_PAGE
# MDEV-16682: in _ma_read_block_record
# MDEV-16779: rw_lock_own
# MDEV-16783: in mysql_delete
# MDEV-16783: !conds
# MDEV-16961: table->read_set, field_index
# MDEV-17021: length <= column->length
# MDEV-17021: in write_block_record
# MDEV-17027: table_list->table
# MDEV-17027: Field_iterator_table_ref::set_field_iterator
# MDEV-17027: in add_key_field
# MDEV-17167: table->get_ref_count
# MDEV-17215: in row_purge_remove_clust_if_poss_low
# MDEV-17215: in row_purge_upd_exist_or_extern_func
# MDEV-17219: !dt->fraction_remainder
# MDEV-17314: thd->transaction.stmt.is_empty
# MDEV-17349: table->read_set, field_index
# MDEV-17354: in add_key_field
# MDEV-17432: lock_trx_has_sys_table_locks
# MDEV-17470: Operating system error number 17 in a file operation
# MDEV-17470: returned OS error 71. Cannot continue operation
# MDEV-17697: col.vers_sys_end
# MDEV-17755: table->s->reclength
# MDEV-17823: row_sel_sec_rec_is_for_clust_rec
# MDEV-17885: Could not remove temporary table
# MDEV-17901: row_parse_int
# MDEV-17938: block->magic_n == MEM_BLOCK_MAGIC_N
# MDEV-17938: dict_mem_table_free
# MDEV-17975: m_status == DA_OK_BULK
# MDEV-18072: == item->null_value
# MDEV-18076: in row_parse_int
# MDEV-18183: id != LATCH_ID_NONE
# MDEV-18183: OSMutex::enter
# MDEV-18218: btr_page_reorganize_low

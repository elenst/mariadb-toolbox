# thread1_init:
#	LOCK TABLE `t7` WRITE ; CREATE TEMPORARY TABLE A AS SELECT * FROM `t7` ; SELECT MAX(`emitente_id`) INTO @a FROM A; UPDATE A SET `emitente_id` = `emitente_id` + @a ; INSERT IGNORE INTO `t7` SELECT * FROM A ; UPDATE A SET `emitente_id` = `emitente_id` + @a ; INSERT IGNORE INTO `t7` SELECT * FROM A ; DROP TEMPORARY TABLE A ; UNLOCK TABLES ;

query:
	select | select | roberto_select ;

roberto_select:
	SELECT distinct roberto_select_item FROM `t7` WHERE `emitente_tipo` comparison_operator emitente_enum AND `emitente_id` comparison_operator _digit AND `emitente_propriedade` comparison_operator _digit AND `nf_serie` = '3nfe' AND `nf` comparison_operator _digit ;


roberto_select_item:
	* | COUNT(*) | primary_key | my_field, my_field, my_field, my_field ;

emitente_enum:
	'j' | 'f' | '' | ' ' ;

select:
	SELECT distinct * FROM `t7` index_hint WHERE where order_by_limit |
	SELECT distinct * FROM `t7` index_hint WHERE where order_by_limit |
	SELECT distinct * FROM `t7` index_hint WHERE where order_by_limit |
	SELECT distinct * FROM `t7` index_hint WHERE where order_by_limit |
	SELECT aggregate int_key ) FROM `t7` index_hint WHERE where |
	SELECT int_key , aggregate int_key ) FROM `t7` index_hint WHERE where GROUP BY 1 ;

distinct:
	| | DISTINCT ;

order_by_limit:
	| ORDER BY any_key asc_desc, any_key asc_desc | ORDER BY primary_key asc_desc limit ;

asc_desc:
	| ASC | DESC ;

primary_key:
	`emitente_tipo`,`emitente_id`,`emitente_propriedade`,`nf_serie`,`nf`,`id_item` ;

limit:
	| LIMIT _digit
	| LIMIT _tinyint_unsigned;

where:
	where_list and_or where_list ;

where_list:
	where_two and_or ( where_list ) |
	where_two and_or where_two |
	where_two and_or where_two and_or where_two |
	where_two ;

where_two:
	( integer_item or_and integer_item ) |
	( string_item or_and string_item );

integer_item:
	not ( int_key comparison_operator integer_value ) |
	not ( int_key comparison_operator integer_value ) |
	not ( int_key comparison_operator integer_value ) |
	int_key not BETWEEN integer_value AND integer_value + integer_value |
	int_key not BETWEEN integer_value AND integer_value + integer_value |
	int_key not IN ( integer_list ) |
	int_key IS not NULL ;

string_item:
	not ( string_key comparison_operator string_value ) |
	string_key not BETWEEN string_value AND string_value |
	string_key not LIKE CONCAT (string_value , '%' ) |
	string_key not IN ( string_list ) |
	string_key IS not NULL ;

aggregate:
	MIN( | MAX( | COUNT( ;

and_or:
	AND | AND | AND | AND | OR ;
or_and:
	OR | OR | OR | OR | AND ;

integer_value:
	_digit | _digit |
	_tinyint | _tinyint_unsigned |
	255 | 1 ;

string_value:
	_varchar(1) | _varchar(2) | _english | _states | _varchar(10) ;

integer_list:
	integer_value , integer_value |
	integer_value , integer_list ;

string_list:
	string_value , string_value |
	string_value , string_list ;

comparison_operator:
	= | = | = | = | = | = |
	!= | > | >= | < | <= | <> ;

not:
	| | | | | | NOT ;

any_key:
	int_key | string_key ;

int_key:
	`emitente_id` | `emitente_propriedade` | `nf` | `id_item` | `unidade_id` | `lote_spa` | `item_id` | `item_id_red` ;

my_field:
  `emitente_tipo` |
  `emitente_id` |
  `emitente_propriedade` |
  `nf_serie` |
  `nf` |
  `id_item` |
  `status` |
  `unidade_id` |
  `lote_tipo` |
  `lote_spa` |
  `oe_tipo` |
  `oe` |
  `oe_seq` |
  `item_id` |
  `item_id_red` |
  `item_codigo` |
  `item_desc` |
  `servico` |
  `documento_auxiliar` |
  `cfop_id` |
  `cfop_id_red` |
  `cfop_numero` |
  `class_fiscal` |
  `sit_trib` |
  `sit_trib_ipi` |
  `sit_trib_pis` |
  `sit_trib_cofins` |
  `sit_trib_iss` |
  `sit_trib_sn` |
  `icms_incluir_bc` |
  `icms_subst_incluir_bc` |
  `ipi_incluir_bc` |
  `pis_inclur_bc` |
  `cofins_incluir_bc` |
  `ii_incluir_bc` |
  `sn_incluir_bc` |
  `un_fat` |
  `quant` |
  `pecas` |
  `pbruto` |
  `pliq` |
  `vliq` |
  `vbruto` |
  `valor_pauta` |
  `valor_pauta_grandeza` |
  `valor_pauta_grandeza_quant` |
  `valor_produto_un` |
  `valor_produto_grandeza` |
  `valor_produto_grandeza_quant` |
  `valor_produto_tabela_un` |
  `valor_produto_total` |
  `valor_frete` |
  `valor_seguro` |
  `valor_outras` |
  `valor_estimado_impostos` |
  `valor_estimado_impostos_por` |
  `desconto` |
  `icms_de_aliq` |
  `icms_de_red` |
  `icms_fe_aliq` |
  `icms_fe_red` |
  `icms_basecalculo` |
  `icms_valor` |
  `icms_subst_ind_convenio` |
  `icms_subst_basecalculo` |
  `icms_subst_valor` |
  `ipi_aliq` |
  `ipi_red` |
  `ipi_basecalculo` |
  `ipi_valor` |
  `iss_aliq` |
  `iss_red` |
  `iss_basecalculo` |
  `iss_valor` |
  `pis_aliq` |
  `pis_red` |
  `pis_basecalculo` |
  `pis_valor` |
  `cofins_aliq` |
  `cofins_red` |
  `cofins_basecalculo` |
  `cofins_valor` |
  `funrural_aliq` |
  `funrural_red` |
  `funrural_basecalculo` |
  `funrural_valor` |
  `sn_aliq` |
  `sn_red` |
  `sn_basecalculo` |
  `sn_valor` |
  `cide_aliq` |
  `cide_red` |
  `cide_basecalculo` |
  `cide_valor` |
  `csll_aliq` |
  `csll_red` |
  `csll_basecalculo` |
  `csll_valor` |
  `sit_trib_csll` |
  `inss_aliq` |
  `inss_red` |
  `inss_basecalculo` |
  `inss_valor` |
  `sit_trib_inss` |
  `ir_aliq` |
  `ir_red` |
  `ir_basecalculo` |
  `ir_valor` |
  `sit_trib_ir` |
  `ii_aliq` |
  `ii_red` |
  `ii_basecalculo` |
  `ii_valor` |
  `sit_trib_ii` |
  `numero_pedido_compra` |
  `numero_item_pedido` |
  `obs_item` |
  `quant_devolvida` |
  `pecas_devolvida` |
  `pbruto_devolvida` |
  `pliq_devolvida` |
  `vliq_devolvida` |
  `vbruto_devolvida` |
  `ii_anterior_un` |
  `ipi_anterior_un` |
  `pis_anterior_un` |
  `cofins_anterior_un` 
;	

string_key:
	`emitente_tipo` | `nf_serie` | `lote_tipo` ;

index_list:
	index_item , index_item |
	index_item , index_list;


index_item:
	my_field | my_field |
	int_key | string_key ( index_length ) ;

index_length:
	1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 ;

index_hint:
	| | | FORCE KEY (PRIMARY, `spamov`, `item_id`);

query:

return_charset_to_default; modify_column_recreate_index ;

return_charset_to_default:

ALTER TABLE _table[invariant] MODIFY `col_varchar_1000_key` VARCHAR(1000) CHARSET latin1; recreate_index ;

modify_column_recreate_index:

ALTER TABLE _table[invariant] MODIFY `col_varchar_1000_key` VARCHAR(1000) CHARSET charset; recreate_index ;  

recreate_index:

ALTER TABLE _table[invariant] DROP INDEX `col_varchar_1000_key` ; ALTER TABLE _table[invariant] ADD INDEX(`col_varchar_1000_key`) ;

# Character sets from 5.3.3 release

charset:

`big5` | `dec8` | `cp850` | `hp8` | `koi8r` | `latin1` | `latin2` | `swe7` | `ascii` | ujis | sjis | hebrew | tis620 | euckr | koi8u | gb2312 | greek | cp1250 | gbk | latin5 | armscii8 | utf8 | ucs2 | cp866 | keybcs2 | macce | macroman | cp852 | latin7 | cp1251 | cp1256 | cp1257 | `binary` | geostd8 | cp932 | eucjpms ; 
 
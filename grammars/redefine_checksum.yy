#
# Redefining grammar for MDEV-9758 (CHECKSUM TABLE - optimize calling my_checksum with larger chunks)
#

thread2_add:
    CHECKSUM TABLE table_list checksum_quick_extended;

thread4_add:
    CHECKSUM TABLE table_list checksum_quick_extended;

table_list:
    _basetable | _basetable, table_list;

checksum_quick_extended:
    | | QUICK | EXTENDED;
    

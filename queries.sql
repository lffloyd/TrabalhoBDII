conn chinook/p4ssw0rd;

/*O select abaixo é o resultado requerido na questão 1.*/
select INDEX_NAME, TABLE_NAME, COLUMN_NAME from ALL_IND_COLUMNS where INDEX_OWNER = user;

create or replace view tab_and_cols as
select table_name as tab_name, column_name as col_name
from all_tab_columns
where owner = USER;

select * from tab_and_cols;

create or replace view foreign_keys as
select constraint_name as cons_name, constraint_type as cons_type
from user_constraints
where constraint_type = 'R';

select * from foreign_keys;

create or replace view all_cons as
select constraint_name as cons_name, table_name as tab_name, column_name as col_name, constraint_type as cons_type
from (all_cons_columns natural join user_constraints);

select * from all_cons;

create or replace view primary_keys as
select cons_name, tab_name as ref_tab, col_name as ref_col from all_cons where cons_type = 'P';

select * from primary_keys;

create or replace view all_scheme_cons as
select tab_and_cols.tab_name, tab_and_cols.col_name, all_cons_columns.constraint_name as cons_name, 
user_constraints.r_constraint_name as references_pk
from ((tab_and_cols join all_cons_columns on tab_and_cols.tab_name = all_cons_columns.table_name) join user_constraints on 
all_cons_columns.constraint_name = user_constraints.constraint_name)
where tab_and_cols.col_name = all_cons_columns.column_name;

select * from all_scheme_cons;

create or replace view all_scheme_fk_cons as
select *
from all_scheme_cons natural join foreign_keys;

select * from all_scheme_fk_cons;

create or replace view all_fk_and_related_tabs_cols as
select all_scheme_fk_cons.cons_name, all_scheme_fk_cons.tab_name, all_scheme_fk_cons.col_name, all_scheme_fk_cons.references_pk, 
primary_keys.ref_tab, primary_keys.ref_col, all_scheme_fk_cons.cons_type
from all_scheme_fk_cons join primary_keys on all_scheme_fk_cons.references_pk = primary_keys.cons_name
order by tab_name;

/*O select abaixo é o resultado requerido an questão 3.*/
select * from all_fk_and_related_tabs_cols;


select * from user_constraints;
select * from user_tables;
select * from all_tab_columns where owner = USER;
select * from all_cons_columns where owner = USER;


/*create or replace procedure getForeignKeys(tabela in varchar2) is
    declare
    begin
        select * from ALL_TAB_COLUMNS
        where OWNER = USER;
    end getForeignKeys;
    
getForeignKeys('Artist');
*/

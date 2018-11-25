conn chinook/p4ssw0rd;

/*-----------------------------------------------
-------------------------------------------------
PARTE 1: ITEM 1
-------------------------------------------------
-----------------------------------------------*/

/*O select abaixo é o resultado requerido na questão 1. Mostra todos os índices 
sobre tabelas do usuário existentes no bd, além de indicar sob quais tabelas e
colunas das mesmas estes índices estão atuando.*/
select INDEX_NAME, TABLE_NAME, COLUMN_NAME from ALL_IND_COLUMNS where INDEX_OWNER = user;

/*-----------------------------------------------
-------------------------------------------------
PARTE 1: ITEM 2
-------------------------------------------------
-----------------------------------------------*/
create or replace procedure remove_index(tabela_nome ALL_IND_COLUMNS.TABLE_NAME%TYPE)
is
cursor c1 is select distinct INDEX_NAME from ALL_IND_COLUMNS where INDEX_OWNER = user and TABLE_NAME = tabela_nome;
total int;
BEGIN
    FOR c1_rec IN c1 LOOP
        select count(CONSTRAINT_NAME) INTO total from ALL_CONSTRAINTS where OWNER = 'CHINOOK' AND CONSTRAINT_NAME = c1_rec.INDEX_NAME;
        IF(total > 0) THEN
        EXECUTE IMMEDIATE 'ALTER TABLE ' || tabela_nome || ' DROP CONSTRAINT ' || c1_rec.INDEX_NAME;
        ELSE
        EXECUTE IMMEDIATE 'ALTER TABLE ' || tabela_nome || ' DROP INDEX ' || c1_rec.INDEX_NAME;
        END IF;
    END LOOP;
END;

/*Procedure que recebe como parâmetro o nome de uma tabela a ter todos os seus índices removidos. No Oracle, toda chave primária 
é criada junto com um indice que recebe o mesmo nome que ela e uma constraint. Se o indice a ser removido for desse tipo, precisamos
dar DROP na constraint dele, se o indice for relacionado a outra coluna que não seja chave primária, damos DROP no indice direto.
*/

/*-----------------------------------------------
-------------------------------------------------
PARTE 1: ITEM 3
-------------------------------------------------
-----------------------------------------------*/

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

/*O select abaixo é o resultado requerido an questão 3. Exibirá todas as foreign keys existentes no banco de dados,
as tabelas e colunas  em que essas foreign keys existem, assim como as tabelas e colunas originais que essas chaves
referenciam.*/
select * from all_fk_and_related_tabs_cols;

select * from user_constraints;
select * from user_tables;
select * from all_tab_columns where owner = USER;
select * from all_cons_columns where owner = USER;

/*-----------------------------------------------
-------------------------------------------------
PARTE 1: ITEM 4
-------------------------------------------------
-----------------------------------------------*/

/*----------------------------
Funções e procedures para criação dos comandos 'create table' das tabelas do banco Chinook
.---------------------------*/

/*Cria as tabelas do bd Chinook, constando apenas de colunas, tipos, possibilidade de nulidade, chaves primárias, dentre
outras informações básicas.*/
create or replace function criar_tabelas return varchar2 is
    cursor c1 is select table_name from user_tables;
    codigo varchar2(32767) := '';
    htab varchar2(10) := '    ';
    nome_cons varchar2(30) := '';
begin
    for c1_rec in c1 loop
        codigo := (codigo || chr(10) || 'CREATE TABLE ' || c1_rec.table_name || ' (' || chr(10));
        for c2_rec in (select * from all_tab_columns where table_name = c1_rec.table_name order by column_id) loop
            codigo := (codigo || htab || c2_rec.column_name || ' ' || c2_rec.data_type);
            if c2_rec.data_type = 'NUMBER' then
                if (not (c2_rec.data_precision is null)) and (not (c2_rec.data_scale is null)) then
                    codigo := (codigo || '(' || c2_rec.data_precision || ', ' || c2_rec.data_scale || ')');
                end if;
            elsif c2_rec.data_type = 'VARCHAR2' then
                codigo := (codigo || '(' || c2_rec.data_length || ')');
            end if;
            if c2_rec.nullable = 'N' then
                codigo := (codigo || ' NOT NULL');
            end if;
            codigo := (codigo || ',' || chr(10));
        end loop;
        select distinct cons_name into nome_cons from primary_keys where ref_tab = c1_rec.table_name;
        codigo := (codigo || htab || 'CONSTRAINT ' || nome_cons || ' PRIMARY KEY (');
        for c3_rec in (select ref_col from primary_keys where ref_tab = c1_rec.table_name) loop
            codigo := (codigo || c3_rec.ref_col || ', ');
        end loop;
        codigo := substr(codigo, 1, length(codigo) - 2);
        codigo := (codigo || ')');
        codigo := (codigo || chr(10) || ');' || chr(10) || chr(10));
    end loop;
    return codigo;
end criar_tabelas;

/*Cria os comandos de inclusão de foreign keys nas tabelas previamente criadas do bd.*/
create or replace function criar_foreign_keys(cod_ant varchar2) return varchar2 is
    cod_atual varchar(32767) := '';
    htab varchar(10) := '    ';
    cursor c1 is select * from all_fk_and_related_tabs_cols;
begin
    cod_atual := (cod_atual || cod_ant);
    for c1_rec in c1 loop
        cod_atual := (cod_atual || 'ALTER TABLE ' || c1_rec.tab_name || ' ADD CONSTRAINT ' || c1_rec.cons_name || chr(10));
        cod_atual := (cod_atual || htab || 'FOREIGN KEY (' || c1_rec.col_name || ') REFERENCES ' || c1_rec.ref_tab || '(');
        cod_atual := (cod_atual || c1_rec.ref_col || ');' || chr(10) || chr(10));
    end loop;
    return cod_atual;
end criar_foreign_keys;

/*Cria o conjunto de comandos de criação do bd Chinook.*/
create or replace procedure criar_bd is
    codigo varchar(32767) := '';
begin
    codigo := criar_tabelas();
    codigo := criar_foreign_keys(codigo);
    dbms_output.put_line(codigo); 
end criar_bd;

/*Executa a procedure que criará o conjunto de comandos SQL para criação das tabelas do banco de dados Chinook database.
Deve-se abrir um console dbms no SQL Developer para que o 'print' da string gerada possa ser visualizado.*/
execute criar_bd();

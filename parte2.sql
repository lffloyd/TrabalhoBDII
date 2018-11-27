/*-----------------------------------------------
-------------------------------------------------
PARTE 2
-------------------------------------------------
-----------------------------------------------*/


/*-----------------------------------------------
-------------------------------------------------
ITENS 1 E 2
-------------------------------------------------
-----------------------------------------------*/
/*
A regra semântica implementada por trigger (abaixo) descreve que uma instância de ALBUM não pode possuir mais do que
17 instâncias de faixas TRACK associadas ao mesmo por 'foreign keys'.
Essa regra foi baseada na quantidade comum de faixas encontradas em álbuns de música popular típicos, que incluem até 18 
faixas no caso de versões em CD.
Quando ocorre inserção ou remoção na tabela TRACK, checa-se a quantidade de faixas associadas ao ALBUM referido pela faixa 
removida/inserida, e caso este valor seja igual ou maior que 18 emite-se um erro para o usuário, abortando esta modificação.
*/
create or replace trigger verifica_total_faixas
    before insert or delete on Track
    referencing OLD as old New as new
    for each row
declare
    tam number := 0;
begin
    select count(*) into tam from Track where albumid = :new.albumid;
    if (tam >= 18) then
    	raise_application_error(-20202, 'An ALBUM instance must have 18 associated TRACK instances only.');
    end if;       
end;

/*Testes para trigger acima.*/
select * from TRACK where albumid = 1;

INSERT INTO Track (TrackId, Name, AlbumId, MediaTypeId, GenreId, Composer, Milliseconds, Bytes, UnitPrice) VALUES
(3504, 'asfadfs', 1, 1, 1, 'Angus Young, Malcolm Young, Brian Johnson', 343719, 11170334, 0.99);
INSERT INTO Track (TrackId, Name, AlbumId, MediaTypeId, GenreId, Composer, Milliseconds, Bytes, UnitPrice) VALUES
(3505, 'asfadfs', 1, 1, 1, 'Angus Young, Malcolm Young, Brian Johnson', 343719, 11170334, 0.99);
INSERT INTO Track (TrackId, Name, AlbumId, MediaTypeId, GenreId, Composer, Milliseconds, Bytes, UnitPrice) VALUES
(3506, 'asfadfs', 1, 1, 1, 'Angus Young, Malcolm Young, Brian Johnson', 343719, 11170334, 0.99);
INSERT INTO Track (TrackId, Name, AlbumId, MediaTypeId, GenreId, Composer, Milliseconds, Bytes, UnitPrice) VALUES
(3507, 'qerwr', 1, 1, 1, 'Angus Young, Malcolm Young, Brian Johnson', 343719, 11170334, 0.99);
INSERT INTO Track (TrackId, Name, AlbumId, MediaTypeId, GenreId, Composer, Milliseconds, Bytes, UnitPrice) VALUES
(3508, 'dghfh', 1, 1, 1, 'Angus Young, Malcolm Young, Brian Johnson', 343719, 11170334, 0.99);
INSERT INTO Track (TrackId, Name, AlbumId, MediaTypeId, GenreId, Composer, Milliseconds, Bytes, UnitPrice) VALUES
(3509, 'etyr', 1, 1, 1, 'Angus Young, Malcolm Young, Brian Johnson', 343719, 11170334, 0.99);
INSERT INTO Track (TrackId, Name, AlbumId, MediaTypeId, GenreId, Composer, Milliseconds, Bytes, UnitPrice) VALUES
(3510, 'uioui', 1, 1, 1, 'Angus Young, Malcolm Young, Brian Johnson', 343719, 11170334, 0.99);
INSERT INTO Track (TrackId, Name, AlbumId, MediaTypeId, GenreId, Composer, Milliseconds, Bytes, UnitPrice) VALUES
(3511, 'cxcvxc', 1, 1, 1, 'Angus Young, Malcolm Young, Brian Johnson', 343719, 11170334, 0.99);

INSERT INTO Track (TrackId, Name, AlbumId, MediaTypeId, GenreId, Composer, Milliseconds, Bytes, UnitPrice) VALUES
(3513, 'zsszsz', 1, 1, 1, 'Angus Young, Malcolm Young, Brian Johnson', 343719, 11170334, 0.99);

delete from Track where trackid > 3503;

/*A regra semântica abaixo é semelhante a anterior. Ela é uma stored procedure que um dado usuário criado chamado newUser 
deve utilizar para poder adicionar TRACKS as suas PLAYLISTS. Ele não possui acesso à nenhuma informação das tabelas, apenas pode
adicionar TRACKS novas utilizando a stored procedure que recebe como parâmetros o ID da PLAYLIST e o ID da TRACK. Caso o nº de TRACKS
numa playlist tenha atingido o limite de 50, a stored procedure levanta um erro 
avisando ao usuário sobre o limite de 50 TRCKS por PLAYLIST. Para fazer esta parte é necssário fazer login com o user SYSTEM, 
criar o novo usuário, compilar a stored procedure e dar acesso ao usuário à essa stored procedure. Após fazer isso deve-se 
desconectar do BD atual e reconectar com o novo user criado (newUser) e ele poderá adicionar TRACKS novas executando a procedure,
informando o ID da TRACK e da PLAYLIST ao qual ele pretende associar.*/

CREATE USER newUser
IDENTIFIED BY 1234;

GRANT CONNECT TO newUser;
GRANT EXECUTE ON SYSTEM.insert_track_on_playlist TO newUser;

create or replace procedure insert_track_on_playlist(playlist_id int, track_id int)
is
total int;
BEGIN
select count(*) into total from PLAYLIST where PLAYLISTID = playlist_id;
IF (total>=50) THEN
    raise_application_error(-23, 'Playlists can contain a maximum of 50 tracks.');
ELSE
insert into PLAYLISTTRACK(PLAYLISTID,TRACKID) values (playlist_id, track_id);
END IF;
END;

/*Teste da procedure*/
BEGIN
SYSTEM.insert_track_on_playlist(1,1);
END;

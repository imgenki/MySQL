/* Creación de Base de datos */

CREATE DATABASE FutbolDB;
USE FutbolDB;

/* Creación de Tablas */

CREATE TABLE Ligas (codLiga char(5) primary key, nomLiga varchar(50));

CREATE TABLE Equipos (codEquipo integer AUTO_INCREMENT PRIMARY KEY, nomEquipo varchar(40), codLiga char(5) DEFAULT 'PDN',
localidad varchar(60), internacional tinyint(1) default 0,
FOREIGN KEY (codLiga) REFERENCES Ligas(codLiga));

create table Futbolistas (codDNIoNIE char(9) PRIMARY KEY, nombre varchar(50), nacionalidad varchar(40));

create table Contratos (codContrato integer AUTO_INCREMENT PRIMARY KEY, codDNIoNIE char(9), codEquipo integer, 
fechaInicio date, fechaFin date, precioAnual integer, precioRecision integer,
FOREIGN KEY (codEquipo) REFERENCES Equipos(codEquipo),
FOREIGN KEY (codDNIoNIE) REFERENCES Futbolistas(codDNIoNIE)
);

-- Inserciones 
insert into ligas values (11111, 'Liga1');
insert into ligas values (22222, 'Liga2');
insert into ligas values (33333, 'Liga3');
insert into ligas values (44444, 'Liga4');
insert into ligas values (55555, 'Liga5');
insert into ligas values ('PDN', 'Liga6');

insert into equipos values (null,'Equipo1', default, 'Santa Cruz', 1);
insert into equipos values (null,'Equipo2', 11111, 'Los Sauces', 0);
insert into equipos values (null,'Equipo3', 44444, 'La Orotava', 1);
insert into equipos values (null,'Equipo4', 44444, 'La Victoria', 1);
insert into equipos values (null,'Equipo5', 33333, 'Los Abrigos', 0);
insert into equipos values (null,'Equipo6', 55555, 'Las Galletas', 0);

insert into futbolistas values ('11111111F', 'Futbolista1', 'Española');
insert into futbolistas values ('22222222R', 'Futbolista2', 'Alemana');
insert into futbolistas values ('33333333G', 'Futbolista3', 'Inglesa');
insert into futbolistas values ('44444444S', 'Futbolista4', 'Española');
insert into futbolistas values ('55555555A', 'Futbolista5', 'Inglesa');

insert into contratos values (null,'44444444S', 3, '2018-11-08', '2019-04-06', 12369, 123535);
insert into contratos values (null,'55555555A', 6, '2012-02-11', '2020-06-04', 15987, 125653);
insert into contratos values (null,'22222222R', 5, '2010-12-01', '2015-06-04', 17896, 125635);
insert into contratos values (null,'11111111F', 4, '2013-02-10', '2015-12-06', 12896, 14863);
insert into contratos values (null,'33333333G', 1, '2011-09-10', '2013-12-08', 1789, 14341);
insert into contratos values (null,'33333333G', 2, '2019-09-10', '2025-12-08', 1789, 14123);

-- Procedimientos
-- P1
DELIMITER $$

CREATE PROCEDURE ejerc_1 (IN codDNIoNIE char(9))
BEGIN 
    SELECT contratos.codContrato, Equipos.nomEquipo, Ligas.nomLiga, contratos.fechaInicio, contratos.fechaFin, contratos.precioAnual, contratos.preciorecision
    from ligas, contratos, equipos
    WHERE contratos.codEquipo=equipos.codEquipo AND 
    equipos.codLiga=ligas.codLiga
    ORDER BY contratos.fechaInicio;
END

$$
DELIMITER ;
 -- P2
DELIMITER $$

create procedure ejerc_2 (IN nomEquipo varchar(40), IN codLiga char(5),
							 IN localidad varchar(60), IN internacional bit, OUT LigaExiste int , IN InsercionCorrecta int)
BEGIN
SET LigaExiste = 0;
SET InsercionCorrecta = 0;

SET LigaExiste = (SELECT COUNT(*) FROM Ligas WHERE ligas.codLiga=codLiga);

CASE LigaExiste
    WHEN 1 THEN
        BEGIN
        SET @NumeroEquiposAntes = (SELECT COUNT(*) FROM equipos);

        INSERT INTO equipos VALUES (null, nomEquipo, codLiga, localidad, internacional);

        SET @NumeroEquiposDespues = (SELECT COUNT(*) FROM equipos);

        IF @NumeroEquiposDespues>@NumeroEquiposAntes THEN
        SET InsercionCorrecta = 1;
        ELSE
        SET InsercionCorrecta = 1;
        END IF;

        END;
ELSE
        BEGIN 
    END;
    END CASE;
END

$$
DELIMITER ;

--P3
DELIMITER $$

CREATE PROCEDURE ejerc_3 (IN p_codEquipo int, IN p_precioAnual int, IN p_precioRecision int, OUT p_FutbolistasActivosEquipo int, OUT p_FutbolistasActivosEspecifico int)

BEGIN
    SET p_FutbolistasActivosEquipo = (SELECT count(coddnionie) FROM contratos WHERE p_codEquipo = contratos.codEquipo
                    AND fechaFin > NOW() AND fechaInicio < NOW());
    SET p_FutbolistasActivosEspecifico = (SELECT count(coddnionie) FROM contratos WHERE p_codEquipo = contratos.codEquipo
                    AND p_precioAnual > contratos.precioAnual AND p_precioResicion > contratos.precioResicion
                    AND fechaFin > NOW() AND fechaInicio < NOW());
END

$$
DELIMITER ;

-- Funciones
DELIMITER $$

CREATE FUNCTION NumeroDeMeses(DNI varChar(9)) RETURNS Integer
 DETERMINISTIC
 CONTAINS SQL
BEGIN
DECLARE Numero Integer DEFAULT 0;
    SET Numero = (SELECT sum(TIMESTAMPDIFF(MONTH,contratos.fechaInicio,contratos.fechaFin)) AS meses_transcurridos 
    FROM futbolistas INNER JOIN contratos ON futbolistas.codDNIoNIE=contratos.codDNIoNIE WHERE futbolistas.codDNIoNIE=DNI);
RETURN Numero;
END

$$
DELIMITER ;


-- Tigers

--T1
DELIMITER

$$

CREATE TRIGGER PrecioRecision_Update BEFORE UPDATE
ON contratos FOR EACH ROW
Begin

IF NEW.precioRecision<NEW.precioAnual THEN
	signal sqlstate '45000' set message_text='El precio no puede ser inferior al Precio Anual';
END IF;

END

$$

DELIMITER  ;

DELIMITER  $$
CREATE TRIGGER PrecioRecision_Insert BEFORE INSERT
ON contratos FOR EACH ROW
BEGIN 

IF NEW.precioRecision<NEW.precioAnual THEN
	signal sqlstate '45000' set message_text='El precio no puede ser inferior al Precio Anual';
END IF;

END 

$$

DELIMITER  ;

--T2

DELIMITER $$

CREATE TRIGGER fechaCheck  BEFORE UPDATE 
ON contratos FOR EACH ROW
BEGIN 
DECLARE Fecha1 DATE;
DECLARE Fecha2 DATE;
IF NEW.fechaInicio>New.fechaFin THEN
    SET Fecha1 = NEW.fechaInicio;
	SET Fecha2 = NEW.fechaFin;
	SET NEW.fechaInicio = Fecha2;
	SET NEW.fechaFin = Fecha1;
END IF;

END

$$

DELIMITER  ;

DELIMITER $$

CREATE TRIGGER Fechas_Insert BEFORE INSERT
ON contratos FOR EACH ROW
Begin
DECLARE Fecha1 DATE;
DECLARE Fecha2 DATE;
IF NEW.fechaInicio>NEW.fechaFin THEN
	SET Fecha1 = NEW.fechaInicio;
	SET Fecha2 = NEW.fechaFin;
	SET NEW.fechaInicio = Fecha2;
	SET NEW.fechaFin = Fecha1;
END IF;

END 

$$

DELIMITER  ;


--T3

DELIMITER $$

CREATE TRIGGER noBorrarLiga BEFORE DELETE 
ON ligas FOR EACH ROW

BEGIN 

    signal sqlstate '45000' set message_text='No se pueden borrar Ligas';

END

$$

DELIMITER ;



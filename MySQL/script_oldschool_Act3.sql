CREATE DATABASE oldschool_transacciones;
USE oldschool_transacciones;

SHOW DATABASES;

-- Punto 5.9.2
CREATE TABLE deudores (
cc INT PRIMARY KEY NOT NULL,
clave VARCHAR (15) NOT NULL,
nombre VARCHAR (30) NOT NULL,
apellido VARCHAR (30) NOT NULL,
email VARCHAR (50) NOT NULL
)ENGINE = innodb;

DESCRIBE deudores;

-- Punto 5.9.3
CREATE TABLE creditos(
id INT AUTO_INCREMENT PRIMARY KEY NOT NULL,
fecha DATE NOT NULL,
valor FLOAT NOT NULL,
cuotas INT NOT NULL,
interes FLOAT NOT NULL,
estado VARCHAR (20) NOT NULL DEFAULT 'Activo',
deudor_id INT NOT NULL,
CONSTRAINT chk_interes
CHECK (interes>=0 AND interes<=1),
FOREIGN KEY (deudor_id) REFERENCES deudores (cc)
ON DELETE CASCADE ON UPDATE CASCADE
)ENGINE = innodb;

DESCRIBE creditos;

ALTER TABLE creditos
ADD CONSTRAINT chk_valor
CHECK (valor>0);

ALTER TABLE creditos
ADD CONSTRAINT chk_cuota
CHECK (cuotas>0);

-- Punto 5.9.4
CREATE TABLE pagos(
id INT PRIMARY KEY AUTO_INCREMENT NOT NULL,
fecha DATE NOT NULL,
valor FLOAT NOT NULL ,
credito_id INT NOT NULL,
CONSTRAINT chk_valor_positivo CHECK(valor>0),
FOREIGN KEY (credito_id) REFERENCES creditos (id)
ON DELETE CASCADE ON UPDATE CASCADE
)ENGINE = innodb;

DESCRIBE pagos;

DELIMITER $$
CREATE TRIGGER verificar_fecha BEFORE INSERT ON pagos
FOR EACH ROW
BEGIN
  IF NEW.fecha > CURDATE() THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La fecha debe ser menor o igual a la fecha actual.';
  END IF;
END$$
DELIMITER ;
-- punto 5.9.5
INSERT INTO deudores
VALUES(123, 'Abc', 'Fulanito', 'Detal', 'fulanito1@gmail.com');

INSERT INTO deudores
VALUES(456, 'B15', 'Mengano', 'Guerrero', 'mengano@hotmail.com'),
(789, 'w86', 'Prencejo', 'Tapias', 'prencejo@yahoo.com'),
(951, 'y84', 'Riquilda', 'López', 'riquilda@gmail.com');
-- punto 5.9.6
SELECT * FROM deudores;

SELECT * FROM creditos;

-- punto 5.9.7
INSERT INTO creditos (fecha, valor, cuotas, interes, deudor_id) 
VALUES(DATE_ADD(CURDATE(),INTERVAL -1 YEAR),100000,5,0.4,'123'),
(DATE_ADD(CURDATE(),INTERVAL -1 YEAR),200000,10,0.2,'456'),
(DATE_ADD(CURDATE(),INTERVAL -1 YEAR),300000,12,0.2,'789'),
(DATE_ADD(CURDATE(),INTERVAL -1 YEAR),700000,6,0.2,'951');
-- punto 5.9.8
SELECT * FROM creditos;

select * from pagos;
DROP PROCEDURE IF EXISTS InsertarPago;
-- Punto 5.9.9
DELIMITER //
CREATE PROCEDURE InsertarPago
(pago_id INT,
pago_fecha DATE,
pago_valor FLOAT,
credito_id INT)
BEGIN
	-- Se decalra el error
    DECLARE error_obtenido BOOLEAN DEFAULT FALSE;
    -- Insertar el pago
    INSERT INTO pagos (id, fecha, valor, credito_id)
    VALUES (pago_id, pago_fecha, pago_valor, credito_id);
    
    IF ROW_COUNT() = 1 THEN
		SELECT CONCAT("El pago con Id ", pago_id,
        " del credito con Id ", credito_id,
        " ha sistematizado Exitosamente!") AS Mensaje;
	END IF;
END //
DELIMITER ;

-- Punto 5.9.9.1
CALL InsertarPago(1, DATE_ADD((SELECT fecha FROM creditos WHERE id = 1), INTERVAL 1 MONTH), 28000, 1);

-- Punto 5.9.9.2
CALL InsertarPago(2, DATE_ADD(CURDATE(), INTERVAL 1 MONTH), 28000, 1);

-- Punto 5.9.9.3
CALL InsertarPago(3, DATE_ADD((SELECT p.fecha FROM pagos p WHERE p.id = 1), INTERVAL 1 MONTH), 28000, 1);

-- Punto 5.9.9.4
CALL InsertarPago(4, DATE_ADD((SELECT p.fecha FROM pagos p WHERE p.id = 1), INTERVAL 1 MONTH), 28000, 1);

-- Punto 5.9.9.5
CALL InsertarPago(5, DATE_ADD((SELECT p.fecha FROM pagos p WHERE p.id = 1), INTERVAL 1 MONTH), -28000, 1);

DROP PROCEDURE IF EXISTS EstadoCredito;
-- Punto 5.9.10
DELIMITER //

CREATE PROCEDURE EstadoCredito(IN credito_id INT)   
BEGIN
    DECLARE valor_credito FLOAT;
    DECLARE tasa_interes FLOAT;
    DECLARE valor_deuda FLOAT;
    DECLARE valor_saldo FLOAT;
    DECLARE valor_pagado FLOAT;
    DECLARE estado_actual VARCHAR(20);
    DECLARE estado_final VARCHAR(20);
        
    -- Obtenemos el valor del crédito y la tasa de interés
    SELECT valor, interes_mes, estado INTO valor_credito, tasa_interes, estado_actual
    FROM creditos
    WHERE id = credito_id;
    
    -- Calculamos el valor de la deuda
    SET valor_deuda = valor_credito *(1+ tasa_interes);
    
    -- Calculamos el valor total pagado
    SELECT SUM(valor) INTO valor_pagado
    FROM pagos
    WHERE credito_id = credito_id;
    
    -- calculamos el saldo
    SET valor_saldo = valor_deuda - valor_pagado;
    -- Determinar el estado del crédito
    IF valor_pagado >= valor_deuda THEN
        SET estado_final = 'Finalizado';
    ELSE
        SET estado_final = estado_actual;
    END IF;
    
    -- Actualizar el estado del crédito en la tabla Creditos
    UPDATE creditos
    SET estado = estado_final
    WHERE id = credito_id;    
    -- enviamos un mensaje con el estado final del credito
    SELECT CONCAT("El estado actual del crédito con Id ", credito_id, " es ", estado_final) AS Mensaje;
END //
DELIMITER ;

CALL EstadoCredito(1);

CALL InsertarPago(5, DATE_ADD((SELECT p.fecha FROM pagos p WHERE p.id = 1), INTERVAL 1 MONTH), 28000, 1);
CALL InsertarPago(2, DATE_ADD((SELECT p.fecha FROM pagos p WHERE p.id = 1), INTERVAL 1 MONTH), 28000, 1);
CALL EstadoCredito(1);

-- Punto 5.9.11
SELECT * FROM creditos
WHERE id=1;

-- Punto 5.9.12
SELECT * FROM pagos
WHERE credito_id= 1;

-- Punto 5.9.13
SELECT credito_id, SUM(valor) AS 'TOTAL PAGOS' 
FROM pagos
WHERE credito_id = 1;

 -- Punto 5.9.15
DELETE FROM pagos WHERE credito_id>=1;

-- Punto 5.9.16
SELECT * FROM pagos
WHERE credito_id= 1;

DROP PROCEDURE IF EXISTS insertar_pago_transaccion;
-- Punto 5.9.17
DELIMITER //
CREATE PROCEDURE insertar_pago_transaccion 
(
p_id INT,
p_fecha DATE,
p_valor FLOAT,
p_credito_id INT
)
BEGIN
DECLARE EXIT HANDLER FOR SQLEXCEPTION
BEGIN
   SHOW ERRORS LIMIT 1;
   RESIGNAL;
   ROLLBACK;
END;

START TRANSACTION;

	INSERT INTO pagos (id, fecha, valor, credito_id)
    VALUES(p_id, p_fecha, p_valor, p_credito_id);

COMMIT;
	SELECT CONCAT("La Transacción para el id = ",p_id,
    " fue realizada exitosamente!") AS Mensaje;
END//
DELIMITER ; 

CALL insertar_pago_transaccion (1, DATE_ADD((SELECT fecha FROM creditos WHERE id = 1), INTERVAL 1 MONTH), 28000, 1);
CALL insertar_pago_transaccion(2, DATE_ADD(CURDATE(), INTERVAL 1 MONTH), 28000, 1);
CALL insertar_pago_transaccion(3, DATE_ADD((SELECT p.fecha FROM pagos p WHERE p.id = 1), INTERVAL 1 MONTH), 28000, 1);
CALL insertar_pago_transaccion(4, DATE_ADD((SELECT p.fecha FROM pagos p WHERE p.id = 1), INTERVAL 1 MONTH), 28000, 1);
CALL insertar_pago_transaccion(5, DATE_ADD((SELECT p.fecha FROM pagos p WHERE p.id = 1), INTERVAL 1 MONTH), -28000, 1);

-- punto 5.9.19
CALL EstadoCredito(1);
CALL insertar_pago_transaccion(2, DATE_ADD((SELECT p.fecha FROM pagos p WHERE p.id = 1), INTERVAL 1 MONTH), 28000, 1);
CALL insertar_pago_transaccion(5, DATE_ADD((SELECT p.fecha FROM pagos p WHERE p.id = 1), INTERVAL 1 MONTH), 28000, 1);
CALL EstadoCredito(1);

-- Punto 5.9.20
SELECT * FROM creditos WHERE id=1;

-- Punto 5.9.21
SELECT * FROM pagos
WHERE credito_id= 1;

-- Punto 5.9.22
SELECT credito_id, SUM(valor) AS 'TOTAL PAGOS'
FROM pagos
WHERE credito_id = 1;

-- Punto 5.9.23
ROLLBACK;

-- Punto 5.9.24
SELECT * FROM pagos  
WHERE credito_id= 1;

-- Punto 5.9.25
SELECT credito_id, SUM(valor) AS 'TOTAL PAGOS'
FROM pagos
WHERE credito_id = 1;

SELECT * FROM deudores;
SELECT * FROM creditos;
-- Punto 5.10.1
SELECT d.nombre, (
    SELECT COUNT(*)
    FROM creditos c
    WHERE c.deudor_id = d.cc
        AND c.estado = 'Activo'
) AS total_creditos_activos
FROM deudores d;

-- Punto 5.10.2
SELECT d.nombre, c.valor_credito
FROM deudores d, (
    SELECT deudor_id, sum(valor) AS valor_credito
    FROM creditos
    GROUP BY deudor_id
) c
WHERE d.cc = c.deudor_id;

-- Punto 5.10.3
SELECT d.nombre
FROM deudores d
WHERE d.cc IN (
    SELECT c.deudor_id
    FROM creditos c
    WHERE c.estado = 'Activo'
);

-- Punto 5.10.4
SELECT d.nombre, COUNT(c.id) AS total_creditos_activos
FROM deudores d
JOIN creditos c ON d.cc = c.deudor_id
WHERE c.estado = 'Activo'
GROUP BY d.cc
HAVING COUNT(c.id) > (
    SELECT AVG(total_creditos)
    FROM (
        SELECT COUNT(id) AS total_creditos
        FROM creditos
        WHERE estado = 'Activo'
        GROUP BY deudor_id
    ) AS subconsulta);
    
-- Punto 5.10.5
ALTER TABLE deudores
ADD CONSTRAINT chk_cc
CHECK (CC > 0);

INSERT INTO deudores
VALUES(-654, 'Abc', 'Jonny', 'Luna', 'jonnylunag@gmail.c    om');

-- Punto 5.10.6
SELECT d.nombre, c.fecha, c.valor
FROM deudores d
INNER JOIN creditos c ON d.cc = c.deudor_id;

-- Punto 5.10.7
SELECT d.cc, d.nombre, d.apellido
FROM deudores d
FULL JOIN creditos  ON d.cc = creditos.deudor_id; 

SELECT d.nombre, c.fecha, c.valor
FROM deudores d
LEFT JOIN creditos c ON d.cc = c.deudor_id
UNION
SELECT d.nombre, c.fecha, c.valor
FROM deudores d
RIGHT JOIN creditos c ON d.cc = c.deudor_id
WHERE d.cc IS NULL;

-- Punto 5.10.8
SELECT d.nombre, d.apellido, c.cuota, c.valor
FROM deudores d
LEFT OUTER JOIN creditos c ON d.cc = c.deudor_id;

-- Punto 5.10.9
SELECT * FROM pagos;
SELECT d.nombre, c.cuota, c.valor, c.interes_mes
FROM deudores d
LEFT JOIN creditos c ON d.cc = c.deudor_id;

-- Punto 5.10.10
SELECT c.id, c.valor, p.fecha, p.valor
FROM creditos c
RIGHT JOIN pagos p ON c.id = p.credito_id;

-- Punto 5.10.11
SELECT id FROM creditos
UNION 
SELECT credito_id FROM pagos;

-- Punto 5.10.12
SELECT d.cc, d.nombre
FROM deudores d
INNER JOIN creditos c ON d.cc = c.deudor_id
WHERE d.cc IN (SELECT deudor_id FROM creditos);

-- Punto 5.10.13
CREATE VIEW VistaDeudoresCreditos AS
SELECT d.nombre, c.fecha, c.valor
FROM deudores d
INNER JOIN creditos c ON d.cc = c.deudor_id;

SELECT * FROM VistaDeudoresCreditos;

-- Punto 5.10.14
SELECT nombre, fecha, valor
FROM VistaDeudoresCreditos
WHERE valor > 100000;

-- Punto 5.10.15
ALTER VIEW VistaDeudoresCreditos AS
SELECT d.nombre, c.fecha, c.valor, c.cuota
FROM deudores d
INNER JOIN creditos c ON d.cc = c.deudor_id
WHERE c.estado = 'Activo';

-- Punto 5.10.16
SELECT * FROM VistaDeudoresCreditos;

-- Punto 5.10.17
SHOW FULL TABLES WHERE Table_type='VIEW';

-- Punto 5.10.18
DROP VIEW VistaDeudoresCreditos;

-- Punto 5.10.19
START TRANSACTION;

#Insertar ocho nuevos registros de pago en la tabla "Pagos" al credito con id = 4
INSERT INTO pagos (fecha, valor, credito_id)
VALUES (DATE_ADD((SELECT fecha FROM creditos WHERE id = 1), INTERVAL 1 MONTH), 45000, 4),
(DATE_ADD((SELECT fecha FROM creditos WHERE id = 1), INTERVAL 2 MONTH), 45000, 4),
(DATE_ADD((SELECT fecha FROM creditos WHERE id = 1), INTERVAL 3 MONTH), 45000, 4),
(DATE_ADD((SELECT fecha FROM creditos WHERE id = 1), INTERVAL 4 MONTH), 45000, 4),
(DATE_ADD((SELECT fecha FROM creditos WHERE id = 1), INTERVAL 5 MONTH), 45000, 4),
(DATE_ADD((SELECT fecha FROM creditos WHERE id = 1), INTERVAL 6 MONTH), 45000, 4),
(DATE_ADD((SELECT fecha FROM creditos WHERE id = 1), INTERVAL 7 MONTH), 45000, 4),
(DATE_ADD((SELECT fecha FROM creditos WHERE id = 1), INTERVAL 8 MONTH), 45000, 4);

# Actualizar el estado del crédito a "Finalizado" en la tabla "creditos"
UPDATE creditos
SET estado = 'Finalizado'
WHERE id = 4;

COMMIT;
DROP PROCEDURE IF EXISTS insertar_pago;
-- Punto 5.10.20
DELIMITER //
CREATE PROCEDURE insertar_pago 
(
p_fecha date,
p_valor float,
p_credito_id int
)
BEGIN
DECLARE EXIT HANDLER FOR SQLEXCEPTION
BEGIN
   SHOW ERRORS LIMIT 1;
   RESIGNAL;
   ROLLBACK;
END;

START TRANSACTION;

	INSERT INTO pagos (fecha, valor, credito_id)
    VALUES(p_fecha, p_valor, p_credito_id);
COMMIT;
	SELECT 'Transacción realizada exitosamente';
END//
DELIMITER ; 

CALL insertar_pago('2022-08-04',28000,2);

CALL insertar_pago('2022-08-04',-28000,2);

CALL insertar_pago('2025-08-04',28000,2);

/***** ACTIVIDAD 3 *********/
DROP FUNCTION verificar_deudor;
-- Punto 5.7
DELIMITER //
CREATE FUNCTION verificar_deudor(d_cc INT, d_clave VARCHAR(15))
RETURNS VARCHAR(10)
BEGIN
    DECLARE existe BOOLEAN;
    
    SET existe = EXISTS(
        SELECT 1 FROM deudores WHERE cc = d_cc AND clave = d_clave
    );
    RETURN IF(existe,'Verdadero','Falso');
END
//

-- Punto 5.8
SELECT verificar_deudor(123, 'Abc');

SELECT verificar_deudor(1234, 'xyz');

-- Punto 5.9
DELIMITER //
CREATE FUNCTION obtener_informacion_deudor(d_cc INT)
RETURNS TEXT
BEGIN
    DECLARE d_nombre VARCHAR(30);
    DECLARE ultimo_credito VARCHAR(500);
    DECLARE resultado VARCHAR(500);
    
    -- Obtener el nombre del deudor
    SELECT nombre INTO d_nombre
    FROM deudores
    WHERE cc = d_cc;
    
    -- Obtener el último crédito del deudor
    SELECT CONCAT('NOMBRE: ', d_nombre, ', ',
                  'FECHA: ', DATE_FORMAT(c.fecha, '%d-%m-%Y'), ', ',
                  'VALOR: $', c.valor, ', ',
                  'ESTADO: ', c.estado)
    INTO ultimo_credito
    FROM creditos c
    JOIN deudores d ON c.deudor_id = d.cc
    WHERE d.cc = d_cc
    ORDER BY c.fecha DESC
    LIMIT 1;
    
    -- Construir el resultado en el formato requerido
    SET resultado = ultimo_credito;
    
    RETURN resultado;
END//
DELIMITER ;

-- Punto 5.10
SELECT obtener_informacion_deudor(123);

SELECT obtener_informacion_deudor(456);

-- Punto 5.11
DELIMITER //
CREATE FUNCTION sumatoria_acumulativa(n_1 INT, n_2 INT)
RETURNS INT
BEGIN
    DECLARE v_suma INT DEFAULT 0;
    DECLARE v_min INT;
    DECLARE v_max INT;
    
    IF n_1 < n_2 THEN
        SET v_min = n_1;
        SET v_max = n_2;
    ELSE
        SET v_min = n_2;
        SET v_max = n_1;
    END IF;
    
    WHILE v_min <= v_max DO
        SET v_suma = v_suma + v_min;
        SET v_min = v_min + 1;
    END WHILE;
    
    RETURN v_suma;
END//
DELIMITER ;

SELECT sumatoria_acumulativa(15, 5);

SELECT sumatoria_acumulativa(1, 1000);

DROP PROCEDURE creditos_activos;
-- Punto 5.12
DELIMITER //
CREATE PROCEDURE creditos_activos(
IN d_cc INT,
INOUT cantidad INT
)
BEGIN
	DECLARE cant_creditos_activos INT;	
    
    SELECT COUNT(*) INTO cant_creditos_activos
    FROM creditos
    WHERE deudor_id = d_cc
    AND estado = 'Activo';
    
    SET cantidad = cant_creditos_activos;
    
    SELECT CONCAT("La cantidad de créditos activos que tiene el deudor con cc= ",
    d_cc, " es de ", cantidad) AS Mensaje; 
    -- RETURN creditos_activos_count;
END//
DELIMITER ;

-- Punto 5.13
SET @cant_creditos_activos := 0;
CALL creditos_activos(456, @cantidad_creditos_activos);
SELECT @cantidad_creditos_activos;

/********/
SELECT * FROM creditos;
SELECT * FROM pagos;
SELECT * FROM deudores; 





















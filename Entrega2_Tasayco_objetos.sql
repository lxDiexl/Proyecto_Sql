USE SistemaArchivos;

-- Limpieza segura de objetos si existen (orden para dependencias)
DROP VIEW IF EXISTS vw_auditoria_reciente;
DROP VIEW IF EXISTS vw_documentos_sin_categoria;
DROP VIEW IF EXISTS vw_documentos_por_categoria;
DROP VIEW IF EXISTS vw_historial_documentos;
DROP VIEW IF EXISTS vw_documentos_detalle;

DROP TRIGGER IF EXISTS trg_doc_cat_ai;
DROP TRIGGER IF EXISTS trg_historial_ai;
DROP TRIGGER IF EXISTS trg_documentos_au;
DROP TRIGGER IF EXISTS trg_documentos_ai;

DROP PROCEDURE IF EXISTS sp_buscar_documentos;
DROP PROCEDURE IF EXISTS sp_agregar_version;
DROP PROCEDURE IF EXISTS sp_asignar_categoria;
DROP PROCEDURE IF EXISTS sp_crear_documento;

DROP FUNCTION IF EXISTS fn_normalizar_titulo;
DROP FUNCTION IF EXISTS fn_tiene_categoria;
DROP FUNCTION IF EXISTS fn_ultima_version;


-- FUNCIONES

DELIMITER $$
CREATE FUNCTION fn_ultima_version(p_id_documento INT)
RETURNS INT
DETERMINISTIC
BEGIN
  DECLARE v INT;
  SELECT COALESCE(COUNT(*), 0) INTO v
  FROM Historial_Documentos
  WHERE id_documento = p_id_documento;
  RETURN v;
END$$

CREATE FUNCTION fn_tiene_categoria(p_id_documento INT, p_id_categoria INT)
RETURNS TINYINT
DETERMINISTIC
BEGIN
  RETURN EXISTS (
    SELECT 1
    FROM Documentos_Categorias
    WHERE id_documento = p_id_documento
      AND id_categoria  = p_id_categoria
  );
END$$

CREATE FUNCTION fn_normalizar_titulo(p_txt VARCHAR(255))
RETURNS VARCHAR(255)
DETERMINISTIC
BEGIN
  DECLARE t VARCHAR(255);
  SET t = UPPER(TRIM(p_txt));
  WHILE INSTR(t, '  ') > 0 DO
    SET t = REPLACE(t, '  ', ' ');
  END WHILE;
  RETURN t;
END$$
DELIMITER ;

-- STORED PROCEDURES

DELIMITER $$
CREATE PROCEDURE sp_crear_documento(
  IN  p_titulo VARCHAR(255),
  IN  p_tipo VARCHAR(50),
  IN  p_ruta VARCHAR(255),
  IN  p_id_usuario INT,
  OUT p_id_documento INT
)
BEGIN
  -- Inserta un documento nuevo según el esquema del diagrama (sin columna 'descripcion')
  INSERT INTO Documentos(titulo, tipo, ruta, id_usuario, version, fecha_subida, estado)
  VALUES (p_titulo, p_tipo, p_ruta, p_id_usuario, '1', NOW(), 'Activo');
  SET p_id_documento = LAST_INSERT_ID();
END$$

CREATE PROCEDURE sp_asignar_categoria(
  IN p_id_documento INT,
  IN p_id_categoria INT
)
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM Documentos_Categorias
    WHERE id_documento = p_id_documento AND id_categoria = p_id_categoria
  ) THEN
    INSERT INTO Documentos_Categorias(id_documento, id_categoria)
    VALUES (p_id_documento, p_id_categoria);
  END IF;
END$$

CREATE PROCEDURE sp_agregar_version(
  IN  p_id_documento INT,
  IN  p_ruta VARCHAR(255),
  IN  p_id_usuario INT,
  OUT p_version INT
)
BEGIN
  -- Nueva versión = cantidad de registros en historial + 1
  SET p_version = fn_ultima_version(p_id_documento) + 1;

  INSERT INTO Historial_Documentos (id_documento, ruta, fecha_modificacion, id_usuario)
  VALUES (p_id_documento, p_ruta, NOW(), p_id_usuario);

  -- Actualizar la fila actual en Documentos: ruta, version (varchar) y fecha_subida
  UPDATE Documentos
  SET ruta = p_ruta,
      version = CAST(p_version AS CHAR),
      fecha_subida = NOW()
  WHERE id_documento = p_id_documento;
END$$

CREATE PROCEDURE sp_buscar_documentos(
  IN p_texto VARCHAR(255)
)
BEGIN
  DECLARE q VARCHAR(255);
  SET q = CONCAT('%', fn_normalizar_titulo(p_texto), '%');

  SELECT d.id_documento,
         d.titulo,
         d.tipo,
         d.ruta,
         d.fecha_subida,
         d.version,
         d.estado,
         CONCAT(u.nom_usr, ' ', COALESCE(u.apellido,'')) AS autor,
         u.email AS correo_autor,
         fn_ultima_version(d.id_documento) AS cantidad_versiones
  FROM Documentos d
  LEFT JOIN Usuarios u ON u.id_usuario = d.id_usuario
  WHERE UPPER(d.titulo) LIKE q
     OR UPPER(d.tipo) LIKE q
  GROUP BY d.id_documento, d.titulo, d.tipo, d.ruta, d.fecha_subida, d.version, d.estado, u.nom_usr, u.apellido, u.email;
END$$
DELIMITER ;

-- TRIGGERS (AUDITORÍA)

DELIMITER $$
CREATE TRIGGER trg_documentos_ai
AFTER INSERT ON Documentos
FOR EACH ROW
BEGIN
  INSERT INTO Auditoria(id_usuario, tabla, accion, detalle)
  VALUES (NEW.id_usuario, 'Documentos', 'INSERT', CONCAT('DocID=', NEW.id_documento, ', Título=', NEW.titulo));
END$$

CREATE TRIGGER trg_documentos_au
AFTER UPDATE ON Documentos
FOR EACH ROW
BEGIN
  INSERT INTO Auditoria(id_usuario, tabla, accion, detalle)
  VALUES (NEW.id_usuario, 'Documentos', 'UPDATE', CONCAT('DocID=', NEW.id_documento, ', Título=', NEW.titulo));
END$$

CREATE TRIGGER trg_historial_ai
AFTER INSERT ON Historial_Documentos
FOR EACH ROW
BEGIN
  INSERT INTO Auditoria(id_usuario, tabla, accion, detalle)
  VALUES (NEW.id_usuario, 'Historial_Documentos', 'INSERT', CONCAT('DocID=', NEW.id_documento, ', Ruta=', NEW.ruta));
END$$

CREATE TRIGGER trg_doc_cat_ai
AFTER INSERT ON Documentos_Categorias
FOR EACH ROW
BEGIN
  INSERT INTO Auditoria(id_usuario, tabla, accion, detalle)
  SELECT d.id_usuario, 'Documentos_Categorias', 'INSERT', CONCAT('DocID=', d.id_documento, ', CatID=', NEW.id_categoria)
  FROM Documentos d
  WHERE d.id_documento = NEW.id_documento
  LIMIT 1;
END$$
DELIMITER ;

-- VISTAS 

CREATE OR REPLACE VIEW vw_documentos_detalle AS
SELECT
  d.id_documento,
  d.titulo,
  d.tipo,
  d.ruta,
  d.fecha_subida,
  d.version,
  d.estado,
  CONCAT(u.nom_usr, ' ', COALESCE(u.apellido,'')) AS autor,
  u.email AS correo_autor,
  fn_ultima_version(d.id_documento) AS cantidad_versiones,
  GROUP_CONCAT(DISTINCT c.nom_categoria ORDER BY c.nom_categoria SEPARATOR ', ') AS categorias
FROM Documentos d
LEFT JOIN Usuarios u ON u.id_usuario = d.id_usuario
LEFT JOIN Documentos_Categorias dc ON dc.id_documento = d.id_documento
LEFT JOIN Categorias c ON c.id_categoria = dc.id_categoria
GROUP BY d.id_documento, d.titulo, d.tipo, d.ruta, d.fecha_subida, d.version, d.estado, u.nom_usr, u.apellido, u.email;

CREATE OR REPLACE VIEW vw_historial_documentos AS
SELECT
  h.id_historial,
  h.id_documento,
  d.titulo,
  h.ruta,
  h.fecha_modificacion,
  CONCAT(u.nom_usr, ' ', COALESCE(u.apellido,'')) AS usuario
FROM Historial_Documentos h
JOIN Documentos d ON d.id_documento = h.id_documento
JOIN Usuarios u ON u.id_usuario = h.id_usuario;

CREATE OR REPLACE VIEW vw_documentos_por_categoria AS
SELECT
  c.id_categoria,
  c.nom_categoria,
  COUNT(dc.id_documento) AS cantidad_documentos
FROM Categorias c
LEFT JOIN Documentos_Categorias dc ON dc.id_categoria = c.id_categoria
GROUP BY c.id_categoria, c.nom_categoria
ORDER BY c.nom_categoria;

CREATE OR REPLACE VIEW vw_documentos_sin_categoria AS
SELECT d.*
FROM Documentos d
LEFT JOIN Documentos_Categorias dc ON dc.id_documento = d.id_documento
WHERE dc.id_documento IS NULL;

CREATE OR REPLACE VIEW vw_auditoria_reciente AS
SELECT a.id_auditoria,
       a.fecha_accion,
       CONCAT(u.nom_usr, ' ', COALESCE(u.apellido,'')) AS usuario,
       a.tabla,
       a.accion,
       a.detalle
FROM Auditoria a
LEFT JOIN Usuarios u ON u.id_usuario = a.id_usuario
ORDER BY a.fecha_accion DESC;
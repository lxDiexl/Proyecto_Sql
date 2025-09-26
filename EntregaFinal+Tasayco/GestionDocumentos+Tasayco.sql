
DROP DATABASE IF EXISTS gestion_archivo_documentos;
CREATE DATABASE gestion_archivo_documentos CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE gestion_archivo_documentos;

CREATE TABLE roles (
  id_rol INT AUTO_INCREMENT PRIMARY KEY,
  nom_rol VARCHAR(50) NOT NULL,
  desc_rol VARCHAR(200),
  UNIQUE KEY ux_roles_nom (nom_rol)
) ENGINE=InnoDB;

-- 2) departamentos
CREATE TABLE departamentos (
  id_departamento INT AUTO_INCREMENT PRIMARY KEY,
  nombre_departamento VARCHAR(100) NOT NULL,
  descripcion VARCHAR(255)
) ENGINE=InnoDB;

-- 3) usuarios (apego exacto a tu diagrama)
CREATE TABLE usuarios (
  id_usuario INT AUTO_INCREMENT PRIMARY KEY,
  nom_usr VARCHAR(100) NOT NULL,
  apellido VARCHAR(100) NOT NULL,
  dni VARCHAR(8),
  email VARCHAR(150) NOT NULL UNIQUE,
  contrasena VARCHAR(255) NOT NULL,
  id_rol INT NOT NULL,
  id_departamento INT NULL,
  fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (id_rol) REFERENCES roles(id_rol) ON UPDATE CASCADE ON DELETE RESTRICT,
  FOREIGN KEY (id_departamento) REFERENCES departamentos(id_departamento) ON UPDATE SET NULL ON DELETE SET NULL
) ENGINE=InnoDB;

-- 4) categorias (apego a tu diagrama)
CREATE TABLE categorias (
  id_categoria INT AUTO_INCREMENT PRIMARY KEY,
  nom_categoria VARCHAR(100) NOT NULL,
  descripcion VARCHAR(255),
  UNIQUE KEY ux_categorias_nom (nom_categoria)
) ENGINE=InnoDB;

-- 5) proyectos (nuevo: para clasificar documentos por proyecto)
CREATE TABLE proyectos (
  id_proyecto INT AUTO_INCREMENT PRIMARY KEY,
  nombre_proyecto VARCHAR(150) NOT NULL,
  descripcion TEXT,
  fecha_inicio DATE,
  fecha_fin DATE
) ENGINE=InnoDB;

-- 6) ubicaciones (almacenamiento físico/virtual)
CREATE TABLE ubicaciones (
  id_ubicacion INT AUTO_INCREMENT PRIMARY KEY,
  nombre_ubicacion VARCHAR(100) NOT NULL,
  detalles VARCHAR(255)
) ENGINE=InnoDB;

-- 7) documentos (mantener nombres EXACTOS)
CREATE TABLE documentos (
  id_documento INT AUTO_INCREMENT PRIMARY KEY,
  titulo VARCHAR(255) NOT NULL,
  tipo ENUM('Plano','Manual','Informe','Contrato','Otro') NOT NULL,
  fecha_subida TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  version VARCHAR(20) DEFAULT '1',
  estado ENUM('Activo','Archivado','Obsoleto') DEFAULT 'Activo',
  ruta VARCHAR(500) NOT NULL,
  id_usuario INT NOT NULL,
  id_proyecto INT NULL,
  id_ubicacion INT NULL,
  FOREIGN KEY (id_usuario) REFERENCES usuarios(id_usuario) ON UPDATE CASCADE ON DELETE RESTRICT,
  FOREIGN KEY (id_proyecto) REFERENCES proyectos(id_proyecto) ON UPDATE SET NULL ON DELETE SET NULL,
  FOREIGN KEY (id_ubicacion) REFERENCES ubicaciones(id_ubicacion) ON UPDATE SET NULL ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE INDEX idx_documentos_titulo ON documentos(titulo);
CREATE INDEX idx_documentos_tipo ON documentos(tipo);

-- 8) documentos_categorias (intermedia, EXACTO)
CREATE TABLE documentos_categorias (
  id_documento INT NOT NULL,
  id_categoria INT NOT NULL,
  PRIMARY KEY (id_documento, id_categoria),
  FOREIGN KEY (id_documento) REFERENCES documentos(id_documento) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (id_categoria) REFERENCES categorias(id_categoria) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- 9) historial_documentos (mantener EXACTO: no version field, solo ruta y fecha)
CREATE TABLE historial_documentos (
  id_historial INT AUTO_INCREMENT PRIMARY KEY,
  id_documento INT NOT NULL,
  ruta VARCHAR(500) NOT NULL,
  fecha_modificacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  id_usuario INT NOT NULL,
  FOREIGN KEY (id_documento) REFERENCES documentos(id_documento) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (id_usuario) REFERENCES usuarios(id_usuario) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE INDEX idx_historial_doc ON historial_documentos(id_documento);

-- 10) etiquetas (tags)
CREATE TABLE etiquetas (
  id_etiqueta INT AUTO_INCREMENT PRIMARY KEY,
  nom_etiqueta VARCHAR(100) NOT NULL UNIQUE
) ENGINE=InnoDB;

-- 11) document_etiquetas (N:M)
CREATE TABLE document_etiquetas (
  id_documento INT NOT NULL,
  id_etiqueta INT NOT NULL,
  PRIMARY KEY (id_documento, id_etiqueta),
  FOREIGN KEY (id_documento) REFERENCES documentos(id_documento) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (id_etiqueta) REFERENCES etiquetas(id_etiqueta) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- 12) permisos_documento (control acceso por usuario o por rol)
CREATE TABLE permisos_documento (
  id_permiso INT AUTO_INCREMENT PRIMARY KEY,
  id_documento INT NOT NULL,
  id_usuario INT NULL,
  id_rol INT NULL,
  nivel_access ENUM('lectura','escritura','administrador') DEFAULT 'lectura',
  fecha_asign TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (id_documento) REFERENCES documentos(id_documento) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (id_usuario) REFERENCES usuarios(id_usuario) ON DELETE SET NULL ON UPDATE CASCADE,
  FOREIGN KEY (id_rol) REFERENCES roles(id_rol) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB;

-- 13) metadatos_documentos (pares clave-valor)
CREATE TABLE metadatos_documentos (
  id_meta INT AUTO_INCREMENT PRIMARY KEY,
  id_documento INT NOT NULL,
  clave VARCHAR(100) NOT NULL,
  valor TEXT,
  FOREIGN KEY (id_documento) REFERENCES documentos(id_documento) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- 14) comentarios (transaccional)
CREATE TABLE comentarios (
  id_comentario INT AUTO_INCREMENT PRIMARY KEY,
  id_documento INT NOT NULL,
  id_usuario INT NOT NULL,
  comentario TEXT NOT NULL,
  fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (id_documento) REFERENCES documentos(id_documento) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (id_usuario) REFERENCES usuarios(id_usuario) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

-- 15) document_events (transaccional: views/downloads/edits)
CREATE TABLE document_events (
  id_evento INT AUTO_INCREMENT PRIMARY KEY,
  id_documento INT NOT NULL,
  id_usuario INT NULL,
  evento_type ENUM('view','download','edit','share','delete') NOT NULL,
  evento_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  detalle TEXT,
  FOREIGN KEY (id_documento) REFERENCES documentos(id_documento) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (id_usuario) REFERENCES usuarios(id_usuario) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE INDEX idx_events_tipo ON document_events(evento_type);
CREATE INDEX idx_events_doc ON document_events(id_documento);

-- 16) auditoria (mantener EXACTO a tu diagrama)
CREATE TABLE auditoria (
  id_auditoria INT AUTO_INCREMENT PRIMARY KEY,
  id_usuario INT NULL,
  tabla VARCHAR(50) NOT NULL,
  accion VARCHAR(255) NOT NULL,
  fecha_accion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  detalle VARCHAR(255),
  FOREIGN KEY (id_usuario) REFERENCES usuarios(id_usuario) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB;

-- 17) fact_document_activity (tabla de hechos para analítica)
CREATE TABLE fact_document_activity (
  id_fact INT AUTO_INCREMENT PRIMARY KEY,
  id_documento INT NOT NULL,
  fecha DATE NOT NULL,
  total_views INT DEFAULT 0,
  total_downloads INT DEFAULT 0,
  total_edits INT DEFAULT 0,
  total_shares INT DEFAULT 0,
  total_deletes INT DEFAULT 0,
  FOREIGN KEY (id_documento) REFERENCES documentos(id_documento) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

DELIMITER $$
CREATE FUNCTION fn_ultima_version(p_id_documento INT)
RETURNS INT
DETERMINISTIC
BEGIN
  DECLARE v INT;
  SELECT COALESCE(COUNT(*),0) INTO v
  FROM historial_documentos
  WHERE id_documento = p_id_documento;
  RETURN v;
END$$

CREATE FUNCTION fn_tiene_categoria(p_id_documento INT, p_id_categoria INT)
RETURNS TINYINT
DETERMINISTIC
BEGIN
  RETURN EXISTS(
    SELECT 1 FROM documentos_categorias
    WHERE id_documento = p_id_documento AND id_categoria = p_id_categoria
  );
END$$

CREATE FUNCTION fn_normalizar_titulo(p_txt VARCHAR(255))
RETURNS VARCHAR(255)
DETERMINISTIC
BEGIN
  DECLARE t VARCHAR(255);
  SET t = UPPER(TRIM(p_txt));
  WHILE INSTR(t,'  ') > 0 DO
    SET t = REPLACE(t,'  ',' ');
  END WHILE;
  RETURN t;
END$$

CREATE FUNCTION fn_fullname_user(p_id_usuario INT)
RETURNS VARCHAR(255)
DETERMINISTIC
BEGIN
  DECLARE s VARCHAR(255);
  SELECT CONCAT(nom_usr,' ',apellido) INTO s FROM usuarios WHERE id_usuario = p_id_usuario;
  RETURN s;
END$$
DELIMITER ;

DELIMITER $$
CREATE PROCEDURE sp_crear_documento(
  IN p_titulo VARCHAR(255),
  IN p_tipo VARCHAR(50),
  IN p_ruta VARCHAR(500),
  IN p_id_usuario INT,
  IN p_id_proyecto INT,
  IN p_id_ubicacion INT,
  OUT p_id_documento INT
)
BEGIN
  INSERT INTO documentos (titulo, tipo, ruta, id_usuario, id_proyecto, id_ubicacion, version, fecha_subida, estado)
  VALUES (p_titulo, p_tipo, p_ruta, p_id_usuario, p_id_proyecto, p_id_ubicacion, '1', NOW(), 'Activo');
  SET p_id_documento = LAST_INSERT_ID();
END$$

CREATE PROCEDURE sp_asignar_categoria(
  IN p_id_documento INT,
  IN p_id_categoria INT
)
BEGIN
  IF NOT EXISTS (SELECT 1 FROM documentos_categorias WHERE id_documento = p_id_documento AND id_categoria = p_id_categoria) THEN
    INSERT INTO documentos_categorias (id_documento, id_categoria)
    VALUES (p_id_documento, p_id_categoria);
  END IF;
END$$

CREATE PROCEDURE sp_agregar_version(
  IN p_id_documento INT,
  IN p_ruta VARCHAR(500),
  IN p_id_usuario INT,
  OUT p_version INT
)
BEGIN
  SET p_version = fn_ultima_version(p_id_documento) + 1;
  INSERT INTO historial_documentos (id_documento, ruta, fecha_modificacion, id_usuario)
  VALUES (p_id_documento, p_ruta, NOW(), p_id_usuario);
  UPDATE documentos
  SET ruta = p_ruta, version = CAST(p_version AS CHAR), fecha_subida = NOW()
  WHERE id_documento = p_id_documento;
END$$

CREATE PROCEDURE sp_generar_fact_activity(IN p_fecha DATE)
BEGIN
  -- Limpia registros del día (si existe) para refrescar
  DELETE FROM fact_document_activity WHERE fecha = p_fecha;

  -- Agrega agregados por documento
  INSERT INTO fact_document_activity (id_documento, fecha, total_views, total_downloads, total_edits, total_shares, total_deletes)
  SELECT
    de.id_documento,
    DATE(de.evento_timestamp) AS fecha,
    SUM(CASE WHEN de.evento_type = 'view' THEN 1 ELSE 0 END) AS total_views,
    SUM(CASE WHEN de.evento_type = 'download' THEN 1 ELSE 0 END) AS total_downloads,
    SUM(CASE WHEN de.evento_type = 'edit' THEN 1 ELSE 0 END) AS total_edits,
    SUM(CASE WHEN de.evento_type = 'share' THEN 1 ELSE 0 END) AS total_shares,
    SUM(CASE WHEN de.evento_type = 'delete' THEN 1 ELSE 0 END) AS total_deletes
  FROM document_events de
  WHERE DATE(de.evento_timestamp) = p_fecha
  GROUP BY de.id_documento, DATE(de.evento_timestamp);
END$$

CREATE PROCEDURE sp_buscar_documentos(IN p_texto VARCHAR(255))
BEGIN
  DECLARE q VARCHAR(255);
  SET q = CONCAT('%', fn_normalizar_titulo(p_texto), '%');
  SELECT d.id_documento, d.titulo, d.tipo, d.ruta, d.fecha_subida, d.version, d.estado,
         CONCAT(u.nom_usr,' ',u.apellido) AS autor,
         u.email AS correo_autor,
         fn_ultima_version(d.id_documento) AS cantidad_versiones
  FROM documentos d
  LEFT JOIN usuarios u ON u.id_usuario = d.id_usuario
  WHERE UPPER(d.titulo) LIKE q OR UPPER(d.tipo) LIKE q;
END$$
DELIMITER ;

DELIMITER $$
-- Insert document -> auditoria
CREATE TRIGGER trg_documentos_ai
AFTER INSERT ON documentos
FOR EACH ROW
BEGIN
  INSERT INTO auditoria (id_usuario, tabla, accion, detalle)
  VALUES (NEW.id_usuario, 'documentos', 'INSERT', CONCAT('DocID=', NEW.id_documento, ', Titulo=', NEW.titulo));
END$$

-- Update document -> auditoria
CREATE TRIGGER trg_documentos_au
AFTER UPDATE ON documentos
FOR EACH ROW
BEGIN
  INSERT INTO auditoria (id_usuario, tabla, accion, detalle)
  VALUES (NEW.id_usuario, 'documentos', 'UPDATE', CONCAT('DocID=', NEW.id_documento, ', Titulo=', NEW.titulo));
END$$

-- Insert historial -> auditoria
CREATE TRIGGER trg_historial_ai
AFTER INSERT ON historial_documentos
FOR EACH ROW
BEGIN
  INSERT INTO auditoria (id_usuario, tabla, accion, detalle)
  VALUES (NEW.id_usuario, 'historial_documentos', 'INSERT', CONCAT('DocID=', NEW.id_documento, ', Ruta=', NEW.ruta));
END$$

-- Insert documentos_categorias -> auditoria
CREATE TRIGGER trg_doc_cat_ai
AFTER INSERT ON documentos_categorias
FOR EACH ROW
BEGIN
  INSERT INTO auditoria (id_usuario, tabla, accion, detalle)
  SELECT d.id_usuario, 'documentos_categorias', 'INSERT', CONCAT('DocID=', d.id_documento, ', CatID=', NEW.id_categoria)
  FROM documentos d WHERE d.id_documento = NEW.id_documento LIMIT 1;
END$$

-- Insert eventos -> auditoria (por ejemplo cuando se registra view/download/edit)
CREATE TRIGGER trg_document_events_ai
AFTER INSERT ON document_events
FOR EACH ROW
BEGIN
  INSERT INTO auditoria (id_usuario, tabla, accion, detalle)
  VALUES (NEW.id_usuario, 'document_events', 'EVENT', CONCAT('DocID=', NEW.id_documento, ', Tipo=', NEW.evento_type));
END$$
DELIMITER ;

-- 1) detalle consolidado
CREATE OR REPLACE VIEW vw_documentos_detalle AS
SELECT d.id_documento,
       d.titulo,
       d.tipo,
       d.ruta,
       d.fecha_subida,
       d.version,
       d.estado,
       CONCAT(u.nom_usr,' ',COALESCE(u.apellido,'')) AS autor,
       u.email AS correo_autor,
       COALESCE(fn_ultima_version(d.id_documento),0) AS cantidad_versiones,
       GROUP_CONCAT(DISTINCT c.nom_categoria ORDER BY c.nom_categoria SEPARATOR ', ') AS categorias,
       p.nombre_proyecto AS proyecto,
       ub.nombre_ubicacion AS ubicacion
FROM documentos d
LEFT JOIN usuarios u ON u.id_usuario = d.id_usuario
LEFT JOIN documentos_categorias dc ON dc.id_documento = d.id_documento
LEFT JOIN categorias c ON c.id_categoria = dc.id_categoria
LEFT JOIN proyectos p ON p.id_proyecto = d.id_proyecto
LEFT JOIN ubicaciones ub ON ub.id_ubicacion = d.id_ubicacion
GROUP BY d.id_documento, d.titulo, d.tipo, d.ruta, d.fecha_subida, d.version, d.estado, u.nom_usr, u.apellido, u.email, p.nombre_proyecto, ub.nombre_ubicacion;

-- 2) historial (versiones)
CREATE OR REPLACE VIEW vw_historial_documentos AS
SELECT h.id_historial, h.id_documento, d.titulo, h.ruta, h.fecha_modificacion, CONCAT(u.nom_usr,' ',u.apellido) AS usuario
FROM historial_documentos h
JOIN documentos d ON d.id_documento = h.id_documento
JOIN usuarios u ON u.id_usuario = h.id_usuario;

-- 3) docs por categoria
CREATE OR REPLACE VIEW vw_documentos_por_categoria AS
SELECT c.id_categoria, c.nom_categoria, COUNT(dc.id_documento) AS cantidad_documentos
FROM categorias c
LEFT JOIN documentos_categorias dc ON dc.id_categoria = c.id_categoria
GROUP BY c.id_categoria, c.nom_categoria;

-- 4) docs sin categoria
CREATE OR REPLACE VIEW vw_documentos_sin_categoria AS
SELECT d.*
FROM documentos d
LEFT JOIN documentos_categorias dc ON dc.id_documento = d.id_documento
WHERE dc.id_documento IS NULL;

-- 5) auditoria reciente
CREATE OR REPLACE VIEW vw_auditoria_reciente AS
SELECT a.id_auditoria, a.fecha_accion, CONCAT(u.nom_usr,' ',u.apellido) AS usuario, a.tabla, a.accion, a.detalle
FROM auditoria a
LEFT JOIN usuarios u ON u.id_usuario = a.id_usuario
ORDER BY a.fecha_accion DESC;

-- 6) docs por proyecto (extra)
CREATE OR REPLACE VIEW vw_documentos_por_proyecto AS
SELECT p.id_proyecto, p.nombre_proyecto, COUNT(d.id_documento) AS total_documentos
FROM proyectos p
LEFT JOIN documentos d ON d.id_proyecto = p.id_proyecto
GROUP BY p.id_proyecto, p.nombre_proyecto;

-- 7) actividad diaria (vista rozada sobre fact)
CREATE OR REPLACE VIEW vw_actividad_diaria AS
SELECT f.id_documento, d.titulo, f.fecha, f.total_views, f.total_downloads, f.total_edits
FROM fact_document_activity f
JOIN documentos d ON d.id_documento = f.id_documento;

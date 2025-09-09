USE SistemaArchivos;
-- Roles
INSERT INTO Roles (nom_rol, desc_rol) VALUES
('Admin', 'Administrador del sistema'),
('Editor', 'Carga y versiona documentos'),
('Consulta', 'Solo lectura');

-- Usuarios (ajusta contraseñas/hashes según tu entorno)
INSERT INTO Usuarios (nom_usr, apellido, dni, email, contrasena, id_rol)
VALUES
('Diego', 'Tasayco', '12345678', 'diego.tasayco@example.com', 'hash_contraseña1', 1),
('Ana', 'Pérez', '87654321', 'ana.perez@example.com', 'hash_contraseña2', 2),
('Luis', 'Gómez', '11223344', 'luis.gomez@example.com', 'hash_contraseña3', 3);

-- Categorías (en tu diagrama categorias tiene 'descripcion' — ok)
INSERT INTO Categorias (nom_categoria, descripcion) VALUES
('Planos', 'Planos y esquemas técnicos'),
('Manuales', 'Manuales de operación y mantenimiento'),
('Informes', 'Informes técnicos y de inspección'),
('Contratos', 'Contratos y documentación legal');

-- Crear documentos usando el SP (capturando OUT en variables @)
SET @doc1_id = 0;
CALL sp_crear_documento(
  'Plano Planta A',
  'Plano',
  '/repo/docs/plano_planta_a_v1.pdf',
  1,
  @doc1_id
);

SET @doc2_id = 0;
CALL sp_crear_documento(
  'Manual Compresor X',
  'Manual',
  '/repo/docs/manual_compresor_x_v1.pdf',
  2,
  @doc2_id
);

SET @doc3_id = 0;
CALL sp_crear_documento(
  'Informe Inspección Q2',
  'Informe',
  '/repo/docs/informe_q2_v1.pdf',
  2,
  @doc3_id
);

-- Asignar categorías
CALL sp_asignar_categoria(@doc1_id, (SELECT id_categoria FROM Categorias WHERE nom_categoria = 'Planos' LIMIT 1));
CALL sp_asignar_categoria(@doc2_id, (SELECT id_categoria FROM Categorias WHERE nom_categoria = 'Manuales' LIMIT 1));
CALL sp_asignar_categoria(@doc3_id, (SELECT id_categoria FROM Categorias WHERE nom_categoria = 'Informes' LIMIT 1));

-- Agregar versiones (llama al SP que actualiza Documentos y guarda historial)
SET @v = 0;
CALL sp_agregar_version(@doc1_id, '/repo/docs/plano_planta_a_v2.pdf', 1, @v);

CALL sp_agregar_version(@doc2_id, '/repo/docs/manual_compresor_x_v2.pdf', 2, @v);

CALL sp_agregar_version(@doc3_id, '/repo/docs/informe_q2_v2.pdf', 2, @v);

-- Inserción directa adicional (opcional) usando columnas reales
INSERT INTO Documentos (titulo, tipo, ruta, id_usuario, version, fecha_subida, estado)
VALUES ('Procedimiento de Seguridad', 'Manual', '/repo/docs/procedimiento_seguridad_v1.pdf', 1, '1', NOW(), 'Activo');

-- SELECT * FROM vw_documentos_detalle;
-- SELECT * FROM vw_historial_documentos;
-- SELECT * FROM vw_documentos_por_categoria;
-- SELECT * FROM vw_auditoria_reciente LIMIT 50;

SELECT * FROM vw_documentos_detalle;
SELECT * FROM vw_historial_documentos;
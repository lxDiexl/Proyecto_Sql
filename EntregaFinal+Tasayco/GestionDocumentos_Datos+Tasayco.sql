USE gestion_archivo_documentos;

INSERT INTO roles (nom_rol, desc_rol) VALUES
('Admin','Administrador sistema'),
('Editor','Carga y gestiona versiones'),
('Consulta','Solo lectura');

INSERT INTO departamentos (nombre_departamento, descripcion) VALUES
('Ingeniería','Depto. Ingeniería'),
('Mantenimiento','Depto. Mantenimiento'),
('Operaciones','Depto. Operaciones');

INSERT INTO usuarios (nom_usr, apellido, dni, email, contrasena, id_rol, id_departamento)
VALUES
('Diego','Tasayco','12345678','diego.tasayco@example.com','hash1',1,1),
('Ana','Pérez','87654321','ana.perez@example.com','hash2',2,2),
('Luis','Gómez','11223344','luis.gomez@example.com','hash3',3,3),
('Carla','Salas','22334455','carla.salas@example.com','hash4',2,1);

INSERT INTO categorias (nom_categoria, descripcion) VALUES
('Planos','Planos y esquemas técnicos'),
('Manuales','Manuales de operación'),
('Informes','Informes técnicos'),
('Contratos','Documentos legales'),
('Procedimientos','Procedimientos operativos');

INSERT INTO proyectos (nombre_proyecto, descripcion, fecha_inicio) VALUES
('Proyecto Planta A','Construcción planta A', '2024-01-01'),
('Proyecto Planta B','Mejoras planta B','2024-06-01');

INSERT INTO ubicaciones (nombre_ubicacion, detalles) VALUES
('Repositorio Central','S3://empresa/documentos'),
('Servidor Local','/var/docs');

SET @doc1=0;
CALL sp_crear_documento('Plano Planta A','Plano','/repo/docs/plano_planta_a_v1.pdf',1,1,1,@doc1);

SET @doc2=0;
CALL sp_crear_documento('Manual Compresor X','Manual','/repo/docs/manual_compresor_x_v1.pdf',2,1,1,@doc2);

SET @doc3=0;
CALL sp_crear_documento('Informe Inspección Q2','Informe','/repo/docs/informe_q2_v1.pdf',2,2,2,@doc3);

SET @doc4=0;
CALL sp_crear_documento('Contrato Servicio ABC','Contrato','/repo/docs/contrato_abc_v1.pdf',1,NULL,1,@doc4);

CALL sp_asignar_categoria(@doc1, (SELECT id_categoria FROM categorias WHERE nom_categoria='Planos' LIMIT 1));
CALL sp_asignar_categoria(@doc2, (SELECT id_categoria FROM categorias WHERE nom_categoria='Manuales' LIMIT 1));
CALL sp_asignar_categoria(@doc3, (SELECT id_categoria FROM categorias WHERE nom_categoria='Informes' LIMIT 1));
CALL sp_asignar_categoria(@doc4, (SELECT id_categoria FROM categorias WHERE nom_categoria='Contratos' LIMIT 1));

SET @v=0;
CALL sp_agregar_version(@doc1, '/repo/docs/plano_planta_a_v2.pdf', 1, @v);
CALL sp_agregar_version(@doc1, '/repo/docs/plano_planta_a_v3.pdf', 1, @v);

CALL sp_agregar_version(@doc2, '/repo/docs/manual_compresor_x_v2.pdf', 2, @v);

INSERT INTO etiquetas (nom_etiqueta) VALUES ('Seguridad'),('Urgente'),('Mantenimiento');

INSERT INTO document_etiquetas (id_documento, id_etiqueta)
VALUES (@doc1, (SELECT id_etiqueta FROM etiquetas WHERE nom_etiqueta='Seguridad' LIMIT 1)),
       (@doc2, (SELECT id_etiqueta FROM etiquetas WHERE nom_etiqueta='Mantenimiento' LIMIT 1));

INSERT INTO metadatos_documentos (id_documento, clave, valor)
VALUES (@doc1, 'Formato', 'PDF'),
       (@doc1, 'AutorInterno','Técnico A'),
       (@doc2, 'Formato','PDF');


INSERT INTO comentarios (id_documento, id_usuario, comentario)
VALUES (@doc1, 2, 'Revisar escala del plano.'),
       (@doc3, 3, 'Agregar observaciones de prueba.');

INSERT INTO document_events (id_documento, id_usuario, evento_type, detalle)
VALUES
(@doc1, 2, 'view', 'Visualizado para revisión'),
(@doc1, 3, 'download', 'Descargado por técnica'),
(@doc1, 2, 'edit', 'Ajuste de capas'),
(@doc2, 2, 'view','Lectura manual'),
(@doc3, 3, 'download','Exportado PDF');

-- SELECT * FROM vw_documentos_detalle LIMIT 50;
-- SELECT * FROM vw_historial_documentos WHERE id_documento = @doc1;
-- SELECT * FROM vw_documentos_por_categoria;
-- SELECT * FROM vw_documentos_sin_categoria;
-- SELECT * FROM vw_auditoria_reciente LIMIT 50;
-- SELECT * FROM fact_document_activity WHERE fecha = CURDATE();

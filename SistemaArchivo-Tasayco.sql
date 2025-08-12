-- Creación de la base de datos
CREATE DATABASE IF NOT EXISTS SistemaArchivos;
USE SistemaArchivos;

-- Tabla: Roles
CREATE TABLE Roles (
    id_rol INT AUTO_INCREMENT PRIMARY KEY,
    nom_rol VARCHAR(50) NOT NULL,
    desc_rol VARCHAR(200)
);
-- COMENTARIOS DE EVALUACION:                      --

-- Tabla: Usuarios
CREATE TABLE Usuarios (
    id_usuario INT AUTO_INCREMENT PRIMARY KEY NOT NULL,
    nom_usr VARCHAR(100) NOT NULL,
    apellido VARCHAR(100) NOT NULL,
    dni VARCHAR(8) UNIQUE NOT NULL,
    email VARCHAR(150) UNIQUE NOT NULL,
    contrasena VARCHAR(255) NOT NULL,
    id_rol INT NOT NULL,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_rol) REFERENCES Roles(id_rol)
);
-- COMENTARIOS DE EVALUACION:                      --

-- Tabla: Documentos
CREATE TABLE Documentos (
    id_documento INT AUTO_INCREMENT PRIMARY KEY,
    titulo VARCHAR(255) NOT NULL,
    tipo ENUM('PLANO', 'MANUAL', 'INFORME', 'CONTRATO') NOT NULL,
	fecha_subida TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    version VARCHAR(20) DEFAULT '1.0',
    estado ENUM('Activo', 'Archivado', 'Obsoleto') NOT NULL,
    ruta VARCHAR(255) NOT NULL,
    id_usuario INT NOT NULL,
    FOREIGN KEY (id_usuario) REFERENCES Usuarios(id_usuario)
);
-- COMENTARIOS DE EVALUACION:                      --

-- Tabla: Categorías
CREATE TABLE Categorias (
    id_categoria INT AUTO_INCREMENT PRIMARY KEY,
    nom_categoria VARCHAR(100) UNIQUE NOT NULL,
    descripcion VARCHAR(255)
);
-- COMENTARIOS DE EVALUACION:                      --

-- Tabla intermedia: Documentos_Categorías
CREATE TABLE Documentos_Categorias (
    id_documento INT NOT NULL,
    id_categoria INT NOT NULL,
    PRIMARY KEY (id_documento, id_categoria),
    FOREIGN KEY (id_documento) REFERENCES Documentos(id_documento),
    FOREIGN KEY (id_categoria) REFERENCES Categorias(id_categoria)
);
-- COMENTARIOS DE EVALUACION:                      --

-- Tabla: Historial_Documentos
CREATE TABLE Historial_Documentos (
    id_historial INT AUTO_INCREMENT PRIMARY KEY,
    id_documento INT NOT NULL,
    ruta VARCHAR(255) NOT NULL,
    fecha_modificacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    id_usuario INT NOT NULL,
    FOREIGN KEY (id_documento) REFERENCES Documentos(id_documento),
    FOREIGN KEY (id_usuario) REFERENCES Usuarios(id_usuario)
);
-- COMENTARIOS DE EVALUACION:                      --

-- Tabla: Auditoría
CREATE TABLE Auditoria (
    id_auditoria INT AUTO_INCREMENT PRIMARY KEY,
    id_usuario INT NOT NULL,
    tabla VARCHAR(50) NOT NULL,
    accion VARCHAR(255) NOT NULL,
    fecha_accion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    detalle VARCHAR(255) NOT NULL,
    FOREIGN KEY (id_usuario) REFERENCES Usuarios(id_usuario)
);
-- COMENTARIOS DE EVALUACION:                      --

-- ============================================================
-- AgroConecta - Script DDL PostgreSQL
-- CC3088 Bases de Datos 1, Ciclo 1-2026
-- Universidad del Valle de Guatemala
-- ============================================================

-- Limpiar tablas si existen (orden inverso por FK)
DROP TABLE IF EXISTS REPORTE_CALIDAD CASCADE;
DROP TABLE IF EXISTS RESENA CASCADE;
DROP TABLE IF EXISTS PAGO CASCADE;
DROP TABLE IF EXISTS DETALLE_PEDIDO CASCADE;
DROP TABLE IF EXISTS PEDIDO CASCADE;
DROP TABLE IF EXISTS DIRECCION_ENTREGA CASCADE;
DROP TABLE IF EXISTS INVENTARIO_DISTRIBUIDOR CASCADE;
DROP TABLE IF EXISTS PRODUCTO CASCADE;
DROP TABLE IF EXISTS CATEGORIA CASCADE;
DROP TABLE IF EXISTS DISTRIBUIDOR CASCADE;
DROP TABLE IF EXISTS AGRICULTOR CASCADE;
DROP TABLE IF EXISTS USUARIO CASCADE;

-- ────────────────────────────────────────────────────────────
-- TABLA: USUARIO
-- ────────────────────────────────────────────────────────────
CREATE TABLE USUARIO (
    id_usuario       SERIAL PRIMARY KEY,
    nombre           VARCHAR(150) NOT NULL,
    telefono         VARCHAR(15)  NOT NULL UNIQUE,
    email            VARCHAR(100) UNIQUE,
    contrasena_hash  TEXT         NOT NULL,
    tipo_usuario     VARCHAR(20)  NOT NULL
                         CHECK (tipo_usuario IN ('agricultor','distribuidor','admin')),
    activo           BOOLEAN      NOT NULL DEFAULT TRUE,
    fecha_registro   TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ────────────────────────────────────────────────────────────
-- TABLA: AGRICULTOR
-- ────────────────────────────────────────────────────────────
CREATE TABLE AGRICULTOR (
    id_agricultor        SERIAL PRIMARY KEY,
    id_usuario           INT          NOT NULL UNIQUE REFERENCES USUARIO(id_usuario),
    departamento         VARCHAR(50)  NOT NULL,
    municipio            VARCHAR(80),
    tipo_agricultor      VARCHAR(20)  NOT NULL
                             CHECK (tipo_agricultor IN ('pequena_escala','empresarial')),
    tamano_terreno_ha    DECIMAL(10,2),
    cultivos_principales TEXT,
    tiene_membresia      BOOLEAN      NOT NULL DEFAULT FALSE
);

-- ────────────────────────────────────────────────────────────
-- TABLA: DISTRIBUIDOR
-- ────────────────────────────────────────────────────────────
CREATE TABLE DISTRIBUIDOR (
    id_distribuidor       SERIAL PRIMARY KEY,
    id_usuario            INT          NOT NULL UNIQUE REFERENCES USUARIO(id_usuario),
    nombre_negocio        VARCHAR(150) NOT NULL,
    nit                   VARCHAR(20)  UNIQUE,
    departamento          VARCHAR(50)  NOT NULL,
    municipio             VARCHAR(80),
    estado_verificacion   VARCHAR(20)  NOT NULL DEFAULT 'pendiente'
                              CHECK (estado_verificacion IN ('pendiente','aprobado','suspendido')),
    fecha_verificacion    DATE,
    calificacion_promedio DECIMAL(3,2) DEFAULT 0
                              CHECK (calificacion_promedio >= 0 AND calificacion_promedio <= 5)
);

-- ────────────────────────────────────────────────────────────
-- TABLA: CATEGORIA
-- ────────────────────────────────────────────────────────────
CREATE TABLE CATEGORIA (
    id_categoria SERIAL PRIMARY KEY,
    nombre       VARCHAR(80) NOT NULL UNIQUE,
    descripcion  TEXT
);

-- ────────────────────────────────────────────────────────────
-- TABLA: PRODUCTO
-- ────────────────────────────────────────────────────────────
CREATE TABLE PRODUCTO (
    id_producto           SERIAL PRIMARY KEY,
    id_categoria          INT          NOT NULL REFERENCES CATEGORIA(id_categoria),
    nombre                VARCHAR(150) NOT NULL,
    marca                 VARCHAR(100),
    descripcion           TEXT,
    composicion           TEXT,
    dosis_recomendada     TEXT,
    instrucciones_uso     TEXT,
    calificacion_promedio DECIMAL(3,2) DEFAULT 0
                              CHECK (calificacion_promedio >= 0 AND calificacion_promedio <= 5),
    activo                BOOLEAN      NOT NULL DEFAULT TRUE
);

-- ────────────────────────────────────────────────────────────
-- TABLA: INVENTARIO_DISTRIBUIDOR
-- ────────────────────────────────────────────────────────────
CREATE TABLE INVENTARIO_DISTRIBUIDOR (
    id_inventario        SERIAL PRIMARY KEY,
    id_distribuidor      INT           NOT NULL REFERENCES DISTRIBUIDOR(id_distribuidor),
    id_producto          INT           NOT NULL REFERENCES PRODUCTO(id_producto),
    precio               DECIMAL(10,2) NOT NULL CHECK (precio > 0),
    stock_disponible     INT           NOT NULL DEFAULT 0 CHECK (stock_disponible >= 0),
    unidad_medida        VARCHAR(30)   NOT NULL,
    ultima_actualizacion TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (id_distribuidor, id_producto)
);

-- ────────────────────────────────────────────────────────────
-- TABLA: DIRECCION_ENTREGA
-- ────────────────────────────────────────────────────────────
CREATE TABLE DIRECCION_ENTREGA (
    id_direccion      SERIAL PRIMARY KEY,
    id_agricultor     INT          NOT NULL REFERENCES AGRICULTOR(id_agricultor),
    alias             VARCHAR(50),
    descripcion       TEXT         NOT NULL,
    departamento      VARCHAR(50)  NOT NULL,
    municipio         VARCHAR(80)  NOT NULL,
    latitud           DECIMAL(10,7),
    longitud          DECIMAL(10,7),
    es_predeterminada BOOLEAN      NOT NULL DEFAULT FALSE
);

-- ────────────────────────────────────────────────────────────
-- TABLA: PEDIDO
-- ────────────────────────────────────────────────────────────
CREATE TABLE PEDIDO (
    id_pedido         SERIAL PRIMARY KEY,
    id_agricultor     INT           NOT NULL REFERENCES AGRICULTOR(id_agricultor),
    id_distribuidor   INT           NOT NULL REFERENCES DISTRIBUIDOR(id_distribuidor),
    fecha_pedido      TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    estado            VARCHAR(20)   NOT NULL DEFAULT 'pendiente'
                          CHECK (estado IN ('pendiente','confirmado','en_camino','entregado','cancelado')),
    tipo_entrega      VARCHAR(20)   NOT NULL
                          CHECK (tipo_entrega IN ('domicilio','punto_retiro')),
    direccion_entrega TEXT,
    es_urgente        BOOLEAN       NOT NULL DEFAULT FALSE,
    total_pedido      DECIMAL(12,2) NOT NULL CHECK (total_pedido >= 0),
    costo_envio       DECIMAL(8,2)  NOT NULL DEFAULT 0 CHECK (costo_envio >= 0),
    notas             TEXT
);

-- ────────────────────────────────────────────────────────────
-- TABLA: DETALLE_PEDIDO
-- ────────────────────────────────────────────────────────────
CREATE TABLE DETALLE_PEDIDO (
    id_detalle      SERIAL PRIMARY KEY,
    id_pedido       INT           NOT NULL REFERENCES PEDIDO(id_pedido),
    id_inventario   INT           NOT NULL REFERENCES INVENTARIO_DISTRIBUIDOR(id_inventario),
    cantidad        INT           NOT NULL CHECK (cantidad > 0),
    precio_unitario DECIMAL(10,2) NOT NULL CHECK (precio_unitario > 0),
    subtotal        DECIMAL(12,2) NOT NULL CHECK (subtotal > 0)
);

-- ────────────────────────────────────────────────────────────
-- TABLA: PAGO
-- ────────────────────────────────────────────────────────────
CREATE TABLE PAGO (
    id_pago                SERIAL PRIMARY KEY,
    id_pedido              INT           NOT NULL UNIQUE REFERENCES PEDIDO(id_pedido),
    metodo_pago            VARCHAR(30)   NOT NULL
                               CHECK (metodo_pago IN ('efectivo','tigo_money','banrural_movil')),
    monto                  DECIMAL(12,2) NOT NULL CHECK (monto > 0),
    estado_pago            VARCHAR(20)   NOT NULL DEFAULT 'pendiente'
                               CHECK (estado_pago IN ('pendiente','completado','fallido')),
    fecha_pago             TIMESTAMP,
    referencia_transaccion VARCHAR(100)
);

-- ────────────────────────────────────────────────────────────
-- TABLA: RESENA
-- ────────────────────────────────────────────────────────────
CREATE TABLE RESENA (
    id_resena     SERIAL PRIMARY KEY,
    id_agricultor INT       NOT NULL REFERENCES AGRICULTOR(id_agricultor),
    id_producto   INT       NOT NULL REFERENCES PRODUCTO(id_producto),
    id_pedido     INT       NOT NULL REFERENCES PEDIDO(id_pedido),
    calificacion  INT       NOT NULL CHECK (calificacion BETWEEN 1 AND 5),
    comentario    TEXT,
    fecha_resena  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (id_agricultor, id_producto, id_pedido)
);

-- ────────────────────────────────────────────────────────────
-- TABLA: REPORTE_CALIDAD
-- ────────────────────────────────────────────────────────────
CREATE TABLE REPORTE_CALIDAD (
    id_reporte           SERIAL PRIMARY KEY,
    id_agricultor        INT       NOT NULL REFERENCES AGRICULTOR(id_agricultor),
    id_pedido            INT       NOT NULL REFERENCES PEDIDO(id_pedido),
    id_producto          INT       NOT NULL REFERENCES PRODUCTO(id_producto),
    descripcion_problema TEXT      NOT NULL,
    estado_reporte       VARCHAR(20) NOT NULL DEFAULT 'abierto'
                             CHECK (estado_reporte IN ('abierto','en_revision','resuelto')),
    fecha_reporte        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    resolucion           TEXT
);

-- ============================================================
-- FIN DEL SCRIPT
-- ============================================================

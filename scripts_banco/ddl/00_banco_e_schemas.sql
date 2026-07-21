/* 00 - Banco e schemas */
USE master;
GO

IF DB_ID('DeliFitDB') IS NULL
    CREATE DATABASE DeliFitDB;
GO

USE DeliFitDB;
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'oltp')
    EXEC('CREATE SCHEMA oltp');
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'dw')
    EXEC('CREATE SCHEMA dw');
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'stg')
    EXEC('CREATE SCHEMA stg');
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'violacao')
    EXEC('CREATE SCHEMA violacao');
GO

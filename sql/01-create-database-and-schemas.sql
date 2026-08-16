/*
  Project : E-Commerce Customer & Sales Analytics
  Platform: Microsoft SQL Server
  Purpose : Create the database and logical layers used by the project.

  Expected source tables are loaded into the staging schema from the public
  Brazilian Olist e-commerce CSV files. The remaining scripts are rerunnable.
*/

IF DB_ID(N'EcommerceAnalytics') IS NULL
BEGIN
    CREATE DATABASE EcommerceAnalytics;
END;
GO

USE EcommerceAnalytics;
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = N'staging')
    EXEC(N'CREATE SCHEMA staging AUTHORIZATION dbo;');
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = N'analytics')
    EXEC(N'CREATE SCHEMA analytics AUTHORIZATION dbo;');
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = N'reporting')
    EXEC(N'CREATE SCHEMA reporting AUTHORIZATION dbo;');
GO


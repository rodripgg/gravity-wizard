@echo off
title Crear estructura de proyecto Godot - Gravedad Invertida

echo Creando estructura de carpetas...

REM =========================
REM CORE
REM =========================
mkdir scenes
mkdir scripts
mkdir assets
mkdir autoload
mkdir resources
mkdir addons

REM =========================
REM SCENES
REM =========================
mkdir scenes\main
mkdir scenes\levels
mkdir scenes\player
mkdir scenes\weapons
mkdir scenes\objects
mkdir scenes\enemies
mkdir scenes\ui
mkdir scenes\fx
mkdir scenes\test

REM =========================
REM SCRIPTS
REM =========================
mkdir scripts\core
mkdir scripts\player
mkdir scripts\weapons
mkdir scripts\objects
mkdir scripts\enemies
mkdir scripts\ui
mkdir scripts\levels
mkdir scripts\fx
mkdir scripts\autoload

REM =========================
REM ASSETS
REM =========================
mkdir assets\sprites
mkdir assets\sprites\player
mkdir assets\sprites\objects
mkdir assets\sprites\enemies
mkdir assets\sprites\tiles
mkdir assets\sprites\ui
mkdir assets\audio
mkdir assets\audio\sfx
mkdir assets\audio\music
mkdir assets\fonts
mkdir assets\materials
mkdir assets\particles

REM =========================
REM RESOURCES
REM =========================
mkdir resources\levels
mkdir resources\themes
mkdir resources\input
mkdir resources\data

REM =========================
REM DOCUMENTATION
REM =========================
mkdir docs
mkdir docs\design
mkdir docs\notes

echo.
echo Estructura creada correctamente.
echo.
pause
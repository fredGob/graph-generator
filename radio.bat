@echo off
setlocal
title Tuner - serveur local

REM ============================================================
REM  Lance un serveur HTTP local dans ce dossier, puis ouvre
REM  la radio dans le navigateur par defaut.
REM  Le serveur est obligatoire : YouTube refuse de lire une
REM  page ouverte en file:// (erreur 153, en-tete Referer absent).
REM ============================================================

set PORT=8000
cd /d "%~dp0"

REM --- 1. le serveur tourne-t-il deja ? ------------------------
netstat -ano | findstr /r /c:"LISTENING" | findstr /c:":%PORT% " >nul 2>&1
if %errorlevel%==0 (
  echo Serveur deja actif sur le port %PORT%.
  goto :open
)

REM --- 2. trouver un interpreteur Python -----------------------
set PY=
where py >nul 2>&1 && set PY=py -3
if not defined PY ( where python >nul 2>&1 && set PY=python )

if not defined PY (
  echo.
  echo   Python est introuvable dans le PATH.
  echo   Ouvre une invite de commandes dans ce dossier et lance
  echo   manuellement un serveur, ou installe Python.
  echo.
  pause
  exit /b 1
)

REM --- 3. demarrer le serveur en fenetre reduite ----------------
echo Demarrage du serveur sur le port %PORT%...
start "Tuner - serveur (ne pas fermer)" /min cmd /c "%PY% -m http.server %PORT%"

REM --- 4. laisser le temps au serveur de repondre ---------------
timeout /t 2 /nobreak >nul

:open
start "" "http://localhost:%PORT%/radio.html"
exit /b 0

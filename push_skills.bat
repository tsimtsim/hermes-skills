@echo off
title Hermes Skills - Push to GitHub
echo Pushing E:\hermes-skills to GitHub via WSL...
echo.
wsl.exe bash -lc "cd '/mnt/e/hermes-skills' && ./push_skills.sh"
echo.
echo ============================================
echo  Check the output above for errors.
echo ============================================
pause

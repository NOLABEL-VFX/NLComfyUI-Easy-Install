@echo off
setlocal
cd /D %~dp0

if not defined UVargs set "UVargs=--no-cache --link-mode=copy"
set "NL_INSTALL_ROOT=%cd%"
:: If launched from the parent folder, target the nested ComfyUI-Easy-Install root.
if exist "%cd%\ComfyUI-Easy-Install\" set "NL_INSTALL_ROOT=%cd%\ComfyUI-Easy-Install"
set "NL_COMFY_DIR=%NL_INSTALL_ROOT%\ComfyUI"
set "NL_PYTHON=%NL_INSTALL_ROOT%\python_embeded\python.exe"

echo %green%::::::::::::::: %yellow%Nolabel custom node stack%green% :::::::::::::::%reset%
echo.

call :get_node https://github.com/Lightricks/ComfyUI-LTXVideo/ ComfyUI-LTXVideo
call :get_node https://github.com/ltdrdata/ComfyUI-Impact-Pack ComfyUI-Impact-Pack
call :get_node https://github.com/Fannovel16/ComfyUI-Frame-Interpolation ComfyUI-Frame-Interpolation
call :get_node https://github.com/akatz-ai/ComfyUI-DepthCrafter-Nodes ComfyUI-DepthCrafter-Nodes
call :get_node https://github.com/LAOGOU-666/Comfyui-Memory_Cleanup Comfyui-Memory_Cleanup
call :get_node https://github.com/FuouM/ComfyUI-MatAnyone ComfyUI-MatAnyone
call :get_node https://github.com/alexjx/ComfyUI-Sa2VA-XJ ComfyUI-Sa2VA-XJ
call :get_node https://github.com/Comfy-Org/Nvidia_RTX_Nodes_ComfyUI Nvidia_RTX_Nodes_ComfyUI

call :run_postscript
call :run_optional_addons
call :delete_ezi_output_shortcut

echo %green%Nolabel custom install steps completed.%reset%
echo.
endlocal
goto :eof

:get_node
set "git_url=%~1"
set "git_folder=%~2"
echo %green%::::::::::::::: Installing%yellow% %git_folder% %green%:::::::::::::::%reset%
echo.
git.exe clone %git_url% "%NL_COMFY_DIR%\custom_nodes\%git_folder%"

setlocal enabledelayedexpansion
if exist "%NL_COMFY_DIR%\custom_nodes\%git_folder%\requirements.txt" (
    for %%F in ("%NL_COMFY_DIR%\custom_nodes\%git_folder%\requirements.txt") do set filesize=%%~zF
    if not !filesize! equ 0 (
        "%NL_PYTHON%" -I -m uv pip install -r "%NL_COMFY_DIR%\custom_nodes\%git_folder%\requirements.txt" %UVargs%
    )
)

if exist "%NL_COMFY_DIR%\custom_nodes\%git_folder%\install.py" (
    for %%F in ("%NL_COMFY_DIR%\custom_nodes\%git_folder%\install.py") do set filesize=%%~zF
    if not !filesize! equ 0 (
        "%NL_PYTHON%" -I "%NL_COMFY_DIR%\custom_nodes\%git_folder%\install.py"
    )
)
endlocal

echo.
goto :eof

:run_postscript
set "POSTSCRIPT_BASE=\\alien\comfyui"
set "POSTSCRIPT_SOURCE=%POSTSCRIPT_BASE%\extra_model_paths.yaml"
set "POSTSCRIPT_TARGET=%NL_COMFY_DIR%\extra_model_paths.yaml"
set "POSTSCRIPT_NL_REQUIREMENTS=%POSTSCRIPT_BASE%\custom_nodes\ComfyUI-NL_Nodes\requirements.txt"

echo %green%::::::::::::::: %yellow%Postscript: Importing extra_model_paths.yaml%green% :::::::::::::::%reset%
echo.

if not exist "%POSTSCRIPT_SOURCE%" (
    echo %warning%WARNING:%reset% Could not find %yellow%%POSTSCRIPT_SOURCE%%reset%
    echo.
    goto :eof
)

for /f "delims=" %%i in ('powershell -NoProfile -ExecutionPolicy Bypass -command "$folder = New-Object -ComObject Shell.Application; $selection = $folder.BrowseForFolder(0, 'Select your MODELS folder for extra_model_paths.yaml', 512+1+64, 17); if($selection) { $selection.Self.Path }"') do set "POSTSCRIPT_MODELS=%%i"

if not defined POSTSCRIPT_MODELS (
    echo %warning%WARNING:%reset% No models folder selected. Skipping postscript.
    echo.
    goto :eof
)

if not exist "%POSTSCRIPT_MODELS%" (
    echo %warning%WARNING:%reset% Selected models folder does not exist: %yellow%%POSTSCRIPT_MODELS%%reset%
    echo.
    goto :eof
)

copy /Y "%POSTSCRIPT_SOURCE%" "%POSTSCRIPT_TARGET%" >nul
if errorlevel 1 (
    echo %warning%WARNING:%reset% Failed to copy %yellow%extra_model_paths.yaml%reset% into %yellow%%NL_COMFY_DIR%%reset%
    echo.
    goto :eof
)

set "POSTSCRIPT_MODELS_FORWARD=%POSTSCRIPT_MODELS:\=/%"
powershell -NoProfile -ExecutionPolicy Bypass -command "$target=$env:POSTSCRIPT_TARGET; $base=$env:POSTSCRIPT_MODELS_FORWARD; $content=Get-Content -LiteralPath $target -Raw; $content=$content.Replace('C:/AI/ComfyUI',$base); Set-Content -LiteralPath $target -Value $content -Encoding UTF8"

if exist "%POSTSCRIPT_NL_REQUIREMENTS%" (
    echo %green%Postscript:%reset% Installing requirements from %yellow%%POSTSCRIPT_NL_REQUIREMENTS%%reset%
    "%NL_PYTHON%" -I -m uv pip install -r "%POSTSCRIPT_NL_REQUIREMENTS%" %UVargs%
) else (
    echo %warning%WARNING:%reset% Could not find %yellow%%POSTSCRIPT_NL_REQUIREMENTS%%reset%
)

echo %green%Postscript completed:%reset% %yellow%extra_model_paths.yaml%reset% imported and updated, NL requirements installed.
echo.
goto :eof

:run_optional_addons
echo %green%::::::::::::::: %yellow%Installing Nolabel add-ons%green% :::::::::::::::%reset%
echo.

call :run_addon_pattern "FlashAttention*.bat" "FlashAttention"
call :run_addon_pattern "SageAttention-Multi*.bat" "SageAttention-Multi"
goto :eof

:run_addon_pattern
set "ADDON_PATTERN=%~1"
set "ADDON_NAME=%~2"
set "ADDON_FOUND="

for /f "delims=" %%F in ('dir /b /a:-d ".\Add-Ons\%ADDON_PATTERN%" 2^>nul') do (
    set "ADDON_FOUND=1"
    echo %green%Add-on:%reset% Running %%F
    call ".\Add-Ons\%%F" NoPause
)

if not defined ADDON_FOUND (
    echo %warning%WARNING:%reset% Could not find Add-Ons script matching %yellow%%ADDON_PATTERN%%reset% for %yellow%%ADDON_NAME%%reset%
)

echo.
set "ADDON_PATTERN="
set "ADDON_NAME="
set "ADDON_FOUND="
goto :eof

:delete_ezi_output_shortcut
echo %green%::::::::::::::: %yellow%Postscript: Cleanup shortcuts%green% :::::::::::::::%reset%

del /f /q "%USERPROFILE%\Desktop\ComfyUI-EZi output.lnk" >nul 2>&1
del /f /q "%PUBLIC%\Desktop\ComfyUI-EZi output.lnk" >nul 2>&1

if exist "%USERPROFILE%\Desktop\ComfyUI-EZi output.lnk" (
    echo %warning%WARNING:%reset% Could not remove %yellow%%USERPROFILE%\Desktop\ComfyUI-EZi output.lnk%reset%
) else if exist "%PUBLIC%\Desktop\ComfyUI-EZi output.lnk" (
    echo %warning%WARNING:%reset% Could not remove %yellow%%PUBLIC%\Desktop\ComfyUI-EZi output.lnk%reset%
) else (
    echo %green%Removed %yellow%ComfyUI-EZi output%green% shortcut from desktop locations.%reset%
)

echo.
goto :eof

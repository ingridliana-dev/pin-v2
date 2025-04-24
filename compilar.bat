@echo off
echo Compilando o aplicativo PINReceiver...

:: Verificar se o MSBuild está disponível
where /q MSBuild.exe
if %ERRORLEVEL% neq 0 (
    echo MSBuild não encontrado. Procurando no Visual Studio...
    
    :: Tentar encontrar o MSBuild no Visual Studio 2022
    if exist "%ProgramFiles%\Microsoft Visual Studio\2022\Community\MSBuild\Current\Bin\MSBuild.exe" (
        set MSBUILD="%ProgramFiles%\Microsoft Visual Studio\2022\Community\MSBuild\Current\Bin\MSBuild.exe"
        goto :found
    )
    
    :: Tentar encontrar o MSBuild no Visual Studio 2019
    if exist "%ProgramFiles(x86)%\Microsoft Visual Studio\2019\Community\MSBuild\Current\Bin\MSBuild.exe" (
        set MSBUILD="%ProgramFiles(x86)%\Microsoft Visual Studio\2019\Community\MSBuild\Current\Bin\MSBuild.exe"
        goto :found
    )
    
    :: Tentar encontrar o MSBuild no Visual Studio 2017
    if exist "%ProgramFiles(x86)%\Microsoft Visual Studio\2017\Community\MSBuild\15.0\Bin\MSBuild.exe" (
        set MSBUILD="%ProgramFiles(x86)%\Microsoft Visual Studio\2017\Community\MSBuild\15.0\Bin\MSBuild.exe"
        goto :found
    )
    
    echo MSBuild não encontrado. Por favor, instale o Visual Studio Community.
    exit /b 1
) else (
    set MSBUILD=MSBuild.exe
)

:found
echo Usando MSBuild: %MSBUILD%

:: Restaurar pacotes NuGet
echo Restaurando pacotes NuGet...
nuget restore PINReceiverApp.sln

:: Compilar o projeto em modo Release
echo Compilando o projeto...
%MSBUILD% PINReceiverApp.sln /p:Configuration=Release /p:Platform="Any CPU"

:: Verificar se a compilação foi bem-sucedida
if %ERRORLEVEL% neq 0 (
    echo Erro na compilação.
    exit /b 1
)

:: Copiar os arquivos necessários para a pasta Executavel
echo Copiando arquivos para a pasta Executavel...
mkdir Executavel 2>nul
copy /Y PINReceiverApp\bin\Release\PINReceiverApp.exe Executavel\
copy /Y PINReceiverApp\bin\Release\*.dll Executavel\
copy /Y PINReceiverApp\bin\Release\*.config Executavel\

echo.
echo Compilação concluída com sucesso!
echo O executável está disponível na pasta Executavel\PINReceiverApp.exe
echo.

pause

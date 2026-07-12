@echo off
setlocal
set DIR=%~dp0
if "%~1"=="" (
  echo Please use Gradle wrapper to build Android projects.
  exit /b 1
)
set CLASSPATH=%DIR%gradle
apperinootstrap.jar
java -classpath "%CLASSPATH%" org.gradle.wrapper.GradleWrapperMain %*

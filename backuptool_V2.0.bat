:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::
::  ���ߣ�LZC
::  �汾��2.0
::  ���ڣ�20200908
::  ���룺GBK
::  ���ã�������Linux�������ݡ����õ��ļ�������Win��������
::  ������putty����(putty��plink��pscp)��powershell(win�Դ�)
::        .\cfg�ļ���(��ű��������ļ���1��ini��Ӧ1�������ļ�)
::  ������.\log�ļ���(���Զ����ɣ����ִ����־�ļ�)
::        .\his�ļ���(�Ǳ��룬�����ʱ���õ��ļ�)
::  �÷����س�ȷ�����ڣ�����ϵͳ���룬����ʾϵͳ���ݿռ�����ͱ���
::        �ļ���Ϣ�����Զ���ʼ���������ļ�����������ֱ�����б�����
::        ��������ɣ��ڼ���ܻ��С�����δ���ɡ������������С�����ʾ��
::        �����Ե����Ի�xshell�鿴
::  ���ܣ�1����鱾�ر��ݴ��̿ռ�
::        2��������ʽ����
::        3����ѯ��������ʣ��ռ�
::        4���жϱ�������״̬
::        5�����鱸���ļ�������
::        6����¼�����ļ�md5ֵ
::        7���Զ������ѿ����ļ�
::        8����¼ִ����־
::
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
@echo off
setlocal enabledelayedexpansion


set ymd=%date:~,4%%date:~5,2%%date:~8,2%
rem �޸Ŀ������ڣ��ſ�ע�ͣ��м�ִ����Ļ�
set ymd=20200703



rem ����ȫ�ֱ���
set cfgDir=cfg
set logDir=log
if not exist %logDir% md %logDir%
set saveDisk=D
set /a minGB=4
set saveDir=xxxx����

rem ȷ�ϵ�������
call :confirmtoday
set logFile=%logDir%\backup_%ymd%.log
set savePath=%saveDisk%:\%saveDir%\%ymd%
set md5File=%savePath%\md5_%ymd%.txt


rem ���ش��̼��
if exist %saveDisk%:\ (
    for /f "tokens=3" %%i in ('dir /-c %saveDisk%:\') do ( set freeSize=%%i)
) else (
    echo %saveDisk%�̲����ڣ��������ԣ�
    goto errend
)


rem ���ش��̿ռ���
set /a freeSizeG=%freeSize:~0,-3%/1073742 2>nul
if %freeSizeG% lss %minGB% (
    call :echolog "���̿ռ�С��%minGB%G�����������!"
    goto errend
)
set /a freeSizeM=%freeSize:~0,-3% %% 1073742 2>nul
set /a freeSizeM=%freeSizeM%/1074 2>nul
if %freeSizeM% lss 100 (
    if %freeSizeM% lss 10 (
        set freeSizeM=00%freeSizeM%
    ) else (
        set freeSizeM=0%freeSizeM%
    )
)
call :echolog "���ش��̿ռ䣺%freeSizeG%.%freeSizeM% GB [%saveDisk%��]"

rem ���cfgĿ¼
if not exist %cfgDir% (
    echo %cfgDir%Ŀ¼�����ڣ��������ԣ�
    goto errend
)

rem ����powershell�����ַ�����������ʽ��������
set "psCommand=powershell -NoProfile -Command "$pwd=Read-Host -AsSecureString "����"; [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($pwd))""

rem ������������
for /f %%i in ('dir /b /o %cfgDir%\*.ini') do (
    set cfgFile=%cfgDir%\%%i
    set hostPort=
    for /f "delims== tokens=1,2"  %%a in (!cfgFile!) do (
        if /i %%a==hostName (
            set hostName=%%b
        )
        if /i %%a==hostIP (
            set hostIP=%%b
        )
        if /i %%a==hostPort (
            set hostPort=%%b
        )
        if /i %%a==hostClass (
            set hostClass=%%b
        )
        if /i %%a==hostUser (
            set hostUser=%%b
        )
    )
    if not defined hostPort (
        set hostPort=22
    )
    call :checkconnect
    
    if not defined !hostClass!!hostUser!pw (
        set flag=
        set /a allowErrCount=3
        call :inputpasswd
        REM set display=show
        call :echolog "!hostClass!-!hostUser!����У��ɹ���"
        rem ���븳ֵ
        call set ^!hostClass^!^!hostUser^!pw=!passwd!
    )
    REM else (
        REM call set passwd=%%^!hostClass^!^!hostUser^!pw%%
        REM set flag=
        REM call :trylogin
        REM if not "!flag!"=="hello" (
            REM call :inputpasswd
        REM )
    REM )

)

call :echolog
rem ѭ����������
for /f %%i in ('dir /b /on %cfgDir%\*.ini') do (
    set cfgFile=%cfgDir%\%%i
    set cfgName=%%~ni
    call :echolog
    call :echolog "--------!cfgName! ��ʼ����--------"
    rem ��ȡini�ļ������屾�ο�����ر���
    set hostPort=
    set fileNamePre=
    set fileNameSuf=
    set localFileDir=
    set sinDir=
    for /f "delims== tokens=1,2"  %%a in (!cfgFile!) do (
        if /i %%a==hostName (
            set hostName=%%b
        )
        if /i %%a==hostIP (
            set hostIP=%%b
        )
        if /i %%a==hostPort (
            set hostPort=%%b
        )
        if /i %%a==hostClass (
            set hostClass=%%b
        )
        if /i %%a==hostUser (
            set hostUser=%%b
        )
        if /i %%a==remoteFileDir (
            set remoteFileDir=%%b
        )
        if /i %%a==fileNameSuf (
            set fileNameSuf=%%b
        )
        if /i %%a==fileNamePre (
            set fileNamePre=%%b
        )
        if /i %%a==localFileDir (
            set localFileDir=%%b
        )
    )
    if not defined hostPort (
        set hostPort=22
    )
    if defined localFileDir (
        set sinDir=!localFileDir!
        set localFileDir=!savePath!\!localFileDir!
    ) else (
        set localFileDir=!savePath!
    )
    set fileName=!fileNamePre!%ymd%!fileNameSuf!
    set remoteFilePath=!remoteFileDir!/!fileName!
    set localFilePath=!localFileDir!\!fileName!

    if defined !hostClass!!hostUser!pw (
        rem ����ȡֵ
        call set passwd=%%^!hostClass^!^!hostUser^!pw%%
        set flag=
        call :trylogin
        rem ����У��ʧ����������������
        if not "!flag!"=="hello" (
            set /a allowErrCount=3
            call :inputpasswd
            rem �����ٸ�ֵ
            call set ^!hostClass^!^!hostUser^!pw=!passwd!
        )
    ) else (
        set flag=
        set /a allowErrCount=3
        call :inputpasswd
        rem �����ٸ�ֵ
        call set ^!hostClass^!^!hostUser^!pw=!passwd!
    )

    if not exist "!savePath!" md "!savePath!"
    if not exist "!localFileDir!" md "!localFileDir!"
    call :echolog "%saveDir%Ŀ¼��!remoteFileDir!"

    rem ��鱸���ļ��Ƿ����
    set remoteFileRealPath=
    call :checkremotefile

    rem ��ȡԶ���ļ���
    set remoteFileName=
    for /f %%i in ('plink -batch -P !hostPort! -l !hostUser! -pw !passwd! !hostIP! "basename !remoteFileRealPath!"') do ( set remoteFileName=%%i)
    call :echolog "�����ļ����ƣ�!remoteFileName!"

    rem ��鱸���ļ��Ƿ�������
    call :filegrowingcheck

    rem ��ʾ�ļ���С
    set /a fileSize=!fileSize1!
    call :showfilesize "!fileSize!"

    rem ���Զ�̱��ݿռ�ʹ�����
    set remoteDiskFree=
    set remoteDiskFreeP=
    set remoteDiskOn=
    for /f "tokens=1,2,3" %%x in ('plink -batch -P !hostPort! -l !hostUser! -pw !passwd! !hostIP! "df -Ph !remoteFileDir! | tail -1 | awk '{print $4,$5,$6}'"') do (
        set remoteDiskFree=%%x
        set remoteDiskFreeP=%%y
        set remoteDiskOn=%%z
    )
    call :echolog "��鱸�ݿռ䣺!hostName!���ݹ��ص�!remoteDiskOn!��ʣ��ռ�!remoteDiskFree!����ʹ��!remoteDiskFreeP:~0,-1!%%%%"

    rem ��ȡԶ���ļ�MD5ֵ
    set remoteFileMd5=
    for /f %%i in ('plink -batch -P !hostPort! -l !hostUser! -pw !passwd! !hostIP! "[ -f !remoteFileRealPath! ] && md5sum !remoteFileRealPath!"') do ( set remoteFileMd5=%%i)
    if defined remoteFileMd5 (
        call :echolog "�����ļ� MD5��!remoteFileMd5!"
    ) else (
        call :echolog "�����ļ� MD5����ȡMD5ֵʧ�ܣ��޷��жϱ����Ƿ���ڣ��������ֱ�Ӹ��ǣ������������"
        pause >nul
    )
    call :echolog "���ش��Ŀ¼��!localFileDir!"
    
    if not "!remoteFileMd5!"=="" (
        rem �ж��Ƿ��ѿ������ļ�����MD5ֵ��
        call :filecheckexist
        if not "!checkExist!"=="yes" (
            rem ���ز�У���ļ�MD5ֵ
            call :downloadandgetmd5
            call :echolog "����У������MD5У��ɹ���"
        ) else (
            call :echolog "�����ļ����ڣ�!localFileDir!\!remoteFileName!����MD5ֵһ�£�����..."
        )

        call :md5checkrecord
        if not "!areadyRecord!"=="yes" (
            if defined sinDir (
                echo !remoteFileMd5!    !sinDir!\!remoteFileName!>> %md5File%
            ) else (
                echo !remoteFileMd5!    !remoteFileName!>> %md5File%
            )
        )
    ) else (
        pscp -r -P !hostPort! -l !hostUser! -pw !passwd! !hostIP!:!remoteFileRealPath! !localFileDir!
        call :echolog "����У���������ֶ�У�飡"
    )

    call :echolog "--------%%~ni �������--------"
    call :echolog
)
    call :echolog


call :echolog
call :echolog
call :echolog "������ȫ����ɣ�"
call :echolog
call :echolog
:errend
echo ������˳���
pause >nul
exit



:getsystime
set sysTime=%date:~,4%-%date:~5,2%-%date:~8,2% %time:~0,2%:%time:~3,2%:%time:~6,2% 
goto eof
:echolog
call :getsystime
if "%~1"=="" (
    echo.
    echo !sysTime!  >>%logFile%
) else (
    echo %~1
    echo !sysTime!  %~1>>%logFile%
)
goto eof
:log
call :getsystime
echo !sysTime!  %~1>>%logFile%
goto eof
:confirmtoday
set /p cfm=�س�ȷ�ϵ�ǰ����[%ymd%]
if defined cfm (
    echo ��Ч���룬������ȷ�ϣ�
    set cfm=
    REM call :confirmtoday
    goto confirmtoday
)
goto eof
:getyesterday
rem ͨ�������ļ��� ��ȡǰһ������
if not "%~1"=="" (
    if exist "%~1" (
        for /f %%i in ('dir /b /od "%~1"') do (
            set lastFolder=%%i
            if defined lastFolder (
                if "!lastFolder:~,2!"=="20" (
                    if not "!lastFolder:~7,1!"=="" (
                        if "!lastFolder:~8,1!"=="" (
                            set riqi=!lastFolder!
                        )
                    )
                )
            )
        )
    )
)
if not defined riqi set riqi=%ymd%
set /p inp=������һ��������[!riqi!]:
if "!inp!"=="" (
    set ymd=!riqi!
) else (
    set ymd=!inp!
)
rem У���������ڵĸ�ʽ(����������ֵ��Χ��20200000~20300000��ΪУ��ͨ�������ټ������·ݺ�������У��)
set /a digitDate=!ymd! 2>nul || set /a digitDate=0
if !digitDate! lss 20200000 (
    echo ���ڸ�ʽ����:!ymd!���������ԣ�
    goto errend
)
if !digitDate! gtr 20300000 (
    echo ���ڸ�ʽ����:!ymd!���������ԣ�
    goto errend
)
goto eof
:checkconnect
ping -n 1 !hostIP! >nul
if errorlevel 1 (
    call :echolog "ping����!hostName!����!hostIP!ʧ�ܣ������������������!"
    pause >nul
    goto checkconnect
)
goto eof
:trylogin
for /f %%i in ('plink -batch -P !hostPort! -l !hostUser! -pw !passwd! !hostIP! "echo hello" 2^>nul') do ( set flag=%%i)
goto eof
:inputpasswd
echo �ȴ�����!hostName!����!hostUser!�û�����...
for /f "usebackq" %%i in (`%psCommand%`) do ( set passwd=%%i)
call :trylogin
if not "!flag!"=="hello" (
    set /a allowErrCount-=1
    if !allowErrCount! leq 0 (
        call :echolog "������󣡴���������࣡"
        goto errend
    ) else (
        call :echolog "����������������룡[ʣ��!allowErrCount!��]"
        goto inputpasswd
    )
)
goto eof
:checkremotefile
for /f %%i in ('plink -batch -P !hostPort! -l !hostUser! -pw !passwd! !hostIP! "ls -ldrt !remoteFilePath! 2>/dev/null | awk '{print $NF}'"') do ( set remoteFileRealPath=%%i)
if not defined remoteFileRealPath (
    call :echolog "����δ���ɣ�!remoteFilePath!�����������������"
    pause >nul
    goto checkremotefile
)
goto eof
:filegrowingcheck
for /f %%i in ('plink -batch -P !hostPort! -l !hostUser! -pw !passwd! !hostIP! "du -k !remoteFileRealPath!"') do ( set fileSize1=%%i)
ping -n 3 127.1 >nul
for /f %%i in ('plink -batch -P !hostPort! -l !hostUser! -pw !passwd! !hostIP! "du -k !remoteFileRealPath!"') do ( set fileSize2=%%i)
if not "!fileSize1!"=="!fileSize2!" (
    call :echolog "���������У�!remoteFileRealPath!���Ժ������������"
    pause >nul
    goto filegrowingcheck
)
goto eof
:showfilesize
set fileSize=%~1
if !fileSize! lss 1048576 (
    set /a fileSizeMM=!fileSize!/1024 2>nul
    set /a fileSizeMK=!fileSize! %% 1024 2>nul
    set /a fileSizeMK=!fileSizeMK!*1000/1024 2>nul
    if !fileSizeMK! lss 100 (
        if !fileSizeMK! lss 10 (
            set fileSizeMK=00!fileSizeMK!
        ) else (
            set fileSizeMK=0!fileSizeMK!
        )
    )
    call :echolog "�����ļ���С��!fileSizeMM!.!fileSizeMK! MB"
) else (
    set /a fileSizeGG=!fileSize!/1048576 2>nul
    set /a fileSizeGM=!fileSize! %% 1048576 2>nul
    set /a fileSizeGM=!fileSizeGM!/1048 2>nul
    if !fileSizeGM! lss 100 (
        if !fileSizeGM! lss 10 (
            set fileSizeGM=00!fileSizeGM!
        ) else (
            set fileSizeGM=0!fileSizeGM!
        )
    )
    call :echolog "�����ļ���С��!fileSizeGG!.!fileSizeGM! GB"
)
goto eof
:showbnrsize
set /a bnrFileSize=%~z1/1024 2>nul
call :showfilesize "!bnrFileSize!"
goto eof
:getlocalfilemd5
for /f "tokens=* delims=" %%i in ('certutil -hashfile %1 MD5 ^| findstr /V :') do (
    set FileMd5=%%i
)
set localFileMd5=!FileMd5: =!
goto eof
:filecheckexist
set checkExist=
if exist "!localFileDir!\!remoteFileName!" (
    call :getlocalfilemd5 "!localFileDir!\!remoteFileName!"
    if "!remoteFileMd5!"=="!localFileMd5!" set checkExist=yes
)
goto eof
:downloadandgetmd5
pscp -r -P !hostPort! -l !hostUser! -pw !passwd! !hostIP!:!remoteFileRealPath! !localFileDir!
call :getlocalfilemd5 "!localFileDir!\!remoteFileName!"
if not "!localFileMd5!"=="!remoteFileMd5!" (
    call :echolog "MD5У��ʧ�ܣ�������������¿���!"
    pause >nul
    goto downloadandgetmd5
)
goto eof
:md5checkrecord
set areadyRecord=
if exist "%md5File%" (
    for /f "tokens=1,2" %%c in (%md5File%) do (
        if "%%c"=="!remoteFileMd5!" (
            if defined sinDir (
                if "%%d"=="!sinDir!\!remoteFileName!" (
                    set areadyRecord=yes
                )
            ) else (
                if "%%d"=="!remoteFileName!" (
                    set areadyRecord=yes
                )
            )
        )
    )
)
goto eof
:copybnrfilegetmd5
copy /V /Y /Z !bnrFileDir!\!bnrFileName! !savePath! >nul
call :getlocalfilemd5 "!savePath!\!bnrFileName!"
goto eof
:eof
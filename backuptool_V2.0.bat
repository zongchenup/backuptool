:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::
::  作者：LZC
::  版本：2.0
::  日期：20200908
::  编码：GBK
::  作用：拷贝各Linux机器备份、配置等文件到本地Win操作机中
::  依赖：putty工具(putty、plink、pscp)、powershell(win自带)
::        .\cfg文件夹(存放备份描述文件，1个ini对应1个备份文件)
::  附带：.\log文件夹(可自动生成，存放执行日志文件)
::        .\his文件夹(非必须，存放暂时不用的文件)
::  用法：回车确认日期，输入系统密码，会显示系统备份空间情况和备份
::        文件信息，并自动开始拷贝备份文件，以上依次直到所有备份文
::        件拷贝完成，期间可能会有“备份未生成”“备份生成中”等提示，
::        可以稍等再试或xshell查看
::  功能：1、检查本地备份磁盘空间
::        2、密码隐式输入
::        3、查询各服务器剩余空间
::        4、判断备份生成状态
::        5、检验备份文件完整性
::        6、记录备份文件md5值
::        7、自动跳过已拷贝文件
::        8、记录执行日志
::
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
@echo off
setlocal enabledelayedexpansion


set ymd=%date:~,4%%date:~5,2%%date:~8,2%
rem 修改拷贝日期，放开注释，切记执行完改回
set ymd=20200703



rem 定义全局变量
set cfgDir=cfg
set logDir=log
if not exist %logDir% md %logDir%
set saveDisk=D
set /a minGB=4
set saveDir=xxxx备份

rem 确认当天日期
call :confirmtoday
set logFile=%logDir%\backup_%ymd%.log
set savePath=%saveDisk%:\%saveDir%\%ymd%
set md5File=%savePath%\md5_%ymd%.txt


rem 本地磁盘检查
if exist %saveDisk%:\ (
    for /f "tokens=3" %%i in ('dir /-c %saveDisk%:\') do ( set freeSize=%%i)
) else (
    echo %saveDisk%盘不存在，检查后重试！
    goto errend
)


rem 本地磁盘空间检查
set /a freeSizeG=%freeSize:~0,-3%/1073742 2>nul
if %freeSizeG% lss %minGB% (
    call :echolog "磁盘空间小于%minGB%G，清理后重试!"
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
call :echolog "本地磁盘空间：%freeSizeG%.%freeSizeM% GB [%saveDisk%盘]"

rem 检查cfg目录
if not exist %cfgDir% (
    echo %cfgDir%目录不存在，检查后重试！
    goto errend
)

rem 定义powershell命令字符串，用以隐式密码输入
set "psCommand=powershell -NoProfile -Command "$pwd=Read-Host -AsSecureString "密码"; [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($pwd))""

rem 集中输入密码
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
        call :echolog "!hostClass!-!hostUser!密码校验成功！"
        rem 密码赋值
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
rem 循环拷贝备份
for /f %%i in ('dir /b /on %cfgDir%\*.ini') do (
    set cfgFile=%cfgDir%\%%i
    set cfgName=%%~ni
    call :echolog
    call :echolog "--------!cfgName! 开始拷贝--------"
    rem 读取ini文件，定义本次拷贝相关变量
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
        rem 密码取值
        call set passwd=%%^!hostClass^!^!hostUser^!pw%%
        set flag=
        call :trylogin
        rem 密码校验失败则重新输入密码
        if not "!flag!"=="hello" (
            set /a allowErrCount=3
            call :inputpasswd
            rem 密码再赋值
            call set ^!hostClass^!^!hostUser^!pw=!passwd!
        )
    ) else (
        set flag=
        set /a allowErrCount=3
        call :inputpasswd
        rem 密码再赋值
        call set ^!hostClass^!^!hostUser^!pw=!passwd!
    )

    if not exist "!savePath!" md "!savePath!"
    if not exist "!localFileDir!" md "!localFileDir!"
    call :echolog "%saveDir%目录：!remoteFileDir!"

    rem 检查备份文件是否存在
    set remoteFileRealPath=
    call :checkremotefile

    rem 获取远程文件名
    set remoteFileName=
    for /f %%i in ('plink -batch -P !hostPort! -l !hostUser! -pw !passwd! !hostIP! "basename !remoteFileRealPath!"') do ( set remoteFileName=%%i)
    call :echolog "备份文件名称：!remoteFileName!"

    rem 检查备份文件是否生成中
    call :filegrowingcheck

    rem 显示文件大小
    set /a fileSize=!fileSize1!
    call :showfilesize "!fileSize!"

    rem 检测远程备份空间使用情况
    set remoteDiskFree=
    set remoteDiskFreeP=
    set remoteDiskOn=
    for /f "tokens=1,2,3" %%x in ('plink -batch -P !hostPort! -l !hostUser! -pw !passwd! !hostIP! "df -Ph !remoteFileDir! | tail -1 | awk '{print $4,$5,$6}'"') do (
        set remoteDiskFree=%%x
        set remoteDiskFreeP=%%y
        set remoteDiskOn=%%z
    )
    call :echolog "检查备份空间：!hostName!备份挂载点!remoteDiskOn!，剩余空间!remoteDiskFree!，已使用!remoteDiskFreeP:~0,-1!%%%%"

    rem 获取远程文件MD5值
    set remoteFileMd5=
    for /f %%i in ('plink -batch -P !hostPort! -l !hostUser! -pw !passwd! !hostIP! "[ -f !remoteFileRealPath! ] && md5sum !remoteFileRealPath!"') do ( set remoteFileMd5=%%i)
    if defined remoteFileMd5 (
        call :echolog "备份文件 MD5：!remoteFileMd5!"
    ) else (
        call :echolog "备份文件 MD5：获取MD5值失败，无法判断本地是否存在，如存在则直接覆盖，任意键继续！"
        pause >nul
    )
    call :echolog "本地存放目录：!localFileDir!"
    
    if not "!remoteFileMd5!"=="" (
        rem 判断是否已拷贝（文件名、MD5值）
        call :filecheckexist
        if not "!checkExist!"=="yes" (
            rem 下载并校验文件MD5值
            call :downloadandgetmd5
            call :echolog "备份校验结果：MD5校验成功！"
        ) else (
            call :echolog "本地文件存在：!localFileDir!\!remoteFileName!，且MD5值一致，跳过..."
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
        call :echolog "备份校验结果：需手动校验！"
    )

    call :echolog "--------%%~ni 拷贝完成--------"
    call :echolog
)
    call :echolog


call :echolog
call :echolog
call :echolog "拷贝已全部完成！"
call :echolog
call :echolog
:errend
echo 任意键退出！
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
set /p cfm=回车确认当前日期[%ymd%]
if defined cfm (
    echo 无效输入，需重新确认！
    set cfm=
    REM call :confirmtoday
    goto confirmtoday
)
goto eof
:getyesterday
rem 通过备份文件夹 获取前一日日期
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
set /p inp=输入上一备份日期[!riqi!]:
if "!inp!"=="" (
    set ymd=!riqi!
) else (
    set ymd=!inp!
)
rem 校验输入日期的格式(纯数字且数值范围在20200000~20300000即为校验通过，不再继续做月份和天数的校验)
set /a digitDate=!ymd! 2>nul || set /a digitDate=0
if !digitDate! lss 20200000 (
    echo 日期格式有误:!ymd!，检查后重试！
    goto errend
)
if !digitDate! gtr 20300000 (
    echo 日期格式有误:!ymd!，检查后重试！
    goto errend
)
goto eof
:checkconnect
ping -n 1 !hostIP! >nul
if errorlevel 1 (
    call :echolog "ping测试!hostName!机器!hostIP!失败，检查网络后任意键继续!"
    pause >nul
    goto checkconnect
)
goto eof
:trylogin
for /f %%i in ('plink -batch -P !hostPort! -l !hostUser! -pw !passwd! !hostIP! "echo hello" 2^>nul') do ( set flag=%%i)
goto eof
:inputpasswd
echo 等待输入!hostName!主机!hostUser!用户密码...
for /f "usebackq" %%i in (`%psCommand%`) do ( set passwd=%%i)
call :trylogin
if not "!flag!"=="hello" (
    set /a allowErrCount-=1
    if !allowErrCount! leq 0 (
        call :echolog "密码错误！错误次数过多！"
        goto errend
    ) else (
        call :echolog "密码错误！需重新输入！[剩余!allowErrCount!次]"
        goto inputpasswd
    )
)
goto eof
:checkremotefile
for /f %%i in ('plink -batch -P !hostPort! -l !hostUser! -pw !passwd! !hostIP! "ls -ldrt !remoteFilePath! 2>/dev/null | awk '{print $NF}'"') do ( set remoteFileRealPath=%%i)
if not defined remoteFileRealPath (
    call :echolog "备份未生成：!remoteFilePath!，检查后任意键继续！"
    pause >nul
    goto checkremotefile
)
goto eof
:filegrowingcheck
for /f %%i in ('plink -batch -P !hostPort! -l !hostUser! -pw !passwd! !hostIP! "du -k !remoteFileRealPath!"') do ( set fileSize1=%%i)
ping -n 3 127.1 >nul
for /f %%i in ('plink -batch -P !hostPort! -l !hostUser! -pw !passwd! !hostIP! "du -k !remoteFileRealPath!"') do ( set fileSize2=%%i)
if not "!fileSize1!"=="!fileSize2!" (
    call :echolog "备份生成中：!remoteFileRealPath!，稍后任意键继续！"
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
    call :echolog "备份文件大小：!fileSizeMM!.!fileSizeMK! MB"
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
    call :echolog "备份文件大小：!fileSizeGG!.!fileSizeGM! GB"
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
    call :echolog "MD5校验失败，检查后任意键重新拷贝!"
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
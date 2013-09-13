#include constants.h

Set Procedure To functions.prg
Set Classlib To download.vcx
Set Classlib To registry.vcx Additive
Set Classlib To progressbarxp.vcx Additive
Set Classlib To outlook.vcx Additive
Set Classlib To systray.vcx Additive
Set Classlib To customs.vcx Additive

*----------------
Set Console Off
Set Exclusive Off
Set Safety Off
Set Century On
Set Date To Dmy
Set Deleted On
Set Help On
Set Talk Off
Set Escape Off
Set Exact On
Set Near Off
Set Multilocks On
Set ENGINEBEHAVIOR 70
Set REPORTBEHAVIOR 80
Set Seconds Off
Set Echo Off
Set Safety Off
Set Decimals To 2
Set Refresh To 0,-1
Set Seconds On
*----------------

rta=Addbs(Sys(5)+Sys(2003))

If !Checkclass("Chilkat.Http")
	If !RegisterDLL(rta+"ChilkatHttp.dll")
		Messagebox("Error con la libreria ChilkatHttp.dll"+Chr(13)+Chr(13)+"Ejecute el programa con permisos de administrador",0+64,"Aviso")
		Quit
	Endif
	If !RegisterDLL(rta+"CkString.dll")
		Messagebox("Error con la libreria CkString.dll"+Chr(13)+Chr(13)+"Ejecute el programa con permisos de administrador",0+64,"Aviso")
		Quit
	Endif
	If !RegisterDLL(rta+"ChilkatCert.dll")
		Messagebox("Error con la libreria ChilkatCert.dll"+Chr(13)+Chr(13)+"Ejecute el programa con permisos de administrador",0+64,"Aviso")
		Quit
	Endif
Endif

Do Form Main.scx
Read Events

#include constants.h
******************************************************************************************************************************
Function SpecialFolder
Lparameters tuFolder
Local lcPath, ;
	lnFolder, ;
	lcFolder, ;
	lnPidl, ;
	lnPidlFound, ;
	lnFolderFound

#Define CSIDL_APPDATA 0x1A
#Define CSIDL_COMMON_APPDATA 0x23
#Define CSIDL_DESKTOPDIRECTORY 0x10
#Define CSIDL_LOCAL_APPDATA 0x1C
#Define CSIDL_PERSONAL 0x05
#Define CSIDL_INTERNET_CACHE 0x20

#Define ERR_ARGUMENT_INVALID 11
#Define MAX_PATH 260
#Define NOERROR 0
#Define SUCCESS 1

Do Case
Case Vartype(tuFolder) = 'N'
	lnFolder = tuFolder

Case Vartype(tuFolder) <> 'C' Or Empty(tuFolder)
	Error ERR_ARGUMENT_INVALID
	Return ''

Otherwise
	lcFolder = Upper(tuFolder)
	Do Case
	Case lcFolder = 'APPDATA'
		lnFolder = CSIDL_APPDATA
	Case lcFolder = 'COMMONAPPDATA'
		lnFolder = CSIDL_COMMON_APPDATA
	Case lcFolder = 'DESKTOP'
		lnFolder = CSIDL_DESKTOPDIRECTORY
	Case lcFolder = 'LOCALAPPDATA'
		lnFolder = CSIDL_LOCAL_APPDATA
	Case lcFolder = 'PERSONAL'
		lnFolder = CSIDL_PERSONAL
	Case lcFolder = 'INTERNETCACHE'
		lnFolder = CSIDL_INTERNET_CACHE
	Otherwise
		Error ERR_ARGUMENT_INVALID
		Return ''
	Endcase
Endcase

Declare Long SHGetSpecialFolderLocation In shell32 Long HWnd, Long nFolder, ;
	LONG @ ppidl
Declare Long SHGetPathFromIDList In shell32 Long Pidl, String @ pszPath
Declare CoTaskMemFree In ole32 Long pvoid

lcPath = Space(MAX_PATH)
lnPidl = 0

lnPidlFound = SHGetSpecialFolderLocation(0, lnFolder, @lnPidl)
If lnPidlFound = NOERROR
	lnFolderFound = SHGetPathFromIDList(lnPidl, @lcPath)
	If lnFolderFound = SUCCESS
		lcPath = Left(lcPath, At(Chr(0), lcPath) - 1)
	Endif lnFolderFound = SUCCESS
Endif lnPidlFound = NOERROR
CoTaskMemFree(lnPidl)
lcPath = Alltrim(lcPath)
Return lcPath
Endfunc
******************************************************************************************************************************
Function HTTPToStr
Lparameters lcURL

Local _str
loHttp = Createobject('Chilkat.Http')

lnSuccess = loHttp.UnlockComponent(DecodeB64(ChilkatKey))
If (lnSuccess <> 1) Then
	Release loHttp
	Return ''
Endif

loHttp.UseBgThread = 0
temporaryfile = Addbs(SpecialFolder('INTERNETCACHE'))+Sys(3)+".tmp"
lnSuccess = loHttp.Download(lcURL,temporaryfile)
Release loHttp

If (lnSuccess <> 1) Then
	Return ''
Endif

_str=Filetostr(temporaryfile)
Delete File (temporaryfile)

Return (_str)
Endfunc
******************************************************************************************************************************
Function EncodeB64
Lparameters _str

Return (Strconv(_str,13))
Endfunc
******************************************************************************************************************************
Function DecodeB64
Lparameters _str

Return (Strconv(_str,14))
Endfunc
******************************************************************************************************************************
Function CheckClass
Lparameters lcClass

Local loRegistry
loRegistry = Newobject("Registry")

If !loRegistry.Iskey(lcClass)
	Release loRegistry
	Return(.F.)
Endif
Return (.T.)
Endfunc
******************************************************************************************************************************
Function RegisterDLL
Lparameters _dll

Declare Integer DLLSelfRegister In "Vb6stkit.DLL" ;
	STRING lpDllName

Return (DLLSelfRegister(_dll) = 0)
Endfunc
******************************************************************************************************************************
Function urlEncode
Parameters tcValue, llNoPlus
Local lcResult, lcChar, lnSize, lnX

*** Do it in VFP Code
lcResult=""

For lnX=1 To Len(tcValue)
	lcChar = Substr(tcValue,lnX,1)
	If Atc(lcChar,"ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789") > 0
		lcResult=lcResult + lcChar
		Loop
	Endif
	If lcChar=" " And !llNoPlus
		lcResult = lcResult + "+"
		Loop
	Endif
*** Convert others to Hex equivalents
	lcResult = lcResult + "%" + Right(Transform(Asc(lcChar),"@0"),2)
Endfor
Return lcResult
Endfunc
******************************************************************************************************************************
Procedure Convert_Gpl
Lparameters _pname

If File(_pname)
	Select 0
	Create Cursor oldgpl (cad c(250))
	Append From (_pname) Sdf

	Select 0
	Create Cursor newgpl (nombre c(200), artista c(200), duracion c(10), kbps c(5), song_id c(10))

	Select oldgpl
	Go Top
	Delete
	Scan
		_song=Alltrim(Getwordnum(oldgpl.cad,2,"/"))
		_nom=Alltrim(Getwordnum(Strtran(oldgpl.cad,"/"+Alltrim(_song)+"/",""),2,"-"))
		_art=Alltrim(Getwordnum(oldgpl.cad,1,"-"))
		Select newgpl
		Append Blank
		Replace nombre With _nom
		Replace artista With _art
		Replace song_id With _song
	Endscan

	Select newgpl
	Go Top
	Copy To (_pname+"2") Type Csv

	Use In oldgpl
	Use In newgpl
Endif
Endproc
******************************************************************************************************************************
Function Tweet
Lparameters _tweet

_tweet=Left(_tweet,140)

Local loHttp
Local lnSuccess
Local loReq
Local loResp

loHttp = Createobject('Chilkat.Http')

lnSuccess = loHttp.UnlockComponent(DecodeB64(ChilkatKey))
If (lnSuccess <> 1) Then
	ret=loHttp.LastErrorText
	Release loHttp
	Return (ret)
Endif

loHttp.OAuth1 = 1
loHttp.OAuthVerifier = ""
loHttp.OAuthConsumerKey = DecodeB64(OAuth_ConsumerKey)
loHttp.OAuthConsumerSecret = DecodeB64(OAuth_ConsumerSecret)
loHttp.OAuthToken = DecodeB64(OAuth_Token)
loHttp.OAuthTokenSecret = DecodeB64(OAuth_TokenSecret)

loReq = Createobject('Chilkat.HttpRequest')
loReq.AddParam("status",_tweet)

loResp = loHttp.PostUrlEncoded("https://api.twitter.com/1.1/statuses/update.json",loReq)

If (loResp = Null ) Then
	ret=loHttp.LastErrorText
	Release loHttp
	Release loReq
	Release loResp
	Return (ret)
Endif

If !(loResp.StatusCode = 200) Then
	ret=loHttp.LastErrorText
	Release loHttp
	Release loReq
	Release loResp
	Return (ret)
Endif

Release loResp
Release loHttp
Release loReq
Return ("")
******************************************************************************************************************************
Function ObtenerPIN
Local loHttp
Local lnSuccess
Local loReq
Local loResp
Local lcOauthToken
Local lcOauthTokenSecret
Local lcOauthCbConfirmed

loHttp = Createobject('Chilkat.Http')

lnSuccess = loHttp.UnlockComponent(DecodeB64(ChilkatKey))
If (lnSuccess <> 1) Then
	ret=loHttp.LastErrorText
	Release loHttp
	Return (ret)
Endif

loHttp.OAuth1 = 1
loHttp.OAuthConsumerKey = DecodeB64(OAuth_ConsumerKey)
loHttp.OAuthConsumerSecret = DecodeB64(OAuth_ConsumerSecret)

loReq = Createobject('Chilkat.HttpRequest')

loResp = loHttp.PostUrlEncoded("https://api.twitter.com/oauth/request_token",loReq)

If (loResp = Null ) Then
	ret=loHttp.LastErrorText
	Release loHttp
	Release loReq
	Release loResp
	Return (ret)
Endif

If (loResp.StatusCode = 200) Then
	lcOauthToken = loResp.UrlEncParamValue(loResp.BodyStr,"oauth_token")
	lcOauthTokenSecret = loResp.UrlEncParamValue(loResp.BodyStr,"oauth_token_secret")
	lcOauthCbConfirmed = loResp.UrlEncParamValue(loResp.BodyStr,"oauth_callback_confirmed")

	ret="TOKEN="+lcOauthToken+";SECRET="+lcOauthTokenSecret+";CONFIRMED="+lcOauthCbConfirmed

	poExplorer = Createobject("InternetExplorer.Application")
	poExplorer.Navigate("https://api.twitter.com/oauth/authenticate?oauth_token="+Alltrim(lcOauthToken))
	poExplorer.Visible=.T.
Else
	ret=loHttp.LastErrorText
	Release loHttp
	Release loReq
	Release loResp
	Return (ret)
Endif

Release loHttp
Release loReq
Release loResp
Return (ret)
******************************************************************************************************************************
Function ObtenerTokens
Lparameters pin,token

Local loHttp
Local lnSuccess
Local loReq
Local loResp
Local lcOauthToken
Local lcOauthTokenSecret

loHttp = Createobject('Chilkat.Http')

lnSuccess = loHttp.UnlockComponent(DecodeB64(ChilkatKey))
If (lnSuccess <> 1) Then
	ret=loHttp.LastErrorText
	Release loHttp
	Return (ret)
Endif

loHttp.OAuth1 = 1
loHttp.OAuthConsumerKey = DecodeB64(OAuth_ConsumerKey)
loHttp.OAuthConsumerSecret = DecodeB64(OAuth_ConsumerSecret)
loHttp.OAuthToken = Alltrim(token)
loHttp.OAuthVerifier = Alltrim(pin)

loReq = Createobject('Chilkat.HttpRequest')

loResp = loHttp.PostUrlEncoded("https://api.twitter.com/oauth/access_token",loReq)

If (loResp = Null ) Then
	ret=loHttp.LastErrorText
	Release loHttp
	Release loReq
	Release loResp
	Return (ret)
Endif

If (loResp.StatusCode = 200) Then
	lcOauthToken = loResp.UrlEncParamValue(loResp.BodyStr,"oauth_token")
	lcOauthTokenSecret = loResp.UrlEncParamValue(loResp.BodyStr,"oauth_token_secret")
Else
	ret=loHttp.LastErrorText
	Release loHttp
	Release loReq
	Release loResp
	Return (ret)
Endif

Release loHttp
Release loReq
Release loResp
Return ("TOKEN="+lcOauthToken+";SECRET="+lcOauthTokenSecret+";")
******************************************************************************************************************************
Function GetMp3Location
Lparameters full_id

Local obj
Local campo

obj=Createobject("chilkat.http")
obj.UnlockComponent(DecodeB64(ChilkatKey))
obj.FollowRedirects=0
Resp=obj.QuickGetObj(MP3URLGet+full_id)
If Vartype(Resp)="O"
	campo=Resp.GetHeaderField("location")  && retorna URL al mp3.... super fast.
Else
	campo=""
Endif
Release obj
Release Resp
Return (campo)
******************************************************************************************************************************
Function ShortenURL
Lparameters _url

bitlylogin="o_2pd26imb5s"
bitlyapikey="R_ecead8baf68634fd4cf99036dd2a3077"

*cadurl=urlencode("http://gedl.tk/player.php?song="+urlartist+"-"+urltitle+"&songurl="+urltodownload)

ShortenURL="https://api-ssl.bitly.com/v3/shorten?login="+bitlylogin+"&apiKey="+bitlyapikey+"&format=xml&longUrl="+_url
shorturlxml=HTTPToStr(ShortenURL)
response=Alltrim(Strextract(shorturlxml,"<status_code>","</status_code>"))
If response!="200" && hay un codigo de error ??
	Messagebox("Ocurrio un error al acortar la url"+Chr(13)+Chr(13)+"Intente de nuevo",0+64,"Error")
	url_recortada=""
	RETURN (url_recortada)
Else
	url_recortada=Alltrim(Strextract(shorturlxml,"<url>","</url>"))
Endif
Return (url_recortada)
******************************************************************************************************************************
**** FUNCION RANDOM SEQUENCE DE RANDOM.ORG
******************************************************************************************************************************
Function GenerateRandomList
Lparameters _max
If RandomORGQuota()>0
	Lista = HTTPToStr("http://www.random.org/sequences/?min=1&max="+Alltrim(Str(_max))+"&col=1&format=plain&rnd=new")
Else
	Lista = GenerateRandomLocal(_max)
Endif
Lista = ConvertToCSV(Lista)
Return (Lista)
******************************************************************************************************************************
**** FUNCION RANDOM SEQUENCE LOCAL
******************************************************************************************************************************
Function GenerateRandomLocal
Lparameters __max

i=0
LaLista=Alltrim(Str(Int(Rand(-1)*__max)))+","
For i=1 To __max-1
	LaLista=LaLista+Alltrim(Str(Int(Rand()*__max)))+","
Endfor
LaLista=Left(LaLista,Len(LaLista)-1)
Return (LaLista)
******************************************************************************************************************************
**** FUNCION QUOTA DE RANDOM.ORG
******************************************************************************************************************************
Function RandomORGQuota
quota=Val(HTTPToStr("http://www.random.org/quota/?format=plain"))
Return (quota)
******************************************************************************************************************************
**** FUNCION Convertir Lista en renglones a Lista separada por comas
******************************************************************************************************************************
Function ConvertToCSV
Lparameters LaLista

i=0
ListaCSV = ""
For i=1 To Len(Alltrim(LaLista))
	caracter=Substr(LaLista,i,1)
	ListaCSV = ListaCSV + Iif(Isdigit(caracter),caracter,",")
Endfor
*ListaCSV=Alltrim(Strtran(LaLista,Chr(13),","))
If Right(ListaCSV,1)=","
	ListaCSV=Left(ListaCSV,Len(ListaCSV)-1)
Endif
Return (ListaCSV)

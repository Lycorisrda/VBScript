Const WinHttpRequestOption_EnableRedirects = 6
Dim url
If WScript.Arguments.Count>0 Then url = WScript.Arguments(0)
url = InputBox("������Ҫ����ض������ַ","����",url)
If url = False Then WScript.Quit

'��ȡ�ض���
Dim WinHttp
Set WinHttp = CreateObject("WinHttp.WinHttpRequest.5.1")
WinHttp.Open "GET", url, False
WinHttp.Option(WinHttpRequestOption_EnableRedirects) = False
WinHttp.Send
If WinHttp.Status = 302 Or WinHttp.Status = 301 Or WinHttp.Status = 303 Or WinHttp.Status = 307 Then
	Dim result
	result = WinHttp.GetResponseHeader("Location")
	x = InputBox("����ַ�ض���","���",result)
Else
	WScript.Echo "û���ض�����ַ���� " & WinHttp.Status & " ״̬"
End If
 
Set WinHttp = Nothing
Dim Files,customName
Set Files = WScript.Arguments '将参数（文件列表）存入类


Dim fso,oShell
Set fso = CreateObject("scripting.filesystemobject") '文件操作系统对象

If fso.FolderExists(Files(0)) Then
	customName = InputBox("请输入需要显示的名称（特殊字符亦可）","输入名称")
	If Len(customName) < 1 Then
		WScript.Quit
	End If
	
	Dim iniPath
	iniPath = Files(0) & "\desktop.ini"
	If fso.FileExists(iniPath) Then
		fso.GetFile(iniPath).Attributes =0
	End If
	SetIniValue Files(0) & "\desktop.ini",".ShellClassInfo","LocalizedResourceName",customName
	fso.GetFile(iniPath).Attributes = 2 + 4 + 32
'	fso.GetFolder(Files(0)).Attributes = 16
	oldAttributes = fso.GetFolder(Files(0)).Attributes
	fso.GetFolder(Files(0)).Attributes = 1 + 16 + 2 + 4
	fso.GetFolder(Files(0)).Attributes = oldAttributes
'	Set oShell = CreateObject("WScript.Shell")
'	oShell.Run "ATTRIB +R """ & Files(0) & """"
Else
	ShowLog Files(0) & vbCrLf & "不是文件夹或文件夹不存在"
	WScript.Quit
End If

Set fso = Nothing

'显示日志
Function ShowLog(str)
	WScript.Echo str
End Function

'是否符合正则表达式
Function RegExpTest(strng, patrn) 
	Dim regEx      ' 创建变量。
	Set regEx = New RegExp         ' 创建正则表达式。
	regEx.Pattern = patrn         ' 设置模式。
	regEx.IgnoreCase = True         ' 设置是否区分大小写，True为不区分。
	regEx.Global = True         ' 设置全程匹配。
	regEx.MultiLine = True
	RegExpTest = regEx.Test(strng)   ' 执行搜索。
	Set regEx = Nothing
End Function


'函数：设置ini值（ini路径，目标节点，目标键，目标值）
'注：若ini文件不存在则创建；节点或键不存在则添加
Function SetIniValue(path, sectionName, keyName, value)
	
	Dim fsot,file
	Set fsot = CreateObject("Scripting.FileSystemObject")
	Set file = fsot.OpenTextFile(path, 1,True,-2)
	
	Dim line, cache, inSection, sectionExist, keyExist
	Do Until file.AtEndOfStream
		line = file.Readline
		If StrComp(Trim(line),"["+sectionName+"]",1)=0 Then
			inSection=True
			sectionExist=True
		End If
		If inSection And Left(LTrim(line),1)="[" And StrComp(Trim(line),"["+sectionName+"]",1)<>0 Then
			inSection=False
			If Not keyExist Then
				cache = cache + keyName+"="+value+vbCrLf
				keyExist=True
			End If
		End If
		
		If inSection And InStr(line,"=")<>0 Then
			ss = Split(line,"=")
			If StrComp(Trim(ss(0)),keyName,1)=0 Then
				line = ss(0)+"="+value
				keyExist = True
			End If
		End If
		
		cache=cache+line+vbCrLf
		
	Loop
	
	file.Close
	
	If Not sectionExist Then
		cache = cache + "["+sectionName+"]"+vbCrLf
		cache = cache + keyName+"="+value+vbCrLf
	ElseIf Not keyExist Then
		cache = cache + keyName+"="+value+vbCrLf
	End If
	
	Set file = fsot.OpenTextFile(path, 2, True, -1)
	file.Write(cache)
	file.Close
	
End Function
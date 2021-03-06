'====================================
'变量定义区
'====================================
Dim ws,fs,rootFolder,message, _
	cLog,LogName, _
	EmptyFolder,TempFolder
Set osh = CreateObject("WScript.Shell")
set fso = CreateObject("Scripting.FileSystemObject")
cLog = True '是否生成日志文件
LogName = WScript.ScriptFullName & "_" & Replace(Replace(FormatDateTime(Now(),vbGeneralDate),"/","-"),":","-") & ".log" '日志名称
EmptyFolder = "(_Empty)" '空文件夹存放点
TempFolder = "(_Temp)" '转移用临时存放点

Dim Appname,Ver(2)
Appname = "自动缩减文件夹" '程序名称
Ver(0) = 3:Ver(1) = 1:Ver(2) = 0 '程序版本

'====================================
'程序启动判定区
'====================================
If WScript.Arguments.Count<1 Then
	WScript.Echo "请把需要缩减的父文件夹拖到本脚本上运行（既使用参数方式提供路径）"
	WScript.Quit
ElseIf LCase(Right(WScript.FullName,11)) = "wscript.exe" Then
    osh.run "cmd /c cscript.exe //nologo """ & WScript.ScriptFullName & """ """ & WScript.Arguments(0) & """"
    WScript.quit
End If
'If InStr(1,WScript.FullName,"WScript.exe",vbTextCompare)>1 Then
'	nocmd = MsgBox("本版程序建议使用命令行模式运行，请运行bat文件，否则会产生大量对话框。",vbokonly + vbExclamation,"缩减文件夹脚本 提示")
'	WScript.Quit
'End If

'====================================
'函数区
'====================================

'生成版本号
Function Version()
	Version = Join(Ver,".")
End Function

'搜寻文件夹迭代函数
Function FindChildren(FolderPath)
	set iFolder = fso.GetFolder(FolderPath)     '获取文件夹
	set iSubFolders = iFolder.SubFolders    '获取子目录集合
	set iFiles = iFolder.Files              '获取文件集合
	If iFiles.Count= 0 And iSubFolders.count = 1 Then '如果只有一个文件夹
		For each Cfolder in iSubFolders '迭代调用本函数
			FindChildren = FindChildren(Cfolder)
			Exit For
		Next
	ElseIf iFiles.Count> 0 Or iSubFolders.count > 1 Then '如果有文件或者两个及以上文件夹则为最内层
		FindChildren = FolderPath
	Else '什么都没有的空文件夹
		FindChildren = "empty"
	End if
End Function

'是否符合正则表达式
Function RegExpTest(strng, patrn) 
	Dim regEx      ' 创建变量。
	Set regEx = New RegExp         ' 创建正则表达式。
	regEx.Pattern = patrn         ' 设置模式。
	regEx.IgnoreCase = True         ' 设置是否区分大小写，True为不区分。
	regEx.Global = True         ' 设置全程匹配。
	RegExpTest = regEx.Test(strng)   ' 执行搜索。
	Set regEx = Nothing
End Function

'显示日志
Function ShowLog(str)
	WScript.Echo str
	If cLog then
		Set fLog = fso.opentextfile(LogName,8,True,-1)
		fLog.WriteLine(str)
		Set fLog = Nothing
	End If
End Function

'判断不是保留文件夹
Function NotPreservedFolder(Folder)
	NotPreservedFolder = True
	Dim PreservedFolder,FolderTemp
	
	PreservedFolder = EmptyPath
	If fso.FolderExists(PreservedFolder) Then
		Set FolderTemp = fso.GetFolder(PreservedFolder)
		If FolderTemp.Path = Folder.path Then
			NotPreservedFolder = False
			Exit Function
		End If
	End If
	
	PreservedFolder = TempPath
	If fso.FolderExists(PreservedFolder) Then
		Set FolderTemp = fso.GetFolder(PreservedFolder)
		If FolderTemp.Path = Folder.path Then
			NotPreservedFolder = False
			Exit Function
		End If
	End If

End Function
'====================================
'主代码
'====================================

If WScript.Arguments.Count<1 Then
	rootFolder = osh.CurrentDirectory '当前程序所在目录
Else
	rootFolder = WScript.Arguments(0) '将第一个参数存入
End If

Dim rootFolderFiles, rfFiles, rfSubFolders
set rootFolderFiles = fso.GetFolder(rootFolder)     '获取文件夹
set rfSubFolders = rootFolderFiles.SubFolders    '获取子目录集合
ShowLog "==========================================" & vbCrLf _
	& Date() & " " & Time() & " start" & vbCrLf _
	& Appname & " V" & Version & vbCrLf
ShowLog "路径 """ & rootFolder & """"
ShowLog "下共有" & rfSubFolders.count & "个子文件夹"

Dim OutsideFolder , Insidefolder ,NewFolder ,EmptyPath,TempPath
Dim Een,Esn,Emn,i
Een = 0
Esn = 0
Emn = 0
i = 0
EmptyPath = rootFolder & "\" & EmptyFolder
TempPath = rootFolder & "\" & TempFolder

For each OutsideFolder in rfSubFolders '遍历子文件夹
	'判断不是temp或empty文件夹
	If NotPreservedFolder(OutsideFolder) Then
		'调用访问最内层单文件夹迭代函数
		Insidefolder = FindChildren(OutsideFolder)
		i = i + 1
		If Insidefolder = "empty" Then '如果是空文件夹
			Een = Een + 1
			ShowLog i & vbTab & "/" & rfSubFolders.count & vbTab & "空"  & vbTab & """" & OutsideFolder.Name & """"
			If Not fso.FolderExists(EmptyPath) Then fso.CreateFolder(EmptyPath) '建立空文件夹
			fso.MoveFolder OutsideFolder,EmptyPath & "\" & OutsideFolder.Name '移动到空文件夹
		ElseIf Insidefolder = OutsideFolder Then '里外文件夹一样
			Esn = Esn + 1
			ShowLog i & vbTab & "/" & rfSubFolders.count & vbTab & "跳过"  & vbTab & """" & OutsideFolder.Name & """"
		Else
			Emn = Emn + 1
			ShowLog i & vbTab & "/" & rfSubFolders.count & vbTab & "移动中"  & vbTab & """" & OutsideFolder.Name & """"
			If Not fso.FolderExists(TempPath) Then fso.CreateFolder(TempPath) '建立临时文件夹
			fso.MoveFolder Insidefolder,TempPath & "\" & OutsideFolder.Name '移动到空文件夹
			NewFolder = OutsideFolder.Name '存储新的文件夹名
			Call fso.DeleteFolder(OutsideFolder,True) '删除老文件夹
			Call fso.MoveFolder(TempPath & "\" & NewFolder, rootFolder & "\" & NewFolder) '移动到新文件夹
			If fso.FolderExists(TempPath) Then fso.DeleteFolder(TempPath) '删除临时文件夹
		End If
	End If
Next

ShowLog vbCrLf & "总共" & Emn & "个移动，" & Esn & "个不变，" & Een & "个空文件夹" & vbCrLf & "（移至""" & EmptyPath & """）"
ShowLog vbCrLf & Date() & " " & Time() & " end" & vbCrLf  _
	& "==========================================" & vbCrLf 
	
Set ws=Nothing
Set fs=Nothing
WScript.Quit
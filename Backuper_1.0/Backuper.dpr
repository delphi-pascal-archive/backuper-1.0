program Backuper;

uses
  Windows, Sysutils, FileCtrl, Classes;

{
  BackUper for DataBase 1.0
  vkssoft (c) 2006

  Синтаксис:

  Backuper From To
  *** Эта программа копирует все файлы из директории From
      (и её поддиректорий) в директорию To
      Если From не указана - копируется текущая папка,
      если To не указана - копируется в папку backup в текущем
      каталоге.

  NOTE: code not optimized, DEBUG it =)
        about bugs email me vks100@mail.ru
}

{$R *.RES}

var
   count: Integer = 0;
   FileList: TStringList;
   DirList: TStringList;
   log_access: Boolean = true;
   log: TextFile;

const
  MASK = '*.*';
  LOG_NAME = 'backuper.log';
  BUF_SIZE = 8192;


procedure LogIt(what: String);
begin
  IOResult; // Because if error in copying here always raised exception
            //take off error flag
  if log_access then
  try
    Writeln(log,what);
  except
    MessageBox(0,'Ошибка записи в лог!','BackUper 1.0',MB_ICONSTOP);
    log_access:=false;
  end;
end;

function CopyFile(from: String; tof: String): Boolean;
var
   Vf1, Vf2 : file;
   NRead, NWrite: Integer;
   Buf: array[1..BUF_SIZE] of Char;
begin
  {$I-}
  AssignFile(Vf1, from);
  AssignFile(Vf2, tof);

  Reset(Vf1, 1);
  Rewrite(Vf2, 1);


  if IOResult <> 0 then
  begin
    Result:=false;
    CloseFile(Vf1);
    CloseFile(Vf2);
    Exit;
  end;

  repeat
    BlockRead(Vf1, Buf, SizeOf(Buf), NRead);    {читает данные}
    BlockWrite(Vf2, Buf, NRead, NWrite);    {записывает данные}
  until (NRead = 0) or (NWrite <> NRead);

  CloseFile(Vf1);
  CloseFile(Vf2);

  if IOResult = 0 then
     Result:=true else
     Result:=false;

  {$I+}
end;

procedure FindRecursive(path: String; const mask: String);

    function Recurse(var path: String; const mask: String): Boolean;
    var
      SRec: TSearchRec;
      retval: Integer;
      oldlen: Integer;
      tmp: String;
    begin
      Recurse := True;
      oldlen := Length(path);
      retval := FindFirst( path+mask, faanyfile, SRec );
      while retval = 0 do
      begin
        if (SRec.Attr and (faDirectory or faVolumeID)) = 0 then
        begin
          tmp:=Path+Srec.Name;
          if FileExists(tmp) then
             FileList.Add(tmp);
        end;
        retval := FindNext(SRec);
      end;
      FindClose(SRec);
      if not Result then Exit;
      retval := FindFirst(path+MASK, faDirectory, SRec);
      while retval = 0 do
      begin
        if (SRec.Attr and faDirectory) <> 0 then
          if (SRec.Name <> '.') and (SRec.Name <> '..') then
          begin
            path := path + SRec.Name + '\';

            DirList.Add(path);

            if not Recurse(path, mask) then
            begin
              Result := False;
              Break;
            end;
            Delete(path, oldlen+1, 255);
          end;
        retval := FindNext(SRec);
      end;
      FindClose(SRec);
    end; { Recurse }
begin
  count:=0;
  Recurse(path, mask);
end;

procedure HaltBackuper;
begin
  LogIt('');
  DirList.Free;
  FileList.Free;
  Flush(log);
  CloseFile(log);
end;


var
   Path, Dest, tmp: String;
   i: Integer;
begin
  try

    try
      AssignFile(log, LOG_NAME);
      if FileExists(LOG_NAME) then Append(log)
           else Rewrite(log);

    except
      MessageBox(0,'Ошибка доступа к '+LOG_NAME,'BackUper 1.0',MB_ICONSTOP);
      log_access:=false;
    end;

    LogIt('***  New session '+TimeToStr(Time)+' '+DateToStr(Date));

    Path:=ParamStr(1);


    Path:=ExcludeTrailingBackslash(Path);
    if Path <> '' then
    begin
      if DirectoryExists(Path) then Path:=Path+'\'
      else begin
        LogIt('Укажите правильную папку откуда копировать!');
        HaltBackuper;
      end;
    end else
      Path := ExtractFileDir(ParamStr(0))+'\';


    Dest:=ParamStr(2);
    Dest:=ExcludeTrailingBackslash(Dest);
    if Dest <> '' then Dest:=Dest+'\' else Dest:=Path+'Backup\';
    LogIt('Копирование в директорию '+Dest);

    if not DirectoryExists(Dest) then
    if not CreateDir(Dest) then
    begin
      LogIt('Невозможно создать папку '+Dest+#13#10'для копирования');
      HaltBackuper;
    end;

    FileList := TStringList.Create;
    DirList := TStringList.Create;

    FindRecursive(Path,MASK);      //Заполняет список копируемых файлов
                                   // и директорий
    for i:=0 to DirList.Count-1 do
    if Dest <> DirList.Strings[i] then
    begin
      tmp:=DirList.Strings[i];

      Delete(tmp,1,Length(Path));
      tmp:=Dest+tmp;
      if not DirectoryExists(tmp) then
         ForceDirectories(tmp);
    end;

    for i:=0 to FileList.Count-1 do
    if Dest <> Copy(FileList.Strings[i],1,Length(Dest)) then
    begin
      tmp:=FileList.Strings[i];

      Delete(tmp,1,Length(Path));
      tmp:=Dest+tmp;

      if not CopyFile(FileList.Strings[i],tmp) then
        LogIt(FileList.Strings[i]+' NOT copied')
      else
      begin
        Inc(count);
        LogIt(FileList.Strings[i]+' succesful copied')
      end;
    end;

    LogIt(IntToStr(count)+' файлов скопировано'#13#10);
    DirList.Free;
    FileList.Free;
    Flush(log);
    CloseFile(log);

  except
    MessageBox(0,'Fatal error!','Backuper 1.0',MB_ICONSTOP);
  end;
end.


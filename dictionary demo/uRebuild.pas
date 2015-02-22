unit uRebuild;

interface

uses
  BPlusTree,
  BPlusTree.Intf;

procedure RebuildDatabase(const DbPath, DefsPath: string; KeysOnly: boolean; Max: uint32);

implementation

uses
  System.Generics.Collections,
  System.SysUtils,
  uConsts;

type
  TDefinition = record
    Meaning: RawByteString;
    Words: array of RawByteString;
  end;

  TDefinitions = TList<TDefinition>;

procedure ReadDefinitions(const DefsPath: string; var Defs: TDefinitions);
var
  s: RawByteString;
  f: TextFile;
  def: TDefinition;
begin
  AssignFile(f, DefsPath);
  Reset(f);
  try

    Defs.Clear;

    while not Eof(f) do
    begin
      readln(f, s);
      if s = '' then
        continue;
      if s[1] = ';' then
        continue;

      def.Meaning := '';
      def.Words := nil;

      // "s" is "id" now
      // read meaning
      readln(f, def.Meaning);
      // read words
      readln(f, s);
      while s <> '' do
      begin
        setlength(def.Words, length(def.Words) + 1);
        def.Words[high(def.Words)] := s;
        readln(f, s);
      end;

      Defs.Add(def);

{$IFDEF LIMIT}
      if Defs.Count = 100 then
        break;
{$ENDIF}
    end;
  finally
    CloseFile(f);
  end;
end;

procedure InsertPair(const db: IBPlusTree; const key, val: RawByteString); inline;
begin
  db.PutRaw(@key[1], length(key), @val[1], length(val));
end;

procedure InsertKey(const db: IBPlusTree; const key: RawByteString); inline;
begin
  db.PutRaw(@key[1], length(key), nil, 0);
end;

// Max: 0 - unlimited.
procedure BuildDatabase(const DbPath: string; Defs: TDefinitions;
  KeysOnly: boolean; Max: uint32);
var
  db: IBPlusTree;
  def: TDefinition;
  key: AnsiString;
  cnt: uint32;
begin
  cnt := 0;

  db := TBPlusTree.Create;

  if IsConsole then
    Writeln('BuildDatabase begin');

  db.CreateNew(DbPath, MAX_KEY_SIZE, PAGE_SIZE, CACHE_SIZE);
  for def in Defs do
  begin
    for key in def.Words do
    begin
      if not KeysOnly then
        InsertPair(db, key, def.Meaning)
      else
        InsertKey(db, key);
      inc(cnt);
      if cnt = Max then
        break;
    end;
    if cnt = Max then
      break;
  end;

{$IFDEF OLD_BT}
  if IsConsole then
  begin
    Writeln(format('Page Flush Count: %d', [db.Storage.Stats.PageFlushCount]));
    Writeln(format('Page Seek Count: %d', [db.Storage.Stats.PageSeekCount]));
    Writeln('BuildDatabase end');
  end;
{$ENDIF OLD_BT}

end;

procedure RebuildDatabase(const DbPath, DefsPath: string; KeysOnly: boolean;
  Max: uint32);
var
  Defs: TDefinitions;
begin
  Defs := TDefinitions.Create;
  try
    ReadDefinitions(DefsPath, Defs);
    BuildDatabase(DbPath, Defs, KeysOnly, Max);
  finally
    Defs.Free;
  end;
end;

end.

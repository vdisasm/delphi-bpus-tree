unit Unit1;

interface

uses
  System.Classes,
  System.Diagnostics,
  System.SysUtils,
  System.Variants,

  Winapi.Messages,
  Winapi.Windows,

  Vcl.Controls,
  Vcl.Dialogs,
  Vcl.Forms,
  Vcl.Graphics,
  Vcl.ImgList,
  Vcl.Menus,
  Vcl.StdCtrls,

  BPlusTree;

type
  TForm1 = class(TForm)
    edKey: TEdit;
    memoValue: TMemo;
    btFind: TButton;
    btFirst: TButton;
    btLast: TButton;
    btNext: TButton;
    btPrev: TButton;
    btNextPage: TButton;
    btPrevPage: TButton;
    btRebuild: TButton;
    ImageList1: TImageList;
    MainMenu1: TMainMenu;
    Tools1: TMenuItem;
    VerifyLeafLinks1: TMenuItem;
    N1: TMenuItem;
    RebuildDB1: TMenuItem;
    lbPrefixed: TListBox;
    Label1: TLabel;
    Label2: TLabel;
    VerifyParentChild1: TMenuItem;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btFindClick(Sender: TObject);
    procedure edKeyKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure btNextClick(Sender: TObject);
    procedure btPrevClick(Sender: TObject);
    procedure btFirstClick(Sender: TObject);
    procedure btLastClick(Sender: TObject);
    procedure btNextPageClick(Sender: TObject);
    procedure btPrevPageClick(Sender: TObject);
    procedure btRebuildClick(Sender: TObject);
    procedure VerifyLeafLinks1Click(Sender: TObject);
    procedure RebuildDB1Click(Sender: TObject);
    procedure VerifyParentChild1Click(Sender: TObject);
    procedure lbPrefixedClick(Sender: TObject);
  private
    procedure DisplayRangeKeys;
    procedure DisplayBtCursor;
    procedure OpenDB;
    procedure CloseDB;
    procedure EnableButtons(State: boolean);
  public
    procedure FindKey(ADisplayRangeKeys: boolean);
  end;

var
  Form1: TForm1;

implementation

uses
  uConsts,
  uRebuild,
  BPlusTree.Intf;

{$R *.dfm}


const
  dic_path  = 'dic.db';
  defs_path = 'definitions.txt';

var
  gTree: IBPlusTree;
  gCursor: IBPlusTreeCursor;

procedure DestroyTree;
begin
  gCursor := nil;
  gTree := nil;
end;

// string to bytes
function s2b(const s: string): TBytes; inline;
begin
  result := TEncoding.ANSI.GetBytes(s);
end;

// bytes to string
function b2s(const b: TBytes): string; inline;
begin
  result := TEncoding.ANSI.GetString(b);
end;

function set_btCursor(const aCursor: IBPlusTreeCursor): boolean;
begin
  result := aCursor <> nil;
  if result then
  begin
    // btCursor := nil;
    gCursor := aCursor;
  end;
end;

procedure TForm1.btFirstClick(Sender: TObject);
begin
  if Assigned(gTree) then
    if set_btCursor(gTree.CursorCreateFirst) then
      DisplayBtCursor;
end;

procedure TForm1.btFindClick(Sender: TObject);
begin
  FindKey(True);
end;

procedure TForm1.btLastClick(Sender: TObject);
begin
  if Assigned(gTree) then
    if set_btCursor(gTree.CursorCreateLast) then
      DisplayBtCursor;
end;

procedure TForm1.btNextClick(Sender: TObject);
begin
  if Assigned(gCursor) then
    if gCursor.Next then
      DisplayBtCursor;
end;

procedure TForm1.btNextPageClick(Sender: TObject);
begin
  if Assigned(gCursor) and gCursor.NextPage then
    DisplayBtCursor;
end;

procedure TForm1.btPrevClick(Sender: TObject);
begin
  if Assigned(gCursor) then
    if gCursor.Prev then
      DisplayBtCursor;
end;

procedure TForm1.btPrevPageClick(Sender: TObject);
begin
  if Assigned(gCursor) and gCursor.PrevPage then
    DisplayBtCursor;
end;

procedure TForm1.btRebuildClick(Sender: TObject);
const
  // IS_KEYS_ONLY = True;
  // MAX_KEYS     = 20000;
  MAX_KEYS     = 0;
  IS_KEYS_ONLY = False;
var
  sw: TStopwatch;
begin
  CloseDB;
  btRebuild.Enabled := False;
  try
    sw := TStopwatch.StartNew;
    RebuildDatabase(dic_path, defs_path, IS_KEYS_ONLY, MAX_KEYS);
    sw.Stop;

    OpenDB;
    EnableButtons(True);

    ShowMessageFmt(
      'DB rebuilt in %s'#13#10 +
      '%d keys'#13#10,
      [string(sw.Elapsed), gTree.KeyCount]);
  finally
    btRebuild.Enabled := True;
  end;
end;

procedure TForm1.CloseDB;
begin
  DestroyTree;
end;

procedure TForm1.DisplayBtCursor;
begin
  if gCursor <> nil then
  begin
    edKey.Text := b2s(gCursor.Key);
    memoValue.Text := b2s(gCursor.value);
  end
  else
  begin
    edKey.Clear;
    memoValue.Clear;
  end;
end;

procedure TForm1.DisplayRangeKeys;
var
  cur: IBPlusTreeCursor;
begin
  lbPrefixed.Clear;
  lbPrefixed.Items.BeginUpdate;
  try
    cur := gTree.CursorCreateEx(s2b(edKey.Text), [kpEqual, kpGreater], True);
    if cur <> nil then
      repeat
        lbPrefixed.Items.Add(b2s(cur.Key));
      until not cur.Next;
    cur := nil;
  finally
    lbPrefixed.Items.EndUpdate;
  end;
end;

procedure TForm1.edKeyKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  case Key of
    VK_RETURN:
      btFindClick(nil);
  end;
end;

procedure TForm1.EnableButtons(State: boolean);
begin
  btFind.Enabled := State;
  btFirst.Enabled := State;
  btLast.Enabled := State;
  btPrev.Enabled := State;
  btNext.Enabled := State;
  btPrevPage.Enabled := State;
  btNextPage.Enabled := State;
end;

procedure TForm1.FindKey(ADisplayRangeKeys: boolean);
var
  Key: TBytes;
begin
  if gTree <> nil then
  begin
    gCursor := nil;

    memoValue.Clear;
    if edKey.Text <> '' then
    begin
      Key := s2b(edKey.Text);
      if set_btCursor(gTree.CursorCreate(Key)) then
        DisplayBtCursor;
      if ADisplayRangeKeys then
        DisplayRangeKeys;
    end;
  end;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
{$IFDEF XDEBUG}
  Tools1.Visible := True;
{$ELSE}
  Tools1.Visible := False;
{$ENDIF}
  OpenDB;
  btFirstClick(nil);
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  CloseDB;
end;

procedure TForm1.lbPrefixedClick(Sender: TObject);
begin
  if lbPrefixed.ItemIndex <> -1 then
  begin
    edKey.Text := lbPrefixed.Items[lbPrefixed.ItemIndex];
    FindKey(False);
  end;
end;

procedure TForm1.OpenDB;
var
  Status: TBPlusTreeStatus;
begin
  CloseDB;

  gTree := TBPlusTree.Create;

  Status := gTree.OpenExisting(dic_path, CACHE_SIZE, True);

  if Status <> BP_OK then
  begin
    memoValue.Text := 'Failed to open database. Check if it exists or Rebuild.';
    DestroyTree;
    EnableButtons(False);
  end;
end;

procedure TForm1.RebuildDB1Click(Sender: TObject);
begin
  btRebuildClick(nil);
end;

procedure TForm1.VerifyLeafLinks1Click(Sender: TObject);
{$IFDEF XDEBUG}
var
  cnt: uint32;
{$ENDIF}
begin
{$IFDEF XDEBUG}
  if Assigned(bt) then
    if bt.VerifyLeafPageLinks(cnt) then
      ShowMessageFmt('Leaf page links are OK (%d)', [cnt])
    else
      ShowMessageFmt('Leaf page links are BAD (%d)', [cnt]);
{$ENDIF}
end;

procedure TForm1.VerifyParentChild1Click(Sender: TObject);
begin
{$IFDEF XDEBUG}
  if Assigned(bt) then
    if bt.VerifyIndexParentChild() then
      ShowMessage('Parent-child are OK')
    else
      ShowMessage('Parent-child are BAD');
{$ENDIF}
end;

end.

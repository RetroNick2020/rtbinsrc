unit rtbinsrcfm;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  LazFileUtils, Types, SpinEx,rtcodegen;

Const
  ProgramName = 'RtBinSrc v1.3 By RetroNick - Released May 22 - 2023';

type

  { TForm1 }

  TForm1 = class(TForm)
    ArrayLabel: TLabel;
    ItemsPerLineLabel: TLabel;
    ClearOnImport: TCheckBox;
    EditArrayName: TEdit;
    LineStartLabel: TLabel;
    LineStepsLabel: TLabel;
    ItemsPerLineSpinEdit: TSpinEditEx;
    LineStartSpinEdit: TSpinEditEx;
    LineStepsSpinEdit: TSpinEditEx;
    IndentSizeLabel: TLabel;
    OpenDialog: TOpenDialog;
    SaveAs: TButton;
    CopyToClipboard: TButton;
    Import: TButton;
    EditFileName: TEdit;
    InFile: TButton;
    InfoLabel: TLabel;
    MemoWithCode: TMemo;
    LanRadioGroup: TRadioGroup;
    NumTypeRadioGroup: TRadioGroup;
    FormatRadioGroup: TRadioGroup;
    SaveDialog: TSaveDialog;
    IndentSpinEdit: TSpinEditEx;
    procedure CopyToClipboardClick(Sender: TObject);
    procedure FormatRadioGroupClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDropFiles(Sender: TObject; const FileNames: array of String);
    procedure ImportClick(Sender: TObject);
    procedure InFileClick(Sender: TObject);
    procedure InFileDragDrop(Sender, Source: TObject; X, Y: Integer);
    procedure LanRadioGroupClick(Sender: TObject);
    procedure NumTypeRadioGroupClick(Sender: TObject);
    procedure SaveAsClick(Sender: TObject);
  private
   CG : CodeGenRec;
   Lan : integer;
   Format : integer;
   NumType : integer;
   Processing : boolean;

   procedure SetBasicTypes;
   procedure SetGWBasicTypes;
   procedure SetPascalTypes;
   procedure SetCTypes;

  public

  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}

{ TForm1 }



procedure TForm1.NumTypeRadioGroupClick(Sender: TObject);
begin
  case Lan of BasicLan:begin
                         case NumTypeRadioGroup.ItemIndex of 0:NumType:=basic_byte;
                                                             1:NumType:=basic_integer;
                                                             2:NumType:=basic_long;
                         end;
                       end;
              GWBasicLan:begin
                           case NumTypeRadioGroup.ItemIndex of 0:NumType:=basic_byte;
                                                               1:NumType:=basic_integer;
                                                               2:NumType:=basic_long;
                           end;
                          end;
                  CLan:begin
                             case NumTypeRadioGroup.ItemIndex of 0:NumType:=c_char_signed;
                                                                 1:NumType:=c_char_unsigned;
                                                                 2:NumType:=c_int_signed;
                                                                 3:NumType:=c_int_unsigned;
                                                                 4:NumType:=c_long_signed;
                                                                 5:NumType:=c_long_unsigned;
                             end;

                       end;
             PascalLan:begin
                        case NumTypeRadioGroup.ItemIndex of 0:NumType:=pascal_byte;
                                                            1:NumType:=pascal_integer;
                                                            2:NumType:=pascal_word;
                                                            3:NumType:=pascal_longint;
                                                            4:NumType:=pascal_longword;
                        end;

                       end;
  end;
end;

procedure TForm1.SaveAsClick(Sender: TObject);
begin
  if SaveDialog.Execute then
  begin
    MemoWithCode.Lines.SaveToFile(SaveDialog.FileName);
    InfoLabel.Caption:=EditArrayName.Text+' saved to file';
  end;
end;

//when CGWriteLn is executed it calls this procedure to insert the mc.linebustr contents to the memo
procedure FMemoAppend(msg : string);
begin
  Form1.MemoWithCode.Append(msg);
  if (Form1.CG.LineCount Mod 50) = 0 then
  begin
    Form1.InfoLabel.Caption:='Imported '+IntToStr(Form1.CG.LineCount)+' Lines';
    Application.ProcessMessages;
  end;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  Caption:=ProgramName;
  Processing:=False;
  SetBasicTypes;
  CGInit(CG);
  CGSetLineNumber(CG,LineStartSpinEdit.Value,LineStepsSpinEdit.Value);
  CGSetMemoProc(@FMemoAppend);
end;

procedure TForm1.FormDropFiles(Sender: TObject; const FileNames: array of String
  );
var
  MousePoint: TPoint;
begin
  if High(Filenames) > 0 then
  begin
    ShowMessage('Drag only one file!');
    exit;
  end;

  if FileExists(FileNames[0]) then
  begin
    OpenDialog.FileName:=FileNames[0];
    EditFileName.Caption:=FileNames[0];
    EditArrayName.Text:=LowerCase(ExtractFileName(ExtractFileNameWithoutExt(FileNames[0])));
    Import.Enabled:=True;
  end
  else
  begin
    ShowMessage('Invalid File/Directory!');
    exit;
  end;

  MousePoint := ScreenToClient(Mouse.CursorPos);
  if NOT (PtInRect(InFile.BoundsRect, MousePoint) or PtInRect(EditFilename.BoundsRect, MousePoint)) then ImportClick(Self);
end;

procedure TForm1.ImportClick(Sender: TObject);
var
  error : word;
begin
  if Processing then
  begin
     //ShowMessage('Processing Previous Import');
     //InfoLabel.Caption:='Import Canceled';
     Import.Caption:='Import';  //rename cancel back to import
     CGSetImportStatus(CG,FALSE);
     Processing:=FALSE;
     exit;
  end;

  if EditArrayName.Text='' then
  begin
    ShowMessage('Array Name Field Cannot be blank');
    exit;
  end;

  Import.Caption:='Cancel';    //rename import button to cancel
  Processing:=True;
  CGReset(CG);
  //CGSetImportStatus(CG,TRUE);
  CGSetIndent(CG,indentSpinedit.Value);
  CGSetValuesPerLine(CG,ItemsPerLineSpinEdit.Value);
  InfoLabel.Caption:='';
  if ClearOnImport.Checked then
  begin
     MemoWithCode.Clear;
     CGSetLineNumber(CG,LineStartSpinEdit.Value,LineStepsSpinEdit.Value);
  end;

  error:=ImportBinFile(CG,OpenDialog.FileName, EditArrayName.Text,Lan, NumType,Format);
  if error<>0 then
  begin
    ShowMessage('Error Importing File ');
  end
  else
  begin
    if CG.ImportStatus then InfoLabel.Caption:='File Imported Successfully' else InfoLabel.Caption:='File Import Canceled';
  end;
  Processing:=False;
  Import.Caption:='Import';  //rename cancel back to import
end;

procedure TForm1.InFileClick(Sender: TObject);
begin
  if Processing then exit;

  // OpenDialog.Filter := 'Windows BMP|*.bmp|PNG|*.png|PC Paintbrush |*.pcx|DP-Amiga IFF LBM|*.lbm|DP-Amiga IFF BBM Brush|*.bbm|GIF|*.gif|RM RAW Files|*.raw|All Files|*.*';
  if OpenDialog.Execute then
  begin
    EditFileName.Text:=OpenDialog.FileName;
    EditFileName.Enabled:=false;
    EditArrayName.Text:=LowerCase(ExtractFileName(ExtractFileNameWithoutExt(OpenDialog.FileName)));
    Import.Enabled:=true;
  end;
end;

procedure TForm1.InFileDragDrop(Sender, Source: TObject; X, Y: Integer);
begin

end;



procedure TForm1.LanRadioGroupClick(Sender: TObject);
begin
  if Processing then exit;
  case LanRadioGroup.ItemIndex of 0:SetBasicTypes;
                                  1:SetGWBasicTypes;
                                  2:SetCTypes;
                                  3:SetPascalTypes;
  end;
end;

procedure TForm1.CopyToClipboardClick(Sender: TObject);
begin
  if Processing then exit;
  MemoWithCode.SelectAll;
  MemoWithCode.CopyToClipboard;
  MemoWithCode.SelLength:=0;
  InfoLabel.Caption:='Code Copied to Clipboard';
end;

procedure TForm1.FormatRadioGroupClick(Sender: TObject);
begin
  case FormatRadioGroup.ItemIndex of 0:Format:=ValueFormatDecimal;
                                     1:Format:=ValueFormatHex;
  end;
end;

procedure TForm1.SetBasicTypes;
begin
  Lan:=BasicLan;
  NumTypeRadioGroup.Items.Clear;
  NumTypeRadioGroup.Items.Add('BYTE');
  NumTypeRadioGroup.Items.Add('INTEGER');
  NumTypeRadioGroup.Items.Add('LONG');
  NumTypeRadioGroup.ItemIndex:=0;
  IndentSpinEdit.Enabled:=false;
  LineStartSpinEdit.Enabled:=false;
  LineStepsSpinEdit.Enabled:=false;
end;

procedure TForm1.SetGWBasicTypes;
begin
  Lan:=GWBasicLan;
  NumTypeRadioGroup.Items.Clear;
  NumTypeRadioGroup.Items.Add('BYTE');
  NumTypeRadioGroup.Items.Add('INTEGER');
  NumTypeRadioGroup.Items.Add('LONG');
  NumTypeRadioGroup.ItemIndex:=0;
  IndentSpinEdit.Enabled:=false;
  LineStartSpinEdit.Enabled:=true;
  LineStepsSpinEdit.Enabled:=true;
end;

procedure TForm1.SetPascalTypes;
begin
  Lan:=PascalLan;
  NumTypeRadioGroup.Items.Clear;
  NumTypeRadioGroup.Items.Add('Byte');
  NumTypeRadioGroup.Items.Add('Integer');
  NumTypeRadioGroup.Items.Add('Word');
  NumTypeRadioGroup.Items.Add('Longint');
  NumTypeRadioGroup.Items.Add('Longword');
  NumTypeRadioGroup.ItemIndex:=0;
  IndentSpinEdit.Enabled:=true;
  LineStartSpinEdit.Enabled:=false;
  LineStepsSpinEdit.Enabled:=false;
end;

procedure TForm1.SetCTypes;
begin
  Lan:=CLan;
  NumTypeRadioGroup.Items.Clear;
  NumTypeRadioGroup.Items.Add('char');
  NumTypeRadioGroup.Items.Add('unsigned char');
  NumTypeRadioGroup.Items.Add('int');
  NumTypeRadioGroup.Items.Add('unsigned int');
  NumTypeRadioGroup.Items.Add('long');
  NumTypeRadioGroup.Items.Add('unsigned long');
  NumTypeRadioGroup.ItemIndex:=0;
  IndentSpinEdit.Enabled:=true;
  LineStartSpinEdit.Enabled:=false;
  LineStepsSpinEdit.Enabled:=false;
end;


end.


unit uMain;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes,
  System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.StdCtrls,
  FMX.Colors, FMX.Media, IdBaseComponent, IdComponent, IdTCPConnection,
  IdTCPClient, IdHTTP, FMX.Objects, FMX.ListView.Types, FMX.ListView,
  FMX.Layouts, FMX.ListBox, IPPeerClient, REST.Client, Data.Bind.Components,
  Data.Bind.ObjectScope, REST.Types, IdMultipartFormData, FMX.Memo;

type
  TMainForm = class(TForm)
    OpenFile: TSpeedButton;
    OpenList: TSpeedButton;
    StyleBook1: TStyleBook;
    ImageBook: TStyleBook;
    ListBox1: TListBox;
    MainLayout: TLayout;
    TopLayout: TLayout;
    BackBtn: TSpeedButton;
    UploadBtn: TSpeedButton;
    RESTClient: TRESTClient;
    RESTRequest: TRESTRequest;
    RESTResponse: TRESTResponse;
    Memo1: TMemo;
    procedure AddListItem(list: array of string; itype: string);
    procedure OpenFileClick(Sender: TObject);
    procedure ListBox1ItemClick(const Sender: TCustomListBox;
      const Item: TListBoxItem);
    procedure BackBtnClick(Sender: TObject);
    procedure UploadBtnClick(Sender: TObject);
    procedure RESTRequestAfterExecute(Sender: TCustomRESTRequest);

  private
    { Private declarations }
    procedure OpenDictory(path_tr: String);
    function GetImage(const AImageName: string): TBitmap;
    function GetMIMEType(FileExt: string): string;
  public
    { Public declarations }
    clear: Boolean;
    path: String;
    historyPath: TStringList;
  end;

var
  MainForm: TMainForm;

implementation

{$R *.fmx}

{ TForm1 }
uses
  System.IOUtils, System.Generics.Collections,
  FMX.Helpers.Android, Androidapi.JNI.JavaTypes, Androidapi.Helpers,
  Androidapi.JNI.GraphicsContentViewText, Androidapi.JNI.Webkit,
  Generics.Defaults;

function CompareLowerStr(const Left, Right: string): Integer;
begin
  Result := CompareStr(AnsiLowerCase(Left), AnsiLowerCase(Right));
end;

procedure TMainForm.BackBtnClick(Sender: TObject);
begin
  if TDirectory.Exists(historyPath[historyPath.Count - 1]) then
  begin
    path := historyPath[historyPath.Count - 1];
    historyPath.Delete(historyPath.Count - 1);
    OpenDictory(path);
  end;
end;

function TMainForm.GetImage(const AImageName: string): TBitmap;
var
  StyleObject: TFmxObject;
  Image: TImage;
begin
  StyleObject := ImageBook.Style.FindStyleResource(AImageName);
  if (StyleObject <> nil) and (StyleObject is TImage) then
  begin
    Image := StyleObject as TImage;
    Result := Image.Bitmap;
  end
  else
    Result := nil;
end;

function TMainForm.GetMIMEType(FileExt: string): string;
var
  I: Integer;
  S: array [0 .. 255] of Char;
const
  MIMEStart = 101;
  // ID of first MIME Type string (IDs are set in the .rc file
  // before compiling with brcc32)
  MIMEEnd = 742; // ID of last MIME Type string
begin
  Result := 'text/plain';

  // If the file extenstion is not found then the result is plain text
  for I := MIMEStart to MIMEEnd do
  begin

  //  LoadString(hInstance, I, @S, 255);

    // Loads a string from mimetypes.res which is embedded into the
    // compiled exe
    if Copy(S, 1, Length(FileExt)) = FileExt then
    // "If the string that was loaded contains FileExt then"
    begin
      Result := Copy(S, Length(FileExt) + 2, 255);
      // Copies the MIME Type from the string that was loaded
      Break;
      // Breaks the for loop so that it won't go through every
      // MIME Type after it found the correct one.
    end;

end;
end;

procedure TMainForm.ListBox1ItemClick(const Sender: TCustomListBox;
  const Item: TListBoxItem);
var
  FileName, ExtFile: string;
  mime: JMimeTypeMap;
  ExtToMime: JString;
  Intent: JIntent;
begin
  if Item.TagString = 'folder' then
  begin
    historyPath.Add(path);
    path := Item.ItemData.Detail;

    if TDirectory.Exists(path) then
    begin
      OpenDictory(path);
    end
    else
    begin
      ListBox1.Items.Delete(Item.Index);
      ShowMessage('삭제 하시겠습니까?');
    end;
  end
  else if Item.TagString = 'file' then
  begin

    FileName := Item.ItemData.Detail;

    try

      ExtFile := AnsiLowerCase(StringReplace(TPath.GetExtension(FileName),
        '.', '', []));
      mime := TJMimeTypeMap.JavaClass.getSingleton();
      ExtToMime := mime.getMimeTypeFromExtension(StringToJString(ExtFile));

      Intent := TJIntent.Create;
      Intent.setAction(TJIntent.JavaClass.ACTION_VIEW);
      Intent.setDataAndType(StrToJURI('file:' + FileName), ExtToMime);
      SharedActivity.startActivity(Intent);
    except
      ShowMessage('파일을 공유 !');
    end;
  end;
end;

procedure TMainForm.OpenDictory(path_tr: String);
var
  folders, files: TStringDynArray;
begin
  folders := TDirectory.GetDirectories(path_tr);

  TArray.Sort<String>(folders, TComparer<String>.Construct(CompareLowerStr));

  if clear then
  begin
    ListBox1.clear;
  end;

  AddListItem(folders, 'folder');

  files := TDirectory.GetFiles(path_tr);

  TArray.Sort<String>(files, TComparer<String>.Construct(CompareLowerStr));
  AddListItem(files, 'file');

end;

procedure TMainForm.OpenFileClick(Sender: TObject);
begin
  clear := True;
  historyPath := nil;
  historyPath := TStringList.Create;
  path := '/storage/emulated/0/';
  OpenDictory(path);

end;

procedure TMainForm.RESTRequestAfterExecute(Sender: TCustomRESTRequest);
begin
  Memo1.Text := Sender.Response.JSONValue.ToString;
end;

procedure TMainForm.UploadBtnClick(Sender: TObject);
var
  LFileName: string;
  LFileStream: TFileStream;
  LStream: TStream;
  LFile: TFile;
  mime: JMimeTypeMap;
  ExtToMime: JString;
  ExtFile:string;
  LMultPartStream: TIdMultipartFormDataStream;
  Result: string;
begin
  RESTRequest.Method := TRESTRequestMethod.rmPOST;
  try
    LMultPartStream := TIdMultipartFormDataStream.Create;

    if ListBox1.Selected <> nil then
    begin
      LFileName := ListBox1.Selected.ItemData.Detail;
      ExtFile := AnsiLowerCase(StringReplace(TPath.GetExtension(LFileName),
        '.', '', []));
      mime := TJMimeTypeMap.JavaClass.getSingleton();
      ExtToMime := mime.getMimeTypeFromExtension(StringToJString(ExtFile));

      LMultPartStream.AddFormField('title', LFileName);
      if not TFile.Exists(LFileName) then
        exit();

      with LMultPartStream.AddFile('uploadImage', LFileName,
        JStringToString( ExtToMime)) do
      begin
        HeaderCharSet := 'utf-8';
        HeaderEncoding := '8';
      end;
      LMultPartStream.Position := 0;

      RESTRequest.Client.HTTPClient.Request.ContentType :=
        LMultPartStream.RequestContentType;
      RESTRequest.Client.HTTPClient.Post(RESTClient.BaseURL +
        '/images/uploadfile', LMultPartStream);

    end;
  finally
    LMultPartStream.Free;
  end;
end;

procedure TMainForm.AddListItem(list: array of string; itype: string);
var
  c: Integer;
  LItem: TListBoxItem;
  BitmapFolder, BitmapFile: TBitmap;
begin

  BitmapFolder := GetImage('folder');
  BitmapFile := GetImage('file');

  ListBox1.BeginUpdate;

  for c := 0 to Length(list) - 1 do
  begin

    LItem := TListBoxItem.Create(ListBox1);

    if itype = 'folder' then
    begin
      if BitmapFolder <> nil then
      begin
        LItem.ItemData.Bitmap.Assign(BitmapFolder);
      end;
    end
    else
    begin
      if BitmapFile <> nil then
      begin
        LItem.ItemData.Bitmap.Assign(BitmapFile);
      end;
    end;

    LItem.ItemData.Text := ExtractFileName(list[c]);
    LItem.ItemData.Detail := list[c];
    LItem.TagString := itype;
    ListBox1.AddObject(LItem);

  end;

  ListBox1.EndUpdate;

end;

end.

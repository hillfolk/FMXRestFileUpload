unit uImagePopup;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.StdCtrls,
  FMX.Objects, FMX.Layouts;

type
  TForm2 = class(TForm)
    Layout1: TLayout;
    TopLayout: TLayout;
    Image: TImage;
    BackBtn: TSpeedButton;
    SendBtn: TSpeedButton;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form2: TForm2;

implementation

{$R *.fmx}

end.

unit gui;

{$mode objfpc}{$H+}

interface

uses
  Classes,SysUtils,FileUtil,Forms,Controls,Graphics,Dialogs,ComCtrls,
  StdCtrls,ExtCtrls,ustringtools,math,Menus,strutils,Graph,ubackprop;
type

  { TForm1 }

  TForm1 = class(TForm)
    BtnTrainingFile: TButton;
    BtnClose: TButton;
    BtnStart: TButton;
    CBLernrateReduzieren: TCheckBox;
    CBMinVersuche: TCheckBox;
    CBMaxVersuche: TCheckBox;
    CBLernrateEnde: TCheckBox;
    CBearlyBreak: TCheckBox;
    CBgrafisch: TCheckBox;
    CBtext: TCheckBox;
    EDLearnrateRefreshRate: TEdit;
    EDMinLoops: TEdit;
    EDLearnrateEnde: TEdit;
    EDLearnrateStart: TEdit;
    EDMaxLoops: TEdit;
    EDTargetError: TEdit;
    Image1: TImage;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Memo1: TMemo;
    Memo2: TMemo;
    Memo3: TMemo;
    OpenDialogLearn: TOpenDialog;
    PageControl1: TPageControl;
    Panel1: TPanel;
    Panel2: TPanel;
    CBausgabeEinschalten: TRadioButton;
    RBausgabeAusschalten: TRadioButton;
    RadioGroup1: TRadioGroup;
    SaveDialog1: TSaveDialog;
    StatusBar1: TStatusBar;
    TabSheet1: TTabSheet;
    TabSheet2: TTabSheet;
    procedure BtnTrainingFileClick;
    procedure BtnStartClick;
    procedure BtnCloseClick;
  private
    procedure Lernen;
    function fTest:boolean;

    procedure show(refreshRate,n:longint); //aktualisier alle refreshRate Durchläufe die Anzeigen
    function scale(what,fromLow,fromHigh,toLow,toHigh:extended):extended;
    function calcColor(what,fromLow,fromHigh,toLow,toHigh:extended):tColor;
    procedure showGrafikal;

    { private declarations }
  public
    { public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}


var
  aufgaben,loesungen,ergebnis      : array of array of extended;
  slots: array of string;
  refreshRate : longint;
  point   : array of array of tPoint;

procedure TForm1.BtnTrainingFileClick;
var
  f            : textfile;
  fileValue,s,
  aufgabe,
  loesung      : string;
  i,j          : longint;
begin
  if OpenDialogLearn.Execute then
  begin
    AssignFile(f,OpenDialogLearn.FileName);
    reset(f);
    readln(f,fileValue);

    layerCount     := extractIntFromText(fileValue);
    inputLayer     := 0;
    outputLayer    := layerCount - 1;

    setlength(layerSizes,layerCount);
    for i := 0 to layerCount-1 do
    begin
      readln(f,fileValue);
      layerSizes[i] := extractIntFromText(fileValue);
    end;
    setlength(point,layercount);
    for i := 0 to layercount -1 do
      setlength(point[i],layerSizes[i]);

    Init;

    i := 0;
    while not eof(f) do
    begin
      readln(f,fileValue);
      slots := StringSplit(fileValue,'|');
      aufgabe := slots[0];
      loesung := slots[1];

      slots := StringSplit(aufgabe, ',');
      setLength(aufgaben,i+1);
      setLength(loesungen,i+1);
      setLength(ergebnis,i+1);
      setLength(aufgaben[i],layerSizes[inputLayer]);
      for j := 0 to high(neuron[inputLayer]) do
      begin
        s := slots[j];
        s := ReplaceStr(s, '.', ',');
        aufgaben[i,j] := strtofloat(s);
      end;

      slots := StringSplit(loesung, ',');
      setLength(loesungen[i],layerSizes[outputLayer]);
      setLength(ergebnis[i],layerSizes[outputLayer]);
      for j := 0 to high(neuron[outputLayer]) do
      begin
        s := slots[j];
        s := ReplaceStr(s, '.', ',');
        loesungen[i,j] := strtofloat(s);
      end;
      inc(i)
    end;
    aufgabenCount := i;
    CloseFile(f);

    setLength(aufgaben,aufgabenCount);
    setLength(loesungen,aufgabenCount);
    setLength(ergebnis,aufgabenCount);
    BtnStart.Enabled := true;
    loop := 0;
    memo1.Clear;
    memo2.Clear;
    memo3.Clear;
    image1.Canvas.Clear;
    for i := 0 to aufgabenCount-1 do
      show(1000,i);
  end;
end;

procedure TForm1.Lernen;
var
  n : longint;
  function abbruchBedingung: boolean;
  var
    ab1,ab2,ab3,ab4 :boolean;
  begin
//    CBLernrateReduzieren: TCheckBox;
    if CBLernrateEnde.Checked then ab1 := (GlobalError <= TargetError) else ab1 := false;
    if CBMaxVersuche.Checked then ab2  := (loop >= maxVersuche) else ab2 := true;
    if CBearlyBreak.Checked then ab3   := (fTest = true) else ab3 := true;
    if CBMinVersuche.Checked then ab4  := (loop >= minVersuche) else ab4 := true;

    abbruchBedingung := (ab1 or ab2 or ab3)  and ab4;
  end;
begin
  loop := 0;

  repeat
    inc(loop);
    n := random(aufgabenCount);

    neuron[inputLayer] := aufgaben[n];
    target := loesungen[n];

    Feedforward;
    maxweight     := -999999;
    minweight     := 999999;
    Feedbackward;

    ergebnis[n] := neuron[outputLayer];
  until abbruchBedingung;
  BtnTrainingFile.Enabled:=true;
  show(1000,n);
end;

procedure TForm1.BtnStartClick;
begin
  BtnTrainingFile.Enabled:=false;
  BtnStart.Enabled:=false;
  TargetError   := strToFloat(EDTargetError.Text);
  maxVersuche   := strToInt(EDMaxLoops.Text);
  minVersuche   := strToInt(EDMinLoops.Text);
  LernrateStart := strToFloat(EDLearnrateStart.Text);
  LernrateEnde  := strToFloat(EDLearnrateEnde.Text);
  refreshRate   := strToInt(EDLearnrateRefreshRate.Text);
  lernrateReduzieren  := CBlernrateReduzieren.Checked;
  Lernen;
end;

procedure TForm1.BtnCloseClick;
begin
  Close;
end;


function TForm1.fTest:boolean;
var
  i,j,n,k : longint;
begin
  fTest := false;
  if (loop mod refreshRate) = 0 then
  begin
    k := 0;
    memo2.Clear;
    for n := 0 to aufgabenCount-1 do
    begin
      neuron[inputLayer] := aufgaben[n];
      Feedforward;
      ergebnis[n] := neuron[outputLayer];
      show(1000,n);
      i := 0;
      for j := 0 to layerSizes[outputLayer]-1 do
      begin
        ergebnis[n,j] := round(ergebnis[n,j]);
        if round(ergebnis[n,j]) = round(loesungen[n,j]) then
          inc(i);
      end;
      if i = layerSizes[outputLayer] then
        inc(k);
    end;
    if k = aufgabenCount then
      fTest := true;
  end;
end;

procedure TForm1.show(refreshRate,n:longint);
var
  s : string;
  j : longint;
begin
  if (loop mod refreshRate = 0) or (loop <= high(aufgaben) ) or (BtnTrainingFile.Enabled) then
  begin
    if  (not RBausgabeAusschalten.Checked) or (BtnTrainingFile.Enabled) then
    begin
      if CBgrafisch.Checked then
      begin
        application.ProcessMessages;
        if loop > 1 then
          showGrafikal;
      end;

      if CBtext.Checked then
      begin
        if loop <= high(aufgaben) then
        begin
          s := intToStr(n)+ '    ';;
          s += 'input-> ';
          for j := 0 to layerSizes[inputLayer]-1 do
            s += floatToStr(aufgaben[n,j]);
          memo1.lines.add(s);

          s := intToStr(n)+ '    ';;
          s += 'target-> ';
          for j := 0 to layerSizes[outputLayer]-1 do
            s += floatToStr(loesungen[n,j]);
          memo3.lines.add(s);
        end;
        s := intToStr(n)+ '    ';;
        s += 'output-> ';
        for j := 0 to layerSizes[outputLayer]-1 do
          s += intToStr(round(neuron[outputLayer,j]));
        memo2.lines.add(s);
      end;
    end;
  end;
  StatusBar1.Panels[0].Text := 'Error ' + floatToStr(GlobalError);
  StatusBar1.Panels[1].Text:='loop ' + inttoStr(loop);
  Application.ProcessMessages;
end;

function TForm1.scale(what,fromLow,fromHigh,toLow,toHigh:extended):extended;
begin
  if fromHigh-fromLow <> 0 then
    scale := (what*(toHigh-toLow))/(fromHigh-fromLow)+toLow
  else
    scale := 0;
end;

function TForm1.calcColor(what,fromLow,fromHigh,toLow,toHigh:extended):tColor;
var
  e : extended;
  i : longint;
begin
  e := scale(what,fromLow,fromHigh,toLow,toHigh);
  i := round(e);
  if i >= 0 then
  begin
    i := min(255,i);
    calcColor := RGBToColor(i,i,i)
  end
  else
  begin
    i *= -1;
    i := min(255,i);
    calcColor := RGBToColor(i,0,0);
  end;
end;

procedure TForm1.showGrafikal;
var
  maxLayerSize,
  diameter,
  i,j,k : integer;
  col   : tColor;
begin
  maxLayerSize := 0;
  for i := 0 to layercount -1 do
  begin
    if maxLayerSize<layerSizes[i] then
      maxlayerSize:=layerSizes[i];
  end;
  diameter := image1.Height div (layercount*2+1);
  i := image1.Width div (maxLayerSize*2+1);
  if i < diameter then
    diameter := i;
  image1.canvas.Pen.Width := 2;
  for i := 0 to layercount -1 do
  begin
    for j := 0 to layerSizes[i] -1 do
    begin
      point[i,j].x := (Image1.Width div (layerSizes[i]+1)) * (j+1);
      point[i,j].y := (Image1.height div (layercount+1)) * (i+1);
    end;
  end;

  Image1.canvas.Pen.color   := clBlue;
  Image1.canvas.Brush.Color := clBlue;
  Image1.Canvas.FloodFill(10,10,clBlue,fsBorder);

  for i := 0 to layercount -2 do
  begin
    for j := 0 to high(weights[i]) do
    begin
      for k := 0 to high(weights[i,j]) do
      begin
        col := calcColor(weights[i,j,k],minweight,maxweight,0,255);
        Image1.canvas.Pen.color   := col;
        Image1.canvas.Brush.Color := col;
        Image1.Canvas.line(point[i+1,j].x,point[i+1,j].y,point[i,k].x,point[i,k].y);
      end;
    end;
  end;

  for i := 0 to layercount -1 do
  begin
    for j := 0 to layerSizes[i] -1 do
    begin
      col := calcColor(neuron[i,j],minaktivitaet,maxaktivitaet,0,255);
      image1.canvas.Pen.color   := col;
      Image1.canvas.Brush.Color := col;
      Image1.Canvas.Ellipse(point[i,j].x-diameter div 2,point[i,j].y-diameter div 2,point[i,j].x+diameter div 2,point[i,j].y+diameter div 2);
//      Image1.Canvas.FloodFill(point[i,j].x,point[i,j].y,col,fsBorder);
    end;
  end;
  StatusBar1.Panels[0].Text := 'Error ' + floatToStr(GlobalError);
  StatusBar1.Panels[1].Text:='loop ' + inttoStr(loop);
  application.ProcessMessages;
end;


end.


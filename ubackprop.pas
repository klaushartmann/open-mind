unit ubackprop;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,math;
var
  lernrateReduzieren : boolean;

  Lernrate, (* Epsilon *)
  LernrateStart,
  LernrateEnde,
  TargetError,
  GlobalError,
  maxaktivitaet,
  minaktivitaet,
  minweight,
  maxweight      : extended;


  aufgabenCount,
  minVersuche,
  maxVersuche,
  loop,
  layerCount,
  inputLayer,
  outputLayer : longInt;

  layerSizes  : array of longInt;

  weights : array of array of array of extended;
  biases  : array of array of extended;
  neuron  : array of array of extended;
  delta   : array of array of extended;
  target  : array of extended;

//  function fSigmoid (x : extended): extended;
//  function fEpsilon:extended;
  procedure init;
  procedure loadBrain(fileName : string);
  procedure safeBrain(fileName : string);
  procedure Feedforward;
  procedure Feedbackward;
//  function fMarsagliaPolarMethod:extended;

implementation

function fMarsagliaPolarMethod:extended;
var
  x1,x2,w,y1 : extended;
begin
  repeat
    x1 := random(2)-1;
    x2 := random(2)-1;
    w  := x1*x1+x2*x2;
  until (w>= 1);
  y1 := (-2.0 * ln(w))/w ;
  y1 *= y1;
  w  := sqrt(y1);
  y1 := x1 * w;
  w := w*2-1;
  fMarsagliaPolarMethod := w;
end;

procedure init;
var
  i, j,k : longint;
begin
  randomize;
  loop := 0;

  setLength(weights,layerCount-1);
  for i := 0 to high(weights) do
  begin
    setLength(weights[i],layerSizes[i+1]);
    for j := 0 to high(weights[i]) do
      setLength(weights[i,j],layerSizes[i]);
  end;

  setLength(biases,layerCount-1);
  for i := 0 to high(biases) do
    setLength(biases[i],layerSizes[i+1]);

  setLength(neuron,layerCount);
  for i := 0 to high(neuron) do
    setLength(neuron[i],layerSizes[i]);

  setLength(delta,layerCount-1);
  for i := 0 to high(delta) do
    setLength(delta[i],layerSizes[i+1]);

  for i := 0 to high(weights) do
  begin
    for j := 0 to high(weights[i]) do
    begin
      for k := 0 to high(weights[i,j]) do
        weights[i,j,k] := fMarsagliaPolarMethod;
      biases[i,j] := fMarsagliaPolarMethod;
    end;
  end;
  setLength(target,layerSizes[outputLayer]);
end;

function fSigmoid (x : extended): extended;
begin
  fSigmoid := 1 / (1 + exp(-x));
end;

function fEpsilon:extended;
var
  e : extended;
begin
  if lernrateReduzieren = true then
    e := LernrateStart*power((LernrateEnde/LernrateStart),(loop/maxVersuche))
  else
    e := LernrateStart;
  fEpsilon := e;
end;

procedure loadBrain(fileName : string);
begin

end;

procedure safeBrain(fileName : string);
var
  i,j,k     : longint;
  f         : file of extended;
  fileValue : extended;
begin
  AssignFile(f,fileName);
  reset(f);

  fileValue := layerCount;
  write(f,fileValue);
  for i := 0 to layerCount-1 do
  begin
    fileValue := layerSizes[i];
    write(f,fileValue);
  end;
  for i := 0 to high(weights) do
  begin
    for j := 0 to high(weights[i]) do
    begin
      for k := 0 to high(weights[i,j]) do
      begin
        fileValue := weights[i,j,k];
        write(f,fileValue);
      end;
    end;
  end;
  close(f);
end;

procedure Feedforward;
var
  i,j,k : longint;
  a     : extended;
begin
  maxaktivitaet := -999999;
  minaktivitaet := 999999;
  for i := 0 to high(weights) do
  begin
    for j := 0 to high(weights[i]) do
    begin
      a := 0;
      for k := 0 to high(weights[i,j]) do
        a := a + (neuron[i,k] * weights[i,j,k]);
      neuron[i+1,j] := fSigmoid(a + biases[i,j]);
      if maxaktivitaet < neuron[i+1,j] then
        maxaktivitaet := neuron[i+1,j];
      if minaktivitaet > neuron[i+1,j] then
        minaktivitaet := neuron[i+1,j];
    end;
  end;
end;

procedure Feedbackward;
  var i,j,k : longint;
begin
  GlobalError := 0;
  Lernrate := fEpsilon;
  for i := high(neuron) downto 1 do
  begin
    if i = high(neuron) then                      //erster Durchlauf : i ist 2 bei drei Layern
    begin
      for j := 0 to high(delta[outputLayer-1]) do
      begin
        delta[outputLayer-1,j] := (target[j] - neuron[outputLayer,j]) * neuron[outputLayer,j] * (1 - neuron[outputLayer,j]);
        GlobalError += sqr(target[j] - neuron[outputLayer,j]);
      end;

      for j := 0 to high(weights[outputLayer-1]) do
      begin
        for k := 0 to high(weights[outputLayer-1,j]) do
        begin
          weights[outputLayer-1,j,k] := weights[outputLayer-1,j,k] + (Lernrate * delta[outputLayer-1,j] * neuron[outputLayer-1,k]);
          if maxweight < weights[outputLayer-1,j,k] then
            maxweight := weights[outputLayer-1,j,k];
          if minweight > weights[outputLayer-1,j,k] then
            minweight := weights[outputLayer-1,j,k];
        end;
        biases[outputLayer-1,j] := biases[outputLayer-1,j] + (Lernrate * delta[outputLayer-1,j])
      end;
    end                                          // Ende erster Durchlauf
    else
    begin                                        //zweiter Durchlauf : i ist 1 bei drei Layern
      for j := 0 to high(delta[i-1]) do
      begin
        delta[i-1,j] := 0;
        for k := 0 to high(weights[i]) do
          delta[i-1,j] := delta[i-1,j] + (delta[i,k] * weights[i,k,j]);
        delta[i-1,j] := delta[i-1,j] * neuron[i,j] * (1 - neuron[i,j])
      end;

      for j := 0 to high(weights[i-1]) do
      begin
        for k := 0 to high(weights[i-1,j]) do
        begin
          weights[i-1,j,k] := weights[i-1,j,k] + (Lernrate * delta[i-1,j] * neuron[i-1,k]);
          if maxweight < weights[i-1,j,k] then
            maxweight := weights[i-1,j,k];
          if minweight > weights[i-1,j,k] then
            minweight := weights[i-1,j,k];
        end;
        biases[i-1,j] := biases[i-1,j] + (Lernrate * delta[i-1,j]);
      end;
    end;
  end;
end;


end.


unit uStringTools;

{$mode objfpc}{$H+}

interface

uses
  Classes,SysUtils,strutils;

type
  TParts = array of string;

  function extractIntFromText(s:string):longint;
  function StringSplit(Source: string; seperator: char): TParts;

implementation

  function StringSplit(Source: string; seperator: char): TParts;
  var
    Count, counter: integer;
    TArray: array of string;
  begin
    Count := WordCount(Source,[seperator]);
    SetLength(TArray, Count);
{


// dont work as expected.
// so I did some ugly very old style workaround
    for counter := 0 to Count-1 do
    begin
//      TArray[counter] := ExtractWord(counter,Source,[seperator]);
      ExtractDelimited(Count,Source,[seperator]);
    end;
}
    counter := 0;
    while Pos(seperator, Source) > 0 do
    begin
      TArray[counter] := (Copy(Source, 1, Pos(seperator, Source)-1));
      Delete(Source, 1, Pos(seperator, Source));
      inc(counter);
    end;
    TArray[counter] := Source;
    StringSplit := TArray;
  end;

  function extractIntFromText(s:string):longint;
  begin
    while  pos('/',s) >0 do
    begin
      delete(s,pos('/',s),length(s));
    end;
    s := trim(s);
    extractIntFromText := strToInt(s);
  end;

end.

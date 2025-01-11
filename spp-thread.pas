program threadtest;    
{$mode objfpc}

uses
  {$ifdef unix}
  cthreads,cmem,
  {$endif}
  SysUtils,Classes,Math,uVect,uScene,uBMP,uBVH,getopts;

const
   MaxThread=8;
var
  BMP:BMPrecord;

type
  LineArray=array[0..255] of rgbColor;
  TMyThread = class(TThread)
    y:integer;
    Line:LineArray;
    procedure Execute; override;
    procedure AddAxis;
  end;
  
  procedure TMyThread.Execute;
  var
    i:byte;
  begin
     while y<255 do begin
        for i:=0 to 255  do begin
           Line[i].r:=i;
           Line[i].g:=y;
           Line[i].b:=128;
        end;
        Synchronize(@AddAxis);
     end;
  end;
  procedure TMyThread.AddAxis;
  var
     j:integer;
  begin
     writeln(' y=',y);
     for j:=0 to 255 do BMP.SetPixel(j,y,line[j]);
     y:=y+MaxThread;
  end;
  
  
  
var
  i,y:byte;
  ThreadAry:array[0..MaxThread-1] of TMyThread;
begin
  BMP.new(256,256);
  for i:=0 to MaxThread-1 do begin
    ThreadAry[i]:=TMyThread.Create(true);ThreadAry[i].FreeOnTerminate:=true;
    ThreadAry[i].y:=i;
  end;
  writeln('Setup!');
  
  for i:=0 to MaxThread-1 do begin
    ThreadAry[i].Start;
  end;
   for i:=0 to MaxThread-1 do begin
    ThreadAry[i].WaitFor;
   end;
   BMP.WritePPM('test.ppm');
end.
  

program sppthread;    
{$mode objfpc}
{$modeswitch advancedrecords}

uses
  {$ifdef unix}
  cthreads,cmem,
  {$endif}
  SysUtils,Classes,Math,uVect,uScene,uBMP,uBVH,getopts,uSPP;

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
  x,y,sx,sy,i,s: integer;
  w,h,samps,height    : integer;
  temp,d       : Vec3;
  r1,r2,dx,dy  : real;
  cam:CamRecord;
   cx,cy: Vec3;
  tColor,r,camPosition,camDirection : Vec3;

  ScrWidth,ScrHeight:integer;
  vColor:rgbColor;
  ArgInt:integer;
  FN,ArgFN:string;
  c:char;

  rt:TRenderClass;

var
  ThreadAry:array[0..MaxThread-1] of TMyThread;
begin
  FN:='temp.bmp';
  w:=256 ;h:=192;  samps := 16;
  c:=#0;
  repeat
    c:=getopt('o:s:w:');

    case c of
      'o' : begin
         ArgFN:=OptArg;
         if ArgFN<>'' then FN:=ArgFN;
         writeln ('Output FileName =',FN);
      end;
      's' : begin
        ArgInt:=StrToInt(OptArg);
        samps:=ArgInt;
        writeln('samples =',ArgInt);
      end;
      'w' : begin
         ArgInt:=StrToInt(OptArg);
         w:=ArgInt;h:=w *3 div 4;
         writeln('w=',w,' ,h=',h);
      end;
      '?',':' : begin
         writeln(' -o [finename] output filename');
         writeln(' -s [samps] sampling count');
         writeln(' -w [width] screen width pixel');
      end;
    end; { case }
  until c=endofoptions;
  height:=h;
  BMP.new(w,h);
  InitScene;
  Randomize;

  camPosition.new(50, 52, 295.6);
  camDirection.new(0, -0.042612, -1);
  camDirection:=camDirection.norm;
  cam.new(camPosition, camDirection,w,h );

  rt:=TRenderClass.Create(sph,cam);

  
  ScrWidth:=0;
  ScrHeight:=0;
  writeln ('The time is : ',TimeToStr(Time));

  for y := 0 to h-1 do begin
    if y mod 10 =0 then writeln('y=',y);
    for x := 0 to w - 1 do begin
      r:=ZeroVec;
      tColor:=ZeroVec;
      for sy := 0 to 1 do begin
        for sx := 0 to 1 do begin
           for s := 0 to samps - 1 do begin
              temp:=rt.Radiance(Cam.GetRay(x,y,sx,sy), 0);
              temp:= temp/ samps;
              r:= r+temp;
          end;(*samps*)
          temp:= ClampVector(r)* 0.25;
          tColor:=tColor+ temp;
          r:=ZeroVec;
        end;(*sx*)
      end;(*sy*)
      vColor:=ColToRGB(tColor);
      BMP.SetPixel(x,height-y,vColor);
    end;(* for x *)
  end;(*for y*)
  writeln ('The time is : ',TimeToStr(Time));
  BMP.WriteBMPFile(FN);



   
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
   BMP.WritePPM('threadtest.ppm');
end.
  

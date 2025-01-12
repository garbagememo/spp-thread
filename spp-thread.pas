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
   
  LineArray=array[0..255*255] of rgbColor;
  TMyThread = class(TThread)
     samps:integer;//render option
     y:integer;
     Line:LineArray;
     rt:TRenderClass;
     procedure Execute; override;
     procedure AddAxis;
  end;
  
  procedure TMyThread.Execute;
  var
     x,sx,sy,s:integer;
     r,tColor,temp:Vec3;
  begin
    while y<rt.cam.h do begin
      if y mod 10 =0 then writeln('y=',y);
      for x := 0 to rt.cam.w - 1 do begin
        r:=ZeroVec;
        tColor:=ZeroVec;
        for sy := 0 to 1 do begin
          for sx := 0 to 1 do begin
            for s := 0 to samps - 1 do begin
              temp:=rt.Radiance(rt.cam.GetRay(x,y,sx,sy), 0);
              temp:= temp/ samps;
              r:= r+temp;
            end;(*samps*)
            temp:= ClampVector(r)* 0.25;
            tColor:=tColor+ temp;
            r:=ZeroVec;
          end;(*sx*)
        end;(*sy*)
        Line[x]:=ColToRGB(tColor);
      end;(* for x *)
      Synchronize(@AddAxis);
     end;(*for y*)
  end;
  procedure TMyThread.AddAxis;
  var
     j:integer;
     yAxis:integer;
  begin
     yAxis:=rt.cam.h-y-1;
     for j:=0 to rt.cam.w-1 do BMP.SetPixel(j,yAxis,line[j]);
     y:=y+MaxThread;
  end;
  
  
var
  i: integer;
  w,h,samps    : integer;
  cam:CamRecord;
  camPosition,camDirection : Vec3;

  ArgInt:integer;
  FN,ArgFN:string;
  c:char;
var
  ThreadAry:array[0..MaxThread-1] of TMyThread;
begin
  FN:='temp.bmp';
  w:=640 ;h:=480;  samps := 16;
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
  BMP.new(w,h);
  InitScene;
  Randomize;

  camPosition.new(50, 52, 295.6);
  camDirection.new(0, -0.042612, -1);
  camDirection:=camDirection.norm;
  cam.new(camPosition, camDirection,w,h );

   writeln ('The time is : ',TimeToStr(Time));
   
  BMP.new(cam.w,cam.h);
  for i:=0 to MaxThread-1 do begin
     ThreadAry[i]:=TMyThread.Create(true);
     ThreadAry[i].FreeOnTerminate:=false;//falseにしないとスレッドが休止時の後始末ができない。
     ThreadAry[i].rt:=TRenderClass.Create(sph,cam);
     ThreadAry[i].y:=i;
     ThreadAry[i].samps:=samps;
  end;
  writeln('Setup!');
  
  for i:=0 to MaxThread-1 do begin
    ThreadAry[i].Start;
  end;
  //このルーチンが別途で無いとマルチスレッドにならない
  for i:=0 to MaxThread-1 do begin
    ThreadAry[i].WaitFor;
  end;
   writeln(' ober=');
   BMP.WritePPM('threadtest.ppm');
end.
  

program sppthread;    
{$mode objfpc}
{$modeswitch advancedrecords}

uses
  {$ifdef unix}
  cthreads,cmem,
  {$endif}
  SysUtils,Classes,Math,uVect,uBMP,getopts,uDetector;

const
   MaxThread=8;
var
  BMP:BMPrecord;

type
   
   //スタックサイズが不定を嫌ってdynamic arrayは使わない
   LineArray=array[0..255*255] of rgbColor;

   TMyThread = class(TThread)
      wide,hight,samps:integer;//render option
      y:integer;
      Line:LineArray;
      cam:CamRecord;
      procedure Execute; override;
      procedure AddAxis;
   end;
  
  procedure TMyThread.Execute;
  var
     x,sx,sy,s:integer;
     r,tColor:Vec3;
  begin
    while y<hight do begin
      if y mod 10 =0 then writeln('y=',y);
      for x := 0 to wide - 1 do begin
        tColor:=ZeroVec;
        for sy := 0 to 1 do begin
          for sx := 0 to 1 do begin
             r:=ZeroVec;
             for s := 0 to samps - 1 do begin
               r:= r+radiance(cam.GetRay(x,y,sx,sy), 0)/ samps;
             end;(*samps*)
             tColor:=tColor+ ClampVector(r)* 0.25;
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
     yAxis:=hight-y-1;
     for j:=0 to wide-1 do BMP.SetPixel(j,yAxis,line[j]);
     y:=y+MaxThread;
  end;
  
  
var
  i: integer;
  modelnum,w,h,samps: integer;
  camPosition,camDirection : Vec3;
  ArgInt:integer;
  FN,ArgFN:string;
  c:char;
  StarTime:TDateTime;
var
  ThreadAry:array[0..MaxThread-1] of TMyThread;
begin
  FN:='temp.bmp';
  w:=640 ;h:=480;  samps := 16;
  c:=#0;
  modelnum:=0;
  repeat
    c:=getopt('m:o:s:w:');
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
      'm' : begin
         ArgInt:=StrToInt(OptArg);
         modelnum:=ArgInt;
         writeln('model-number=',modelnum);
      end;
      '?',':' : begin
         writeln(' -o [finename] output filename');
         writeln(' -s [samps] sampling count');
         writeln(' -w [width] screen width pixel');
         writeln(' -m [id] scene model number 0..4');
      end;
    end; { case }
  until c=endofoptions;
 
  BMP.new(w,h);

  writeln('samps=',samps);
  writeln('size=',w,'x',h);
  writeln('modele number=',modelnum);
  writeln('output=',FN);

  Randomize;
  case modelnum of
    0:initScene;
    1:initNEScene;
    2:SkyScene;
    3:ForestScene;
    4:wadaScene;
    else begin
      initScene;
    end;
  end;(*case*)

  cam.new(camPosition.new(50, 52, 295.6),camDirection.new(0, -0.042612, -1).norm,w,h );

  writeln ('The time is : ',TimeToStr(Time));
  StarTime:=Time; 
  BMP.new(cam.w,cam.h);
  for i:=0 to MaxThread-1 do begin
     ThreadAry[i]:=TMyThread.Create(true);
     ThreadAry[i].FreeOnTerminate:=false;
     //falseにしないとスレッドが休止時の後始末ができない。
     ThreadAry[i].y:=i;
     ThreadAry[i].wide:=cam.w;
     ThreadAry[i].hight:=cam.h;
     ThreadAry[i].cam:=cam;
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
  writeln('The time is : ',TimeToStr(Time));
  writeln('Calcurate time is=',TimeToStr(Time-StarTime));
  BMP.WriteBMPFile('threadtest.bmp');
end.
  

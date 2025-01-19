﻿unit uHybrid;
{$MODE objfpc}{$H+}
{$INLINE ON}
{$modeswitch advancedrecords}

interface
uses uVect,uScene,Math,Classes;
const
  Nil_Leaf=16384;
type
  IntegerArray=array of integer;

  BVHNodeClass=Class
    root:AABBRecord;
    left,right:BVHNodeClass;
    leaf:integer;
    constructor Create(ary:IntegerArray;sph:TList);
    function intersect(r:RayRecord):InterRecord;
  end;

  HybridBVHClass=Class
    NoBVHary:IntegerArray;
    BVH:BVHNodeClass;
    constructor Create(o:Vec3);
    function intersect(r:RayRecord):InterRecord;
  end;

procedure AABBSort(var a: array of integer);
   
implementation


function GetAABBVal(suf:integer;axis:integer):real;
begin
  case axis of
    1:result:=SphereClass(sph[suf]).BoundBox.min.x;
    2:result:=SphereClass(sph[suf]).BoundBox.min.y;
    else begin
      result:=SphereClass(sph[suf]).BoundBox.min.z;
    end;
  end ;(*case*)
end;

procedure AABBSort(var a: array of integer);//バブルソート
var
   i, j, h,axis: integer;
   ar:real;
begin
   ar:=random;
   if ar<0.33 then axis:=1 else if ar<0.67 then axis:=2 else axis:=3;
   for i := 0 to High(a) do begin
       for j := 1 to High(a) - i  do begin
           if GetAABBVal(a[j],axis) < GetAABBVal(a[j-1],axis) then begin
             h:=a[j-1];a[j-1]:=a[j];a[j]:=h;
         end;
       end;
  end;
end;

constructor BVHnodeClass.Create(ary:IntegerArray;sph:TList);
var
   upAry,DownAry:IntegerArray;
   i,len:integer;
begin
   AABBSort(ary);
   Leaf:=Nil_Leaf;
   root:=sphereclass(sph[ary[0]]).BoundBox;
    
  case High(Ary) of
    0:Leaf:=ary[0];//要素1
    1:begin
       Root:=MargeBoundBox(Root,SphereClass(sph[ary[1] ]).BoundBox);
       setLength(UpAry,1);
       SetLength(downAry,1);
       upAry[0]:=Ary[0];
       DownAry[0]:=Ary[1];
       Left:=BVHNodeClass.Create(upAry,sph);
       right:=BVHNodeClass.Create(DownAry,sph);
    end;
    else begin
      for i:=1 to high(ary)  do begin
        Root:=MargeBoundBox(Root,SphereClass(sph[ary[i] ]).BoundBox);
      end;
      len:=length(Ary) div 2;
      upAry:=Copy(Ary,0,len);
      DownAry:=Copy(Ary,len,length(Ary)-len);
       
      Left:=BVHNodeClass.Create(UpAry,sph);
      right:=BVHNodeClass.Create(DownAry,sph);
    end;
  end;
end;

function BVHnodeClass.intersect(r:RayRecord):InterRecord;
var
   RIR,LIR:InterRecord;
   t:real;
begin
  result.isHit:=false;
  result.t:=INF;
  result.id:=0;
  if leaf<>Nil_Leaf then begin
     result.t:=SphereClass(sph[leaf]).intersect(r);
     if result.t<INF then begin
        result.id:=Leaf;
        result.isHit:=true;
     end;
     exit;
  end;
  
  if root.Hit(r,EPS,INF) then begin
     RIR:=Right.intersect(r);
     LIR:=Left.intersect(r);
     if (LIR.isHit or RIR.isHit) then begin
        if RIR.isHit then result:=RIR;
        if LIR.isHit then begin
           if RIR.isHit=false then
              result:=LIR
           else if RIR.t>LIR.t then
              result:=LIR;
        end;
     end;
  end
  else begin
    result.isHit:=false;
    result.t:=INF;
  end;
end;

constructor  HybridBVHClass.create(o:Vec3);
var
  ary:IntegerArray;
  i,j,k,l:integer;
  s:SphereClass;
begin
  SetLength(ary,sph.count);
  SetLength(NoBVHary,sph.count);
  for i:=0 to sph.count-1 do begin ary[i]:=-1;NoBVHary[i]:=-1;end;
  j:=-1;k:=-1;
  for i:=0 to sph.count-1 do begin
    s:=SphereClass(sph[i]);
    if (s.rad/(s.p-o).len >0.5 ) and (s.rad>1e3) then begin
      j:=j+1;NoBVHary[j]:=i;
    end 
    else begin
      k:=k+1;ary[k]:=i;
    end;
  end;
  SetLength(NoBVHary,j+1);SetLength(ary,k+1);
  BVH:=BVHNodeClass.Create(ary,sph);
end;

function HybridBVHClass.intersect(r:RayRecord):InterRecord;
var
  ir:InterRecord;
  i:integer;
  t:real;
begin
  ir:=BVH.intersect(r);
  for i:=0 to Length(NoBVHary)-1 do begin
    t:=SphereClass(sph[NoBVHary[i]]).intersect(r);
    if ir.t>t then begin
      ir.isHit:=true;
      ir.t:=t;
      ir.id:=NoBVHary[i];
    end;
  end;
  result:=ir;
end;

begin
end.

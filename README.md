# FreePascalによるマルチスレッドなレイトレーシング
## ひっかかった所
* TMyThread.FreeOnTerminate=FALSEにしないと、TMyThread終了後に後作業ができない（計算結果を反映させる等）  
* StartとWaitforはセットにして、なおかつマルチスレッド発呼後の後にWaitforを置く  
具体的には  
```
 for i:=0 to MaxThread-1 do ThreadAry[i].Start;
  //Startが終わった後にWaitforが別途で無いとマルチスレッドにならない
  for i:=0 to MaxThread-1 ThreadAry[i].WaitFor;   
 ```
 というコードになる。
 * スレッドコードの中でSynchronize（プロシージャ）とするとメインの方に制御が移動する  
あたりがコツとなりましょうか。

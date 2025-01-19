# Multi-threaded ray tracing with FreePascal
## Stuck points
* If you don't set TMyThread.FreeOnTerminate=FALSE, you can't do post-processing after TMyThread ends (such as reflecting calculation results)
* Set Start and Waitfor together, and place Waitfor after calling multi-threading
Specifically
```
for i:=0 to MaxThread-1 do ThreadAry[i].Start;
//Multi-threading won't work unless Waitfor is called separately after Start
for i:=0 to MaxThread-1 do ThreadAry[i].WaitFor;
```
The code becomes like this.
* If you use Synchronize (procedure) in the thread code, control will move to the main
I guess that's the trick.

# FreePascalによるマルチスレッドなレイトレーシング
## ひっかかった所
* TMyThread.Create(true)の意味は自動起動しないという意味。これがないとCreate内以外の初期化ができない  
* TMyThread.FreeOnTerminate=FALSEにしないと、TMyThread終了後に後作業ができない（計算結果を反映させる等）  
* StartとWaitforはセットにして、なおかつマルチスレッドをすべて発呼後にWaitforを置かないとマルチスレッドにならない  
具体的には  
```
 for i:=0 to MaxThread-1 do ThreadAry[i].Create(true);コンストラクタ内以外で初期化が必要ならtrueにして、その後Startで起動
 for i:=0 to MaxThread-1 do ThreadAry[i].Start;
  //Startが終わった後にWaitforが別途で無いとマルチスレッドにならない
  for i:=0 to MaxThread-1 do ThreadAry[i].WaitFor;   
 ```
 というコードになる。
 * スレッドコードの中でSynchronize（プロシージャ）とするとメインの方に制御が移動する
もコツと言えるでしょう。

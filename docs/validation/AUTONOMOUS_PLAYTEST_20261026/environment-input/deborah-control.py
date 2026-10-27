"""Task-owned, bounded input/screenshot controller for the one local GMod client."""
from pathlib import Path
import subprocess,json,time,re,sys
request=Path('/tmp/deborah-control-request.json')
actions=json.loads(request.read_text())
assert isinstance(actions,list) and 0<len(actions)<=20

def call(args,timeout=20):
 return subprocess.check_output(args,text=True,timeout=timeout,stderr=subprocess.STDOUT).strip()

ids=call(['xdotool','search','--onlyvisible','--name',"^Garry.s Mod$"]).splitlines()
assert len(ids)==1,('Expected exactly one visible GMod client',ids)
wid=ids[0]
name=call(['xdotool','getwindowname',wid])
assert name=="Garry's Mod",name
call(['xdotool','windowactivate','--sync',wid])
assert call(['xdotool','getactivewindow'])==wid,'GMod did not receive focus'
result={'window':wid,'name':name,'actions':[]}
for a in actions:
 kind=a['action']
 assert call(['xdotool','getactivewindow'])==wid,'Focus changed; input stopped'
 if kind=='key':
  keys=a['keys'];assert isinstance(keys,list) and 1<=len(keys)<=10
  assert all(re.fullmatch(r'[A-Za-z0-9_+]+',k) for k in keys)
  if keys==['Return']:
   call(['xdotool','keydown','--clearmodifiers','Return']);time.sleep(.13);call(['xdotool','keyup','Return'])
  else:call(['xdotool','key','--clearmodifiers',*keys])
 elif kind=='hold':
  keys=a['keys'];seconds=float(a['seconds'])
  assert 0<seconds<=10 and 0<len(keys)<=4
  assert all(k in ['w','a','s','d','e','r','space','Shift_L','Control_L','Up','Down','Left','Right','q','m','p','i','o','l','grave','Escape'] for k in keys)
  from evdev import UInput, ecodes as e
  keycodes={c:getattr(e,'KEY_'+c.upper()) for c in 'abcdefghijklmnopqrstuvwxyz'}
  keycodes.update(space=e.KEY_SPACE,Shift_L=e.KEY_LEFTSHIFT,Control_L=e.KEY_LEFTCTRL,Up=e.KEY_UP,Down=e.KEY_DOWN,Left=e.KEY_LEFT,Right=e.KEY_RIGHT,grave=e.KEY_GRAVE,Escape=e.KEY_ESC)
  with UInput({e.EV_KEY:list(set(keycodes.values()))},name='Deborah bounded playtest keyboard') as device:
   time.sleep(.6)
   assert call(['xdotool','getactivewindow'])==wid,'Focus changed before raw keyboard input'
   try:
    for key in keys:device.write(e.EV_KEY,keycodes[key],1)
    device.syn();time.sleep(seconds)
   finally:
    for key in keys:device.write(e.EV_KEY,keycodes[key],0)
    device.syn();time.sleep(.3)
 elif kind=='walk':
  import math
  from evdev import UInput, ecodes as e
  points=a['points'];budget=float(a.get('seconds',15));tolerance=float(a.get('tolerance',48))
  assert isinstance(points,list) and 1<=len(points)<=8 and 1<=budget<=20 and 30<=tolerance<=65
  assert all(isinstance(q,list) and len(q)==3 and all(isinstance(x,(int,float)) and math.isfinite(x) and abs(x)<17000 for x in q) for q in points)
  probe=Path('/home/deck/.local/share/Steam/steamapps/common/GarrysMod/garrysmod/data/legend_of_deborah/playtest_probe_latest.txt')
  def observe():
   assert probe.exists() and time.time()-probe.stat().st_mtime<3,'Position observer stale'
   state=json.loads(probe.read_text())
   assert state['hp']>0,'Player died; release native controls'
   return state
  codes={'w':e.KEY_W,'a':e.KEY_A,'s':e.KEY_S,'d':e.KEY_D}
  arrivals=[];trace=[];pressed=set();started=time.monotonic();initial=observe();status='time_limit'
  with UInput({e.EV_KEY:list(codes.values())},name='Deborah bounded native walking') as device:
   time.sleep(.6)
   def set_keys(wanted):
    global_unused=None
    for key in pressed-wanted:device.write(e.EV_KEY,codes[key],0)
    for key in wanted-pressed:device.write(e.EV_KEY,codes[key],1)
    device.syn();pressed.clear();pressed.update(wanted)
   try:
    for point in points:
     best=math.inf;last_progress=time.monotonic()
     while time.monotonic()-started<budget:
      assert call(['xdotool','getactivewindow'])==wid,'Focus changed during native walking'
      state=observe();pos=state['pos'];dx,dy=point[0]-pos[0],point[1]-pos[1];distance=math.hypot(dx,dy)
      trace.append({'position':pos,'hp':state['hp'],'target':point,'t':state['t']})
      if state['hp']<max(20,initial['hp']-25):status='damage_interrupt';break
      if distance<=tolerance:
       set_keys(set());time.sleep(.3);state=observe();pos=state['pos']
       if math.hypot(point[0]-pos[0],point[1]-pos[1])<=tolerance+18:
        if abs(point[2]-pos[2])>90:status='height_mismatch';break
        arrivals.append({'target':point,'position':pos});status='arrived';break
      if distance<best-8:best=distance;last_progress=time.monotonic()
      elif time.monotonic()-last_progress>2.5:status='stalled';break
      yaw=math.radians(state['ang'][1]);forward=dx*math.cos(yaw)+dy*math.sin(yaw);right=dx*math.sin(yaw)-dy*math.cos(yaw)
      wanted=set()
      if abs(forward)>28:wanted.add('w' if forward>0 else 's')
      if abs(right)>28:wanted.add('d' if right>0 else 'a')
      set_keys(wanted);time.sleep(.10)
     else:status='time_limit'
     if status!='arrived':break
   finally:
    set_keys(set());time.sleep(.3)
  logfile=Path('/tmp/deborah-native-walk-log.jsonl')
  with logfile.open('a') as stream:stream.write(json.dumps({'initial':initial,'targets':points,'status':status,'arrivals':arrivals,'trace':trace})+'\n')
  result['actions'].append({'action':'walk','status':status,'arrivals':arrivals,'trace':str(logfile)});continue
 elif kind=='logical_hold':
  keys=a['keys'];seconds=float(a['seconds'])
  assert isinstance(keys,list) and 1<=len(keys)<=4 and 0<seconds<=2
  assert all(re.fullmatch(r'[A-Za-z0-9_+]+',k) for k in keys)
  try:
   call(['xdotool','keydown','--clearmodifiers',*keys]);time.sleep(seconds)
  finally:call(['xdotool','keyup',*keys])
 elif kind=='text':
  value=a['text'];assert isinstance(value,str) and 0<len(value)<=6000 and '\n' not in value
  assert chr(96) not in value and '~' not in value,'Source console toggle character in text'
  call(['xdotool','type','--clearmodifiers','--delay','3','--',value])
 elif kind=='mouse':
  x,y=int(a['x']),int(a['y']);assert 0<=x<1280 and 0<=y<800
  call(['xdotool','mousemove','--window',wid,str(x),str(y)])
 elif kind=='look':
  dx,dy=int(a['dx']),int(a['dy']);assert abs(dx)<=2000 and abs(dy)<=1000
  from evdev import UInput, ecodes as e
  with UInput({e.EV_KEY:[e.BTN_LEFT],e.EV_REL:[e.REL_X,e.REL_Y]},name='Deborah bounded playtest mouse') as device:
   time.sleep(.5)
   assert call(['xdotool','getactivewindow'])==wid,'Focus changed before raw mouse input'
   import math
   steps=max(1,math.ceil(max(abs(dx),abs(dy))/50));px=py=0
   for i in range(1,steps+1):
    nx=round(dx*i/steps);ny=round(dy*i/steps)
    device.write(e.EV_REL,e.REL_X,nx-px);device.write(e.EV_REL,e.REL_Y,ny-py);device.syn()
    px,py=nx,ny;time.sleep(.06)
   time.sleep(.3)
 elif kind=='click':
  button=int(a.get('button',1));count=int(a.get('count',1));assert button in range(1,8) and 1<=count<=20
  call(['xdotool','click','--repeat',str(count),'--delay','70',str(button)])
 elif kind=='wait':
  seconds=float(a['seconds']);assert 0<=seconds<=5;time.sleep(seconds)
 elif kind=='move_window':
  call(['xdotool','windowmove',wid,'60','80'])
 elif kind=='screenshot':
  name=a['name'];assert re.fullmatch(r'[a-zA-Z0-9_.-]+\.png',name)
  path=Path('/tmp')/name
  call(['spectacle','-b','-n','-a','-o',str(path)],timeout=30)
  assert path.exists();result['actions'].append({'action':kind,'path':str(path)});continue
 else:raise ValueError('Unsupported game action: '+str(kind))
 result['actions'].append({'action':kind})
print(json.dumps(result))

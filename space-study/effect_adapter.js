/* CLOUD / PROBE: open technique research, Canvas 2D adapter.
CC0 inspiration:
https://godotshaders.com/shader/2d-fog-overlay/
https://godotshaders.com/shader/perspective-grid/
https://godotshaders.com/shader/scrolling-line-background/
This is not the original Godot shader. */
(function(root){
const clamp=(v,a,b)=>Math.max(a,Math.min(b,v));
const frac=x=>x-Math.floor(x);
const hash=(x,y)=>frac(Math.sin(x*127.1+y*311.7)*43758.5453);
function smooth(x,y){
const ix=Math.floor(x),iy=Math.floor(y),u=frac(x),v=frac(y),a=u*u*(3-2*u),b=v*v*(3-2*v);
return (hash(ix,iy)*(1-a)+hash(ix+1,iy)*a)*(1-b)+(hash(ix,iy+1)*(1-a)+hash(ix+1,iy+1)*a)*b;
}
const buffer=document.createElement('canvas'),bc=buffer.getContext('2d');
let last=-1;
function ground(p,x,z){
const dx=x-p.x,dz=z-p.z,s=Math.sin(p.yaw),c=Math.cos(p.yaw),f=dx*s+dz*c,side=dx*c-dz*s;
if(f<10||f>1700)return null;const k=Math.min(p.w,p.h*1.5)/(2*Math.tan(Math.PI*36/180));
const px=p.w*.5+k*side/f,py=p.h*.51+k*34/f;
if(px< -p.w*.7||px>p.w*1.7||py>p.h*1.35)return null;
return [px,py];
}
function sea(ctx,p){
const top=p.h*.53,w=Math.max(60,Math.round(p.w/6)),h=Math.max(30,Math.round((p.h-top)/6)),stamp=Math.floor(p.time*8);
if(buffer.width!==w||buffer.height!==h){buffer.width=w;buffer.height=h;last=-1;}
if(stamp!==last){last=stamp;const img=bc.createImageData(w,h),data=img.data;
const k=Math.min(p.w,p.h*1.5)/(2*Math.tan(Math.PI*36/180)),sn=Math.sin(p.yaw),cs=Math.cos(p.yaw);
for(let j=0;j<h;j++){const y=top+(j+.5)*(p.h-top)/h,d=k*34/Math.max(3,y-p.h*.51),fade=clamp((y-p.h*.55)/(p.h*.19),0,1)*clamp((1900-d)/850,0,1);
for(let i=0;i<w;i++){const side=((i+.5)*p.w/w-p.w*.5)*d/k,x=p.x+sn*d+cs*side,z=p.z+cs*d-sn*side;
const nx=x*.004+p.time*.028,nz=z*.004-p.time*.016;
const n=.62*smooth(nx,nz)+.27*smooth(nx*2.1+1,nz*2.1)+.11*smooth(nx*4.1,nz*4.1);
const a=Math.round(clamp((n-.39)*1.85,0,.37)*fade*255),q=4*(j*w+i);data[q]=83;data[q+1]=p.color===1?143:192;data[q+2]=p.color===2?200:231;data[q+3]=a;}}
bc.putImageData(img,0,0);
}ctx.drawImage(buffer,0,top,p.w,p.h-top);
}
function circuit(ctx,p){
const gap=138,b=1100,c=p.color===1?"109,161,240":"83,204,225";ctx.save();ctx.lineWidth=1;
const line=(ax,az,bx,bz,a)=>{const x=ground(p,ax,az),y=ground(p,bx,bz);if(!x||!y)return;const fade=clamp((Math.min(x[1],y[1])-p.h*.52)/(p.h*.23),0,1);ctx.strokeStyle="rgba("+c+","+(a*fade)+")";ctx.beginPath();ctx.moveTo(...x);ctx.lineTo(...y);ctx.stroke();};
for(let ix=Math.floor((p.x-b)/gap);ix<=Math.ceil((p.x+b)/gap);ix++)for(let iz=Math.floor((p.z-b)/gap);iz<=Math.ceil((p.z+b)/gap);iz++){const n=hash(ix,iz),x=ix*gap,z=iz*gap;
if(n>.22)line(x,z,x,z+gap*.80,.12+n*.23);
if(hash(ix+30,iz)>.28)line(x,z,x+gap*.80,z,.10+n*.22);
if(n>.79){const v=frac(p.time*.14+n*7);line(x,z+gap*v,x,z+gap*Math.min(.96,v+.09),.48);}}
ctx.restore();
}
function echo(ctx,p){
const c=p.color===1?"94,170,243":"103,210,232";ctx.save();
const cs=Math.cos(p.yaw),sn=Math.sin(p.yaw);
for(let i=0;i<44;i++){const d=90+(i%11)*105,side=(Math.floor(i/11)-1.5)*260+(i%4)*39,x=p.x+sn*d+cs*side,z=p.z+cs*d-sn*side;
const a=hash(i,41),v=frac(p.time*(.12+a*.12)+a*4),q=ground(p,x,z+v*130),r=ground(p,x+65+a*125,z+v*130+20);
if(!q||!r)continue;const fade=clamp((q[1]-p.h*.52)/(p.h*.22),0,1);
ctx.strokeStyle="rgba("+c+","+(fade*(.10+.22*v))+")";ctx.lineWidth=.8+v;ctx.beginPath();ctx.moveTo(...q);ctx.lineTo(...r);ctx.stroke();}
const y=p.h*(.56+.32*frac(p.time*.14)),g=ctx.createLinearGradient(0,y-20,0,y+30);g.addColorStop(0,"rgba(50,160,195,0)");g.addColorStop(.5,"rgba(50,160,195,.13)");g.addColorStop(1,"rgba(50,160,195,0)");ctx.fillStyle=g;ctx.fillRect(0,y-20,p.w,50);ctx.restore();
}
root.CloudProbeFx={paint(ctx,state,w,h,time){const p={x:state.x,z:state.z,yaw:state.yaw,color:state.color,w,h,time};if(state.effect===1)sea(ctx,p);if(state.effect===2)circuit(ctx,p);if(state.effect===3)echo(ctx,p);}};
})(window);
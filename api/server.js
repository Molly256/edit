const express = require('express');
const multer = require('multer');
const axios = require('axios');
const FormData = require('form-data');
const cors = require('cors');

const app = express();
app.use(cors());
const upload = multer();

const HF_TOKEN = process.env.HF_TOKEN;
const MODEL = "stabilityai/stable-diffusion-2-inpainting";

// --- NEW WEBSITE UI ---
app.get('/', (req, res) => {
  res.send(`
<!DOCTYPE html>
<html>
<head>
<title>Canva Grab - AI Cleaner</title>
<meta name="viewport" content="width=device-width, initial-scale=1">
<style>
body{font-family:Arial; background:#f5f5f5; margin:0; padding:20px}
.box{background:white; max-width:600px; margin:20px auto; padding:25px; border-radius:16px; box-shadow:0 4px 20px rgba(0,0,0,0.1); text-align:center}
button{background:#7c3aed; color:white; border:none; padding:12px 28px; border-radius:8px; font-size:16px; cursor:pointer; margin:8px}
button:disabled{background:#aaa}
canvas{max-width:100%; border:1px solid #ddd; border-radius:8px; margin-top:10px; touch-action:none}
input{margin:10px 0}
img{max-width:100%; border-radius:10px; margin-top:15px}
</style>
</head>
<body>
<div class="box">
<h2>✨ Canva Grab - AI Text Remover</h2>
<p>Upload image, paint over text to remove, then Send to AI</p>
<input type="file" id="imgInput" accept="image/*">
<br>
<canvas id="c"></canvas><br>
<button onclick="clearMask()">Clear Paint</button>
<br><br>
<input type="text" id="prompt" placeholder="Prompt: clean background, no text" style="width:90%; padding:10px; border-radius:8px; border:1px solid #ccc" value="clean background, no text, seamless">
<br><br>
<button id="sendBtn" onclick="sendAI()">Send to AI 🤖</button>
<div id="status"></div>
<div id="result"></div>
</div>

<script>
let canvas=document.getElementById('c');
let ctx=canvas.getContext('2d');
let img=new Image();
let painting=false;

document.getElementById('imgInput').onchange=(e)=>{
  let file=e.target.files[0];
  img.onload=()=>{
    canvas.width=img.width;
    canvas.height=img.height;
    ctx.drawImage(img,0,0);
  }
  img.src=URL.createObjectURL(file);
}

canvas.addEventListener('mousedown',()=>painting=true);
canvas.addEventListener('mouseup',()=>painting=false);
canvas.addEventListener('mousemove',paint);
canvas.addEventListener('touchstart',(e)=>{painting=true; paint(e.touches[0]); e.preventDefault()});
canvas.addEventListener('touchend',()=>painting=false);
canvas.addEventListener('touchmove',(e)=>{paint(e.touches[0]); e.preventDefault()});

function paint(e){
  if(!painting) return;
  let rect=canvas.getBoundingClientRect();
  let x=(e.clientX||e.pageX)-rect.left;
  let y=(e.clientY||e.pageY)-rect.top;
  x=x*(canvas.width/rect.width);
  y=y*(canvas.height/rect.height);
  ctx.fillStyle='rgba(255,255,255,1)';
  ctx.beginPath();
  ctx.arc(x,y,20,0,Math.PI*2);
  ctx.fill();
}

function clearMask(){
  if(img.src) ctx.drawImage(img,0,0);
}

async function sendAI(){
  if(!img.src){alert('Upload image first'); return}
  document.getElementById('status').innerText='⏳ AI working... 30-60 sec, dont close';
  document.getElementById('sendBtn').disabled=true;

  // Create image blob
  let origCanvas=document.createElement('canvas');
  origCanvas.width=img.width; origCanvas.height=img.height;
  origCanvas.getContext('2d').drawImage(img,0,0);
  let imageBlob=await new Promise(r=>origCanvas.toBlob(r,'image/png'));

  // Create mask blob (white painted area = mask)
  let maskCanvas=document.createElement('canvas');
  maskCanvas.width=img.width; maskCanvas.height=img.height;
  let mctx=maskCanvas.getContext('2d');
  mctx.fillStyle='black';
  mctx.fillRect(0,0,maskCanvas.width,maskCanvas.height);
  // white where user painted
  mctx.globalCompositeOperation='lighten';
  mctx.drawImage(canvas,0,0);
  // extract only painted as white, rest black
  let imgData=ctx.getImageData(0,0,canvas.width,canvas.height);
  let origData=origCanvas.getContext('2d').getImageData(0,0,canvas.width,canvas.height).data;
  let maskData=mctx.getImageData(0,0,canvas.width,canvas.height);
  for(let i=0;i<imgData.data.length;i+=4){
    let isPainted =!(imgData.data[i]==origData[i] && imgData.data[i+1]==origData[i+1] && imgData.data[i+2]==origData[i+2]);
    if(isPainted){ maskData.data[i]=255; maskData.data[i+1]=255; maskData.data[i+2]=255; }
    else { maskData.data[i]=0; maskData.data[i+1]=0; maskData.data[i+2]=0; }
    maskData.data[i+3]=255;
  }
  mctx.putImageData(maskData,0,0);
  let maskBlob=await new Promise(r=>maskCanvas.toBlob(r,'image/png'));

  let fd=new FormData();
  fd.append('image',imageBlob,'image.png');
  fd.append('mask',maskBlob,'mask.png');
  fd.append('prompt',document.getElementById('prompt').value);

  try{
    let res=await fetch('/inpaint',{method:'POST',body:fd});
    if(!res.ok) throw new Error(await res.text());
    let blob=await res.blob();
    let url=URL.createObjectURL(blob);
    document.getElementById('result').innerHTML='<h3>Result:</h3><img src="'+url+'"><br><a href="'+url+'" download="cleaned.png"><button>Download Image</button></a>';
    document.getElementById('status').innerText='✅ Done!';
  }catch(e){
    document.getElementById('status').innerText='❌ Error: '+e.message;
  }
  document.getElementById('sendBtn').disabled=false;
}
</script>
</body>
</html>
  `);
});

// Your old API for Flutter app - keep same
app.post('/inpaint', upload.fields([{name: 'image'}, {name: 'mask'}]), async (req, res) => {
  try {
    const form = new FormData();
    form.append('image', req.files['image'][0].buffer, {filename: 'image.png'});
    form.append('mask', req.files['mask'][0].buffer, {filename: 'mask.png'});
    form.append('prompt', req.body.prompt || 'clean background, no text');

    const response = await axios.post(
      `https://api-inference.huggingface.co/models/${MODEL}`,
      form,
      {
        headers: {...form.getHeaders(), 'Authorization': `Bearer ${HF_TOKEN}` },
        responseType: 'arraybuffer'
      }
    );
    res.set('Content-Type', 'image/png');
    res.send(response.data);
  } catch (err) {
    console.error(err.response?.data?.toString() || err.message);
    res.status(500).send("HF failed - try again: "+ err.message);
  }
});

app.listen(10000, () => console.log("API running with UI"));
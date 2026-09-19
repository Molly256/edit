const express = require('express');
const multer = require('multer');
const axios = require('axios');
const FormData = require('form-data');
const cors = require('cors');

const app = express();
app.use(cors());
const upload = multer();

const HF_TOKEN = process.env.HF_TOKEN; // token lives ONLY in Render, not in code
const MODEL = "stabilityai/stable-diffusion-2-inpainting";

app.get('/', (req, res) => res.send("API is running - Canva Grab"));

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
    console.error(err.message);
    res.status(500).send("HF failed - try again");
  }
});

app.listen(10000, () => console.log("API running"));
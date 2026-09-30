'use strict';
const $ = id => document.getElementById(id);
const defaults = ['2026','2025','2024','2023','2022'];
const supportedImage = /\.(jpe?g|png|webp|gif|avif)$/i;
const safeFile = name => typeof name === 'string' && !name.startsWith('.') && !/[\/\\\u0000-\u001f]/.test(name) && supportedImage.test(name);
const photoURL = (year,name) => `/photos/${year}/${encodeURIComponent(name)}`;
async function listing(path) {
  const response = await fetch(path,{cache:'no-store'});
  if (!response.ok) throw new Error(`Unable to load gallery (${response.status}).`);
  const data = await response.json();
  if (!Array.isArray(data)) throw new Error('Invalid gallery response.');
  return data;
}
async function photos(year) {
  return (await listing(`/api/photos/${year}/`)).filter(x=>x.type==='file' && safeFile(x.name)).sort((a,b)=>a.name.localeCompare(b.name,undefined,{numeric:true}));
}
function makeAlbum(year) {
  const card = document.createElement('a'); card.className='album';card.href=`/car-shows/${year}/`;
  const cover = document.createElement('div'); cover.className='album-cover placeholder';
  const image = document.createElement('img'); image.src='/assets/cruiser.svg';image.alt='';image.loading='lazy';
  const badge=document.createElement('span');badge.textContent=year;cover.append(image,badge);
  const info=document.createElement('div');info.className='album-info';
  const text=document.createElement('div');const title=document.createElement('h3');title.textContent=`${year} Car Show`;
  const count=document.createElement('p');count.textContent='View album';text.append(title,count);
  const arrow=document.createElement('span');arrow.className='album-arrow';arrow.textContent='↗';info.append(text,arrow);card.append(cover,info);
  photos(year).then(items=>{count.textContent=items.length ? `${items.length} photos · View album` : 'Photos coming soon';if(items.length){image.src=photoURL(year,items[0].name);cover.classList.remove('placeholder');image.onerror=()=>{image.src='/assets/cruiser.svg';image.onerror=null;cover.classList.add('placeholder');};}}).catch(()=>{count.textContent='Album temporarily unavailable';});
  return card;
}
async function loadAlbums() {
  $('retry-albums').hidden=true;$('album-status').textContent='';
  let years=defaults;
  try {const entries=await listing('/api/years/');years=[...new Set([...defaults,...entries.filter(x=>x.type==='directory' && /^[0-9]{4}$/.test(x.name)).map(x=>x.name)])].sort((a,b)=>Number(b)-Number(a));}
  catch { $('album-status').textContent='Some albums could not be loaded. Please try again.';$('retry-albums').hidden=false; }
  $('albums').replaceChildren(...years.map(makeAlbum));
}
let items=[],visible=0,current=0,activeYear='';
function showMore(){const next=items.slice(visible,visible+48);for(const [offset,item] of next.entries()) {const index=visible+offset;const tile=document.createElement('button');tile.className='photo-tile';tile.setAttribute('aria-label',`Open photo ${index+1} from the ${activeYear} car show`);const img=document.createElement('img');img.src=photoURL(activeYear,item.name);img.alt=`${activeYear} car show photo ${index+1}`;img.loading='lazy';img.decoding='async';tile.append(img);tile.addEventListener('click',()=>openPhoto(index));$('photo-grid').append(tile);}visible+=next.length;$('load-more').hidden=visible>=items.length;}
function setPhoto(index){current=(index+items.length)%items.length;const url=photoURL(activeYear,items[current].name);$('viewer-image').src=url;$('viewer-image').alt=`${activeYear} car show photo ${current+1}`;$('original-photo').href=url;$('photo-counter').textContent=`${current+1} / ${items.length}`;}
function openPhoto(index){setPhoto(index);$('lightbox').showModal();}
async function loadGallery(year){activeYear=year;$('main').hidden=true;$('gallery-page').hidden=false;$('gallery-title').textContent=`${year} Car Show`;document.title=`${year} Car Show | Weevil City Cruisers`;$('photo-status').textContent='Loading photos…';$('retry-photos').hidden=true;$('load-more').hidden=true;$('photo-grid').replaceChildren();visible=0;
try{items=await photos(year);$('photo-status').textContent=items.length ? `${items.length} photos. Select a photo for a closer look.` : 'The memories are on their way. Check back soon for photos from this car show.';showMore();}catch{$('photo-status').textContent='This album is temporarily unavailable. Please try again.';$('retry-photos').hidden=false;}}
$('copyright-year').textContent=new Date().getFullYear();
$('retry-albums').addEventListener('click',loadAlbums);$('retry-photos').addEventListener('click',()=>loadGallery(activeYear));$('load-more').addEventListener('click',showMore);
$('close-viewer').addEventListener('click',()=>$('lightbox').close());$('prev-photo').addEventListener('click',()=>setPhoto(current-1));$('next-photo').addEventListener('click',()=>setPhoto(current+1));
$('lightbox').addEventListener('click',e=>{if(e.target===$('lightbox')){const r=$('lightbox').getBoundingClientRect();if(e.clientX<r.left||e.clientX>r.right||e.clientY<r.top||e.clientY>r.bottom)$('lightbox').close();}});
$('lightbox').addEventListener('keydown',e=>{if(e.key==='ArrowLeft'){e.preventDefault();setPhoto(current-1);}if(e.key==='ArrowRight'){e.preventDefault();setPhoto(current+1);}});
const match=location.pathname.match(/^\/car-shows\/([0-9]{4})\/?$/);if(match)loadGallery(match[1]);else loadAlbums();

'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {".git/COMMIT_EDITMSG": "c57025fc3463299002a9a6588d87bff2",
".git/config": "05a8f7e5f16653549f96e5da59d39e41",
".git/description": "a0a7c3fff21f2aea3cfa1d0316dd816c",
".git/HEAD": "5ab7a4355e4c959b0c5c008f202f51ec",
".git/hooks/applypatch-msg.sample": "ce562e08d8098926a3862fc6e7905199",
".git/hooks/commit-msg.sample": "e0b5b08e209fa15f48d796e8976bc42b",
".git/hooks/fsmonitor-watchman.sample": "5c90c1740b0cacecb469934e16fe8cb6",
".git/hooks/post-update.sample": "2b7ea5cee3c49ff53d41e00785eb974c",
".git/hooks/pre-applypatch.sample": "054f9ffb8bfe04a599751cc757226dda",
".git/hooks/pre-commit.sample": "5029bfab85b1c39281aa9697379ea444",
".git/hooks/pre-merge-commit.sample": "39cb268e2a85d436b9eb6f47614c3cbc",
".git/hooks/pre-push.sample": "2c642152299a94e05ea26eae11993b13",
".git/hooks/pre-rebase.sample": "56e45f2bcbc8226d2b4200f7c46371bf",
".git/hooks/pre-receive.sample": "2ad18ec82c20af7b5926ed9cea6aeedd",
".git/hooks/prepare-commit-msg.sample": "2b5c047bdb474555e1787db32b2d2fc5",
".git/hooks/push-to-checkout.sample": "c7ab00c7784efeadad3ae9b228d4b4db",
".git/hooks/sendemail-validate.sample": "4d67df3a8d5c98cb8565c07e42be0b04",
".git/hooks/update.sample": "647ae13c682f7827c22f5fc08a03674e",
".git/index": "e842641101d642564e8e783d03125509",
".git/info/exclude": "036208b4a1ab4a235d75c181e685e5a3",
".git/logs/HEAD": "6eee711f1c511d91c9c9add2d920119c",
".git/logs/refs/heads/gh-pages": "6eee711f1c511d91c9c9add2d920119c",
".git/logs/refs/remotes/origin/gh-pages": "1a460c1dda2d5f2f0578db020d25ea35",
".git/objects/00/b6ab70180ee90bd83396d82f8dab9d070c0288": "73e74aeada47409f343aa15d98818006",
".git/objects/03/102f4eec7b42f0fa0ba461bd59cfa369b740a9": "b4d3c61807ac29a84c9a4407a1b4e698",
".git/objects/06/11a5461fd2246adfb14a1042703c50c30fc56f": "17239b232c43528330a136b8e27cd05b",
".git/objects/08/804f5f26bf1eacd788f2d1ad054bdf9570257a": "072adfd3340b23358157ab461099d225",
".git/objects/0f/a5fa55fdd2e81f5f2d94fb396240ce42b0dee4": "286210dd42511fb809b0fba1bc6588f1",
".git/objects/0f/c344c7e8b9e32ea1ad91f30ded22556352d7bf": "a8a30f28869f7378465338066f34d80d",
".git/objects/0f/f13c694fa0c673f0e0db4816daf83cbe6da825": "be805c817e29876997b97fa0af8fc77a",
".git/objects/10/5b28fd633f74115db4d95313e6531edbbe903b": "34c73dcb3a159c7943ef40aadb105ca7",
".git/objects/18/eb401097242a0ec205d5f8abd29a4c5e09c5a3": "4e08af90d04a082aab5eee741258a1dc",
".git/objects/19/3558a91d91eb56b8a8e6d6b4457fc837022e12": "55180a5df323ac260f694c22b2e54da7",
".git/objects/19/c06982d9919ba7d0dc2bf3fbbb740047a1ab70": "a76f8d143dc2011edb5bed8293052e39",
".git/objects/1b/8e961a90eb71ea7c50c22375c0215a37998e1e": "14201487c388f88a7a9a8ff7c78d6380",
".git/objects/1b/fb4003a31a3fd84aef17e0c018545bc1a1a4ef": "a02ba95a893cca309b6215e4d8a04f3e",
".git/objects/1f/45b5bcaac804825befd9117111e700e8fcb782": "7a9d811fd6ce7c7455466153561fb479",
".git/objects/20/1afe538261bd7f9a38bed0524669398070d046": "82a4d6c731c1d8cdc48bce3ab3c11172",
".git/objects/20/cb2f80169bf29d673844d2bb6a73bc04f3bfb8": "b807949265987310dc442dc3f9f492a2",
".git/objects/25/8b3eee70f98b2ece403869d9fe41ff8d32b7e1": "05e38b9242f2ece7b4208c191bc7b258",
".git/objects/26/dad01d1323f1bebfaece289f6f9476683b4ec4": "d640af169b4a61e0e903d25181243501",
".git/objects/28/39e99976438e0554ed0267f72d0b97dfdefdca": "edd547cce58d9bd72d8a808969f378cc",
".git/objects/28/d97626cef4ef3adf956ade1919992106cf92d4": "a33297899fc3eb3069304d51211a7df3",
".git/objects/2a/27c06405b59fec49779444f2b2f81645838e15": "8f87f12516d1f023effda9ba264d4f19",
".git/objects/2b/4003a5b41b4ddd147bd7df2a9b3538b9dcc9fe": "c3a5e4d3d76c0f4816d93ade4366138d",
".git/objects/2f/cbab5e35548bf27c2acd71ff5079adee7a338f": "6dd2b56830423ede282bc6d037046cea",
".git/objects/33/8e7bbafcb2e39ad7f7433a784e391790aced51": "89e9e8ff0f1213b466e89d09c9a99401",
".git/objects/3d/1163ee77e65704a3d33fdbc1d2a70c5a16f195": "10fae945ea54bc483f7eb6f0bc6b3c01",
".git/objects/3f/63d6531553d65d179578521db37566683c8ca1": "06e8b1875a82db2b63b1ff0388610985",
".git/objects/46/4ab5882a2234c39b1a4dbad5feba0954478155": "2e52a767dc04391de7b4d0beb32e7fc4",
".git/objects/49/adebdb511c8c293b28db3f6792e5bac28cdc32": "ba6a3971e7f06834fd6ec3844372ce17",
".git/objects/4c/99c522e199099d3739f253c888dc578ba5120a": "aa8e34e5fc28a5be78ab43843f7e02e2",
".git/objects/4c/de902efb1a10407b44c9d1830f5473f61b834d": "6f2b9aebf3526e042852915495e02e3f",
".git/objects/58/356635d1dc89f2ed71c73cf27d5eaf97d956cd": "f61f92e39b9805320d2895056208c1b7",
".git/objects/58/b007afeab6938f7283db26299ce2de9475d842": "6c6cbea527763bb3cdff2cecfee91721",
".git/objects/59/eddf0908705a2c6e262bf3476a74938cd55584": "916d2f9b6c99cd0fe7b8d0b2cdfb9252",
".git/objects/5d/9cd1e091c050da2e0c62249f8aced82d2a98f5": "8e89468d94ee444a64769a51ab035eac",
".git/objects/5e/40d10ef53a296796ce639c28a3991b975dba75": "25b6770390166aef34f9e3ab04ec6c34",
".git/objects/60/3f5dcc8e0196d8e3c4efd9cac6eb6327df23b4": "466a6b83efb2b01d5b38150867bb1d35",
".git/objects/62/c89ee094658c7a9465824fdb42793a64ea557b": "133cd5da638f245b079d9e9cdc29ae38",
".git/objects/64/0447807bd55c70c4744d2a85f7bbf5f3c03755": "eb9f8d250cb97a9615ed513cb70efb44",
".git/objects/65/d289e491a5df7463af549b8d96e9ebac691ab0": "d97f89d2b1e0357056146e8ccd011cc2",
".git/objects/66/17025528e75a559f6c49fb983a724539b69f1d": "1a95d82e5ab18c9affd9e1dcdc16260b",
".git/objects/6a/21972ad469b152f0f989ae2b4ef0ea1ed18a8d": "da9f3342283261257e173721ab6ed523",
".git/objects/6a/eae3931cbe4cf2108869b57c7b7de14921bc90": "c36db81d41ef9f904b251a5c1c041cd8",
".git/objects/6d/3f79093720f151bf1e7ef5ec953e21e298c7e4": "1cf5997ae766504105ee4b0c9c7e2ed8",
".git/objects/6f/e281faa177d8d0adae785c2e1709cd56b76906": "9188bfb028101245cf0d250b9bcaf324",
".git/objects/71/3f932c591e8f661aa4a8e54c32c196262fd574": "66c6c54fbdf71902cb7321617d5fa33c",
".git/objects/72/31c968122fa1a8b8cbe18ca746fa786cdd1be7": "2860c804d5ae3c634bb73ee9be9aac31",
".git/objects/76/d09dc735f4dff3e66814d76acb7e1caff70621": "7554c1172181a688c1b18a6ff9c79210",
".git/objects/7b/a9d24b39196cd5a8b401df4f773c568cb0271c": "ad0e919e06b7d2dd01235e6f4072dc8c",
".git/objects/7b/b35269e81857fa7a7ed4695e62d1b4f951724d": "fb90e89d7c4db67a307d2fa304c7eacb",
".git/objects/7d/93028e2a15793250e11c4db35cc1989f6cd7dc": "a4caa0e2bab133cca78f9c06f6a67fb0",
".git/objects/85/6a39233232244ba2497a38bdd13b2f0db12c82": "eef4643a9711cce94f555ae60fecd388",
".git/objects/88/cfd48dff1169879ba46840804b412fe02fefd6": "e42aaae6a4cbfbc9f6326f1fa9e3380c",
".git/objects/89/35f5f0f6c16f521fd1791342769631aaa58559": "d7947184dad089602b09a80e1fd8097e",
".git/objects/8a/aa46ac1ae21512746f852a42ba87e4165dfdd1": "1d8820d345e38b30de033aa4b5a23e7b",
".git/objects/8a/b4938c0109634ddccd52548db13b1de89344e5": "5f28dbc341ec18c2576907ee1898cdc4",
".git/objects/8c/f79dc34420157eed7b7c8ba20717ca66d4efac": "2e9c5baa28673ced44f470acc131bfec",
".git/objects/8f/7baeea44e44c8c7e1127379f296ce96e0cfcec": "ce8d86288e7f83b087ebac703b288200",
".git/objects/94/a202ae2ee7779b2b330248114fed30999ad6eb": "043598996ef36697ec6c58daef7407cd",
".git/objects/94/f7d06e926d627b554eb130e3c3522a941d670a": "77a772baf4c39f0a3a9e45f3e4b285bb",
".git/objects/9a/cea0aaabbe96ca0ec9c1939b9e5f8159985ee7": "560fa88041fe12cb095e22d34b449183",
".git/objects/a5/9b1fcc2887ed04069ea458981546c0c206fde7": "79cec142512605094c81cc5c8410f233",
".git/objects/ae/349587cb964c02705d67fcec1e34a83daae605": "27c9f532d2bed9c492851d3d707ca923",
".git/objects/b3/ebbd38f666d4ffa1a394c5de15582f9d7ca6c0": "23010709b2d5951ca2b3be3dd49f09df",
".git/objects/b6/7042de98e1973275f82a39c5a3124af6d1876f": "ef2ad6fa090cb28502b69a4a81f1c1ca",
".git/objects/b7/49bfef07473333cf1dd31e9eed89862a5d52aa": "36b4020dca303986cad10924774fb5dc",
".git/objects/b9/2a0d854da9a8f73216c4a0ef07a0f0a44e4373": "f62d1eb7f51165e2a6d2ef1921f976f3",
".git/objects/ba/5317db6066f0f7cfe94eec93dc654820ce848c": "9b7629bf1180798cf66df4142eb19a4e",
".git/objects/c2/df44a6b46b0768d0abdd182cf9a15f8d368735": "7b131ca75a19abf743c1f345513e3288",
".git/objects/c4/edf1e70292e9e3fd03c958b66ea96021e6c167": "bec76d06f8d1b69fa5ba45e6a211ee4d",
".git/objects/c6/0687ad9027fe75a8093682cf54da227e0ebcd6": "9e1291abc8c2e3c4a066572d4479af4b",
".git/objects/c6/57e02dcfbd21ab6db9427a8ea81c98d4f98399": "d5219a658f4c009225dbb87813659279",
".git/objects/c6/819a353164411bc6d92ac6272df46c94cd82df": "e406c8c396b966f6266f35715903b65d",
".git/objects/c9/bf8af1b92c723b589cc9afadff1013fa0a0213": "632f11e7fee6909d99ecfd9eeab30973",
".git/objects/d1/098e7588881061719e47766c43f49be0c3e38e": "f17e6af17b09b0874aa518914cfe9d8c",
".git/objects/d1/f838918d6eeb47b869d4e87fe3ed095d1ed19e": "2a3c5a360c6b880345b1817dd96b4033",
".git/objects/d3/49920b612c1c820850530681d332754e242097": "171c99de58fe645cc60892c7fe57ed88",
".git/objects/d4/3532a2348cc9c26053ddb5802f0e5d4b8abc05": "3dad9b209346b1723bb2cc68e7e42a44",
".git/objects/d6/9c56691fbdb0b7efa65097c7cc1edac12a6d3e": "868ce37a3a78b0606713733248a2f579",
".git/objects/da/4d2d70140d3ca7badf8cca93a1ade33c8a3f83": "41515e733d299ab1e5041a325e587a5a",
".git/objects/da/904ec45ac0334627bc4a41e3b37790c6b8a1dd": "01b45ab3138e69de89e56cd7fa79f99e",
".git/objects/de/bc2a4cc74fdca0ad1839145efc1275fe5f1a95": "ac7433c8278eab1effac913a3c25ad90",
".git/objects/de/e6b793dbee2db75c52bea4570af2e07739bb3c": "d1b79958f7e5e17bb2408a6ff2a9fe72",
".git/objects/e0/2b3af0202f47426149e866bb0ae8ef2f18d795": "1b76d4a8e8bb279678fa74c3dca43309",
".git/objects/e5/7e7f4a5f09abc93a9eaa454b2ac90e9a290e69": "91e18973294324ad3c44bd6911704e0a",
".git/objects/e6/16565d711534231185dc1a2970145142f5a9fb": "12114d0c84000357a06d8ee9853b7f48",
".git/objects/ea/5e60cf0a6e6e1944634506a516352c95624705": "27dec2c95659893fce2dea0ac024854e",
".git/objects/eb/9b4d76e525556d5d89141648c724331630325d": "37c0954235cbe27c4d93e74fe9a578ef",
".git/objects/f1/d13e3b31a2147fc4e05ad24a17248d4cf5f548": "3656c1b9c6ec30543d6b766a6a60eae4",
".git/objects/f2/04823a42f2d890f945f70d88b8e2d921c6ae26": "6b47f314ffc35cf6a1ced3208ecc857d",
".git/objects/fa/efa3cfb2d896ace6886fa7e8cfcb56f4bb8c76": "0c9ca74850f7155d570ed39ec8e1949f",
".git/refs/heads/gh-pages": "3bb678cf1cef2e079753c21174a638a0",
".git/refs/remotes/origin/gh-pages": "3bb678cf1cef2e079753c21174a638a0",
"assets/AssetManifest.bin": "6bf5dc1f9d6c0fba48b4c03c3cd2c81f",
"assets/AssetManifest.bin.json": "86dc020fbd5d26bf98b0e2d854baeb7e",
"assets/AssetManifest.json": "2d847b683bbdf4e3f579744b99bbc093",
"assets/assets/materials_db.json": "8ed95534e01945b749b1073588a8b902",
"assets/assets/weldprice_icon.png": "3cf7a8f9e68f5d5d5030ee09d0dab575",
"assets/FontManifest.json": "dc3d03800ccca4601324923c0b1d6d57",
"assets/fonts/MaterialIcons-Regular.otf": "fe5c324e05ab76f58c73e903d88ff838",
"assets/NOTICES": "b037a0b6eb2c31286aa599456b2710c9",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "e986ebe42ef785b27164c36a9abc7818",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"canvaskit/canvaskit.js": "738255d00768497e86aa4ca510cce1e1",
"canvaskit/canvaskit.js.symbols": "74a84c23f5ada42fe063514c587968c6",
"canvaskit/canvaskit.wasm": "9251bb81ae8464c4df3b072f84aa969b",
"canvaskit/chromium/canvaskit.js": "901bb9e28fac643b7da75ecfd3339f3f",
"canvaskit/chromium/canvaskit.js.symbols": "ee7e331f7f5bbf5ec937737542112372",
"canvaskit/chromium/canvaskit.wasm": "399e2344480862e2dfa26f12fa5891d7",
"canvaskit/skwasm.js": "5d4f9263ec93efeb022bb14a3881d240",
"canvaskit/skwasm.js.symbols": "c3c05bd50bdf59da8626bbe446ce65a3",
"canvaskit/skwasm.wasm": "4051bfc27ba29bf420d17aa0c3a98bce",
"canvaskit/skwasm.worker.js": "bfb704a6c714a75da9ef320991e88b03",
"favicon.png": "3cf7a8f9e68f5d5d5030ee09d0dab575",
"flutter.js": "383e55f7f3cce5be08fcf1f3881f585c",
"flutter_bootstrap.js": "420af8ce404676cdd3447b60560589c6",
"icons/Icon-192.png": "3cf7a8f9e68f5d5d5030ee09d0dab575",
"icons/Icon-512.png": "3cf7a8f9e68f5d5d5030ee09d0dab575",
"icons/Icon-maskable-192.png": "3cf7a8f9e68f5d5d5030ee09d0dab575",
"icons/Icon-maskable-512.png": "3cf7a8f9e68f5d5d5030ee09d0dab575",
"index.html": "0bd9c5c69abacfdf8d2d48afd07124a8",
"/": "0bd9c5c69abacfdf8d2d48afd07124a8",
"main.dart.js": "b4c77a6efe5415a92fe365c588f077e7",
"manifest.json": "761f2e83ef15e546a53b632324cfd828",
"version.json": "b2bf0bca6813bf4c115206290a4c870b"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"flutter_bootstrap.js",
"assets/AssetManifest.bin.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});
// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        // Claim client to enable caching on first launch
        self.clients.claim();
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      // Claim client to enable caching on first launch
      self.clients.claim();
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});
// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});
self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});
// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}

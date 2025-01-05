function goFullScreen(){
  var canvas = document.getElementById("canvas");
  if(canvas.requestFullScreen)
    canvas.requestFullScreen();
  else if(canvas.webkitRequestFullScreen)
    canvas.webkitRequestFullScreen();
  else if(canvas.mozRequestFullScreen)
    canvas.mozRequestFullScreen();
}
function updateContainerSize() {
  var canvas = document.getElementById("canvas");
  var loadingCanvas = document.getElementById("loadingCanvas");
  var container = document.getElementById("game-container");
  
  var width = window.innerWidth || document.documentElement.clientWidth || document.body.clientWidth;
  var height = window.innerHeight || document.documentElement.clientHeight || document.body.clientHeight;
  
  // Calculate container size maintaining 4:3 ratio
  var containerWidth = Math.min(width - 32, 896);
  var containerHeight = containerWidth * (3/4);
  
  // If too tall, recalculate based on height
  if (containerHeight > height - 32) {
    containerHeight = height - 32;
    containerWidth = containerHeight * (4/3);
  }
  
  // Update container and canvases
  container.style.width = containerWidth + 'px';
  container.style.height = containerHeight + 'px';
  canvas.width = containerWidth;
  canvas.height = containerHeight;
  loadingCanvas.width = containerWidth;
  loadingCanvas.height = containerHeight;
}

// Handle regular resizing
window.addEventListener('resize', function() {
  if (!document.fullscreenElement) {
    updateContainerSize();
  }
});

// Initial size
updateContainerSize();
function FullScreenHook(){
  var canvas = document.getElementById("canvas");
  canvas.width = window.innerWidth || document.documentElement.clientWidth || document.body.clientWidth;
  canvas.height = window.innerHeight || document.documentElement.clientHeight || document.body.clientHeight;
}

var loadingContext = document.getElementById('loadingCanvas').getContext('2d');
function drawLoadingText(text) {
  var canvas = loadingContext.canvas;
  loadingContext.fillStyle = "rgb(142, 195, 227)";
  loadingContext.fillRect(0, 0, canvas.scrollWidth, canvas.scrollHeight);
  loadingContext.font = '2em arial';
  loadingContext.textAlign = 'center'
  loadingContext.fillStyle = "rgb( 11, 86, 117 )";
  loadingContext.fillText(text, canvas.scrollWidth / 2, canvas.scrollHeight / 2);
  loadingContext.fillText("Powered By Emscripten.", canvas.scrollWidth / 2, canvas.scrollHeight / 4);
  loadingContext.fillText("Powered By LÖVE.", canvas.scrollWidth / 2, canvas.scrollHeight / 4 * 3);
}

window.onload = function () { window.focus(); };
window.onclick = function () { window.focus(); };

window.addEventListener("keydown", function(e) {
  // space and arrow keys
  if([32, 37, 38, 39, 40].indexOf(e.keyCode) > -1) {
    e.preventDefault();
  }
}, false);

// Add window resize handler
window.addEventListener('resize', FullScreenHook);

var Module = {
  arguments: ["./"],
  INITIAL_MEMORY: 16777216,
  printErr: console.error.bind(console),
  canvas: (function() {
    var canvas = document.getElementById('canvas');
    canvas.addEventListener("webglcontextlost", function(e) { 
      alert('WebGL context lost. You will need to reload the page.'); 
      e.preventDefault(); 
    }, false);
    return canvas;
  })(),
  setStatus: function(text) {
    if (text) {
      drawLoadingText(text);
    } else if (Module.remainingDependencies === 0) {
      document.getElementById('loadingCanvas').style.display = 'none';
      document.getElementById('canvas').style.visibility = 'visible';
    }
  },
  totalDependencies: 0,
  remainingDependencies: 0,
  monitorRunDependencies: function(left) {
    this.remainingDependencies = left;
    this.totalDependencies = Math.max(this.totalDependencies, left);
    Module.setStatus(left ? 'Preparing... (' + (this.totalDependencies-left) + '/' + this.totalDependencies + ')' : 'All downloads complete.');
  }
};

Module.setStatus('Downloading...');
window.onerror = function(event) {
  Module.setStatus('Exception thrown, see JavaScript console');
  Module.setStatus = function(text) {
    if (text) Module.printErr('[post-exception status] ' + text);
  };
};

var applicationLoad = function(e) {
  Love(Module);
}

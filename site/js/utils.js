function updateContainerSize() {
  var canvas = document.getElementById("canvas");
  var loadingCanvas = document.getElementById("loadingCanvas");
  var container = document.getElementById("game-container");

  // In fullscreen, fill the screen
  if (
    document.fullscreenElement ||
    document.webkitFullscreenElement ||
    document.mozFullScreenElement
  ) {
    var w = window.innerWidth;
    var h = window.innerHeight;
    canvas.width = w;
    canvas.height = h;
    loadingCanvas.width = w;
    loadingCanvas.height = h;
    return;
  }

  var width = container.clientWidth;
  var height = container.clientHeight;

  canvas.width = width;
  canvas.height = height;
  loadingCanvas.width = width;
  loadingCanvas.height = height;
}

window.addEventListener("resize", updateContainerSize);
document.addEventListener("fullscreenchange", updateContainerSize);
document.addEventListener("webkitfullscreenchange", updateContainerSize);
document.addEventListener("mozfullscreenchange", updateContainerSize);

// Initial size
updateContainerSize();

var loadingContext = document.getElementById("loadingCanvas").getContext("2d");
function drawLoadingText(text) {
  var canvas = loadingContext.canvas;
  loadingContext.fillStyle = "rgb(142, 195, 227)";
  loadingContext.fillRect(0, 0, canvas.scrollWidth, canvas.scrollHeight);
  loadingContext.font = "2em arial";
  loadingContext.textAlign = "center";
  loadingContext.fillStyle = "rgb(11, 86, 117)";
  loadingContext.fillText(
    text,
    canvas.scrollWidth / 2,
    canvas.scrollHeight / 2,
  );
}

window.onload = function () {
  window.focus();
};
window.onclick = function () {
  window.focus();
};

window.addEventListener(
  "keydown",
  function (e) {
    if ([32, 37, 38, 39, 40].indexOf(e.keyCode) > -1) {
      e.preventDefault();
    }
  },
  false,
);

var Module = {
  arguments: ["./"],
  INITIAL_MEMORY: 16777216,
  printErr: console.error.bind(console),
  canvas: (function () {
    var canvas = document.getElementById("canvas");
    canvas.addEventListener(
      "webglcontextlost",
      function (e) {
        alert("WebGL context lost. You will need to reload the page.");
        e.preventDefault();
      },
      false,
    );
    return canvas;
  })(),
  setStatus: function (text) {
    if (text) {
      drawLoadingText(text);
    } else if (Module.remainingDependencies === 0) {
      document.getElementById("loadingCanvas").style.display = "none";
      document.getElementById("canvas").style.visibility = "visible";
    }
  },
  totalDependencies: 0,
  remainingDependencies: 0,
  monitorRunDependencies: function (left) {
    this.remainingDependencies = left;
    this.totalDependencies = Math.max(this.totalDependencies, left);
    Module.setStatus(
      left
        ? "Preparing... (" +
            (this.totalDependencies - left) +
            "/" +
            this.totalDependencies +
            ")"
        : "All downloads complete.",
    );
  },
};

Module.setStatus("Downloading...");
window.onerror = function (event) {
  Module.setStatus("Exception thrown, see JavaScript console");
  Module.setStatus = function (text) {
    if (text) Module.printErr("[post-exception status] " + text);
  };
};

var applicationLoad = function (e) {
  Love(Module);
};

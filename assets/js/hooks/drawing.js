let canvas;
let context;
let container;
let isDrawing = false;
let points = []
let animationFrameRequestId;
let yourColor;
let liveComponentId;

const init = () => {
  container = document.getElementById('canvas-container')
  canvas = document.getElementById('canvas');
  context = canvas.getContext('2d');
  liveComponentId = container.getAttribute('data-live-component-id')

  yourColor = container.getAttribute('data-your-color')

  context.lineCap = 'round'
  context.lineJoin = 'round'

  canvas.width = 780;
  canvas.height = 490;
  context.lineWidth = 2;
}

const startDrawing = (e) => {
  const yourTurn = container.hasAttribute('data-your-turn')

  if (!yourTurn) {
    return
  }

  if (points.length) {
    return
  }

  isDrawing = true;
  context.strokeStyle = yourColor

  const rect = canvas.getBoundingClientRect();
  points.push({ x: Math.floor(e.clientX - rect.left), y: Math.floor(e.clientY - rect.top) });
}

const draw = (e) => {
  if (!isDrawing) {
    return
  }

  const rect = canvas.getBoundingClientRect();

  var x = e.clientX - rect.left;
  var y = e.clientY - rect.top;

  points.push({ x: Math.floor(x), y: Math.floor(y) })
}

const stopDrawing = () => {
  isDrawing = false;
}

const loop = () => {
  if (isDrawing) {
    render()
  }

  animationFrameRequestId = requestAnimationFrame(loop)
}


const drawLine = ({ color, points }) => {
  if (!points?.length) {
    return
  }

  context.strokeStyle = color

  context.beginPath()
  context.moveTo(points[0].x, points[0].y)

  points.forEach((point) => {
    const xMid = (point.x + point.x) / 2;
    const yMid = (point.y + point.y) / 2;
    const cpX1 = (xMid + point.x) / 2;
    const cpX2 = (xMid + point.x) / 2;
    context.quadraticCurveTo(cpX1, point.y, xMid, yMid);
    context.quadraticCurveTo(cpX2, point.y, point.x, point.y);
  })
  context.stroke()
}

const render = () => {
  context.clearRect(0, 0, canvas.width, canvas.height);

  const drawing = JSON.parse(container.getAttribute('data-drawing'))
  drawing.forEach(line => {
    drawLine({
      color: line.color,
      points: line.points
    })
  })

  drawLine({
    color: yourColor,
    points
  })
}


module.exports.drawing = {
  mounted() {
    init()

    canvas.onmousedown = startDrawing;
    canvas.onmouseup = () => {
      stopDrawing();
      this.pushEventTo(liveComponentId, "line_complete", { points })
    }
    canvas.onmousemove = draw;

    render()

    loop()
  },
  updated() {
    const line = JSON.parse(container.getAttribute('data-line'))
    points = line.points ?? []

    render()
  },
  destroyed() {
    if (animationFrameRequestId) {
      cancelAnimationFrame(animationFrameRequestId)
    }

    canvas.onmousedown = null
    canvas.onmouseup = null
    canvas.onmousemove = null
  }
}
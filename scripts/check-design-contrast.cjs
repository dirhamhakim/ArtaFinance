const fs = require('node:fs');
const path = require('node:path');
const tokens = JSON.parse(fs.readFileSync(path.join(__dirname, '../docs/design/tokens.json'), 'utf8'));

function luminance(hex) {
  const channels = hex.slice(1).match(/.{2}/g).map(value => parseInt(value, 16) / 255);
  const [r, g, b] = channels.map(value => value <= 0.04045 ? value / 12.92 : ((value + 0.055) / 1.055) ** 2.4);
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

function contrast(a, b) {
  const values = [luminance(a), luminance(b)].sort((x, y) => y - x);
  return (values[0] + 0.05) / (values[1] + 0.05);
}

let failures = 0;
let pairs = 0;
const minimums = {};
for (const mode of ['light', 'dark']) {
  minimums[mode] = { text: Infinity, chart: Infinity, control: Infinity };
  const check = (category, name, foreground, background, minimum) => {
    const ratio = contrast(foreground, background);
    pairs++;
    minimums[mode][category] = Math.min(minimums[mode][category], ratio);
    if (ratio < minimum) {
      failures++;
      console.error(`${mode} ${name}: ${ratio.toFixed(2)}:1, requires ${minimum}:1`);
    }
  };
  for (const background of ['background', 'surface', 'surfaceRaised', 'sheet']) {
    for (const foreground of ['textPrimary', 'textSecondary', 'accent', 'positive', 'negative', 'warning', 'info']) {
      check('text', `${foreground}/${background}`, tokens.colors[foreground][mode], tokens.colors[background][mode], 4.5);
    }
    check('control', `controlBorder/${background}`, tokens.colors.controlBorder[mode], tokens.colors[background][mode], 3);
    tokens.chartSeries[mode].forEach((color, index) => check('chart', `series${index + 1}/${background}`, color, tokens.colors[background][mode], 3));
  }
  check('text', 'onAccent/action', tokens.colors.onAccent[mode], tokens.colors.action[mode], 4.5);
}

console.log(JSON.stringify({ pairsChecked: pairs, failures, minimumContrast: minimums }, null, 2));
console.log('Decorative dividers/grid, alpha fills, overlays and disabled states require separate visual review in FigCraft.');
process.exitCode = failures ? 1 : 0;

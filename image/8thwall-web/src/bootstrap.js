// Keep startup failures visible even when the main module or its dependencies fail.
const showStartupError = message => {
  document.querySelector('#status').textContent = 'Demo startup failed'
  document.querySelector('#detail').textContent = `${message}. Restart with npm start, then reload this page.`
}
import('./capture.js').then(()=>import('./main.js')).catch(error => showStartupError(error.message))
window.addEventListener('error', event => {
  if (event.target?.tagName === 'SCRIPT') showStartupError('An engine or application script could not be loaded')
}, true)

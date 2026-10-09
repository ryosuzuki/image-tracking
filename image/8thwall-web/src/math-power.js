export function isShiftedPower(expression){return expression.replace(/\s+/g,'')==='(x+h)^n+k'}
export function explicitGraphFamily(expression){return expression.replace(/\s+/g,'')==='(x+h)^2+k'?'quadratic':isShiftedPower(expression)?'power':'function'}

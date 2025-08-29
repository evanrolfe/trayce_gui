const f = require('faker');

function whatsMyName() {
  // return 'Evan';
  return f.name.firstName();
}

module.exports = {
  whatsMyName,
};

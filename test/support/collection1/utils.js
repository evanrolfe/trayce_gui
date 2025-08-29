const f = require('faker');
const { v4: uuidv4 } = require('uuid');

function whatsMyName() {
  // return 'Evan';
  return uuidv4();
}

module.exports = {
  whatsMyName,
};

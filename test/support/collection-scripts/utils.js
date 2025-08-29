const f = require('faker');
const { v4: uuidv4 } = require('uuid');

function whatsMyName() {
  // return 'Evan';
  return f.name.firstName() + ' ' + uuidv4();
}

module.exports = {
  whatsMyName,
};

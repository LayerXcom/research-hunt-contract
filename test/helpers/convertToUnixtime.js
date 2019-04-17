function convertToUnixtime(time) {
  return Math.round(time.getTime() / 1000);
}

module.exports = {
  convertToUnixtime,
}

function isUploadedThisMonth(date) {
  const now = Date.now();
  const _MS_PER_DAY = 1000 * 60 * 60 * 24;
  const diff = Math.ceil((now - date) / _MS_PER_DAY);
  return diff <= 30;
}

module.exports = { isUploadedThisMonth };

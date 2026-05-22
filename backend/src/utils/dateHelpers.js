const WEEKDAYS = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
const MONTHS = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

function formatDueDateDisplay(isoDate) {
  const date = new Date(`${isoDate}T00:00:00.000Z`);
  const weekday = WEEKDAYS[date.getUTCDay()];
  const month = MONTHS[date.getUTCMonth()];
  const day = date.getUTCDate();
  const year = date.getUTCFullYear();
  return `Due ${weekday} ${month} ${day} ${year}`;
}

module.exports = {
  formatDueDateDisplay,
};

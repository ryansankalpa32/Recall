/**
 * Local wall-clock ↔ UTC conversion using the runtime's IANA tz database
 * (`Intl`), so every zone works, including DST transitions. No dependencies.
 *
 * Kept free of Firebase imports so it can be unit-tested without credentials.
 */

const LOCAL_DATETIME_RE =
  /^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})$/;

/** Throws a RangeError if `timeZone` is not a valid IANA zone. */
export function assertValidTimeZone(timeZone: string): void {
  new Intl.DateTimeFormat("en-US", { timeZone });
}

/** Offset of `timeZone` from UTC at instant `date`, in milliseconds. */
function zoneOffsetMs(timeZone: string, date: Date): number {
  const parts = new Intl.DateTimeFormat("en-US", {
    timeZone,
    hourCycle: "h23",
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
    hour: "2-digit",
    minute: "2-digit",
    second: "2-digit",
  }).formatToParts(date);
  const get = (type: string) =>
    Number(parts.find((p) => p.type === type)?.value);
  const asUtc = Date.UTC(
    get("year"),
    get("month") - 1,
    get("day"),
    get("hour"),
    get("minute"),
    get("second"),
  );
  // Drop sub-second precision from the instant before comparing.
  return asUtc - Math.floor(date.getTime() / 1000) * 1000;
}

/**
 * Interprets `datetime` (ISO-8601 local wall-clock, no offset, no `Z`, e.g.
 * `2026-09-25T15:00:00`) in `timeZone` and returns the matching UTC instant.
 *
 * A wall-clock time that does not exist (skipped by a DST spring-forward)
 * resolves to the instant just after the gap, which is what a reminder
 * should do.
 */
export function localWallClockToUtc(datetime: string, timeZone: string): Date {
  const m = LOCAL_DATETIME_RE.exec(datetime);
  if (!m) {
    throw new Error(`Invalid local datetime: ${datetime}`);
  }
  assertValidTimeZone(timeZone);

  const [, y, mo, d, h, mi, s] = m.map(Number);
  const wallAsUtc = Date.UTC(y, mo - 1, d, h, mi, s);

  // First guess with the offset at the wall-clock instant, then correct once
  // with the offset at the guessed instant (handles DST boundaries).
  let utc = wallAsUtc - zoneOffsetMs(timeZone, new Date(wallAsUtc));
  utc = wallAsUtc - zoneOffsetMs(timeZone, new Date(utc));
  return new Date(utc);
}

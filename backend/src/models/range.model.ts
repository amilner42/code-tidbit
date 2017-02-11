/// Module for encapsulating helper functions for the range model.


/**
 * A range represents a range from the ACE API.
 */
export interface Range {
  startRow: number;
  startCol: number;
  endRow: number;
  endCol: number;
}

/**
 * Checks if a range is empty.
 *
 * @returns True if range is empty or null.
 */
export const emptyRange = (range: Range): boolean => {
  if(!range) {
    return true;
  }

  return (range.startRow === range.endRow) && (range.startCol === range.endCol);
};

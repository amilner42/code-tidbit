/// Module for making augmentations to the global namespace.

export {}; // One import/export needed.

declare global {

  /**
   * Returns true if `thing` is `null` or `undefined`.
   */
  type isNullOrUndefined = (thing: any) => boolean;
}

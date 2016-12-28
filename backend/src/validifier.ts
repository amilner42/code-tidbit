/// Module for encapsulating all validation logic and helpers.

import { isNullOrUndefined } from './util';


/**
 * Regex for superficially valid phone number.
 *
 * @credit: http://stackoverflow.com/questions/6478875/regular-expression-matching-e-164-formatted-phone-numbers
 */
export const validPhone = (phoneNumber: string) => /^\+?[1-9]\d{1,14}$/.test(phoneNumber);

/**
 * Regex for superficially valid email.
 *
 * @credit: http://stackoverflow.com/questions/46155/validate-email-address-in-javascript
 */
export const validEmail = (email: string) => /^(([^<>()\[\]\\.,;:\s@"]+(\.[^<>()\[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/.test(email);


/**
 * Checks that a password is considered "strong" enough.
 *
 * Currently we only require 6-char passwords.
 */
export const validPassword = (password: string) => {
  return !(isNullOrUndefined(password)) && (password.length > 6);
}

/**
 * Checks if an id is a valid mongo ID.
 *
 * Currently only checking 24 hex chars.
 */
export const validMongoID = (id: string = ""): boolean => {
  return /^[0-9a-fA-F]{24}$/.test(id);
}

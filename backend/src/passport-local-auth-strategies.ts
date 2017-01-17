/// Module for all `passport-local` authentication strategies.

import { compareSync, genSaltSync, hashSync } from 'bcryptjs';
import { Strategy } from 'passport-local';
import * as kleen from "kleen";

import { collection } from './db';
import { validEmail, validPassword } from './validifier';
import { ErrorCode } from './types';
import { User } from "./models/user.model";


/**
 * Passport default username field is "username", we use "email".
 */
const usernameField = "email";

/**
 * Check if a password is correct for a user.
 *
 * @param user User in database
 * @param password Password for user (string)
 * @return boolean, true if correct
 */
const correctPassword = (user, password) => {
  return compareSync(password, user.password);
};

/**
 * Register a new user.
 *
 * @required email Email does not exist
 * @param email Unique email for user
 * @param password Password for user
 * @return Promise for the user
 */
const register = (email, password): Promise<User> => {
  const salt = genSaltSync(10);
  const passwordAsHash = hashSync(password, salt);
  const user = {
    email: email,
    password: passwordAsHash
  };

  return collection('users')
  .then((Users) => Users.save(user))
  .then(() => user);
};


/**
 * Standard login strategy, rejects with approprite error code if needed.
 */
export const loginStrategy: Strategy = new Strategy({ usernameField }, (email, password, next) => {

  let retrievedUser: User; // to avoid multiple queries to db for the user.

  /**
   * The user login structure.
   */
  const userLoginStructure: kleen.objectSchema = {
    objectProperties: {
      email: {
        primitiveType: kleen.kindOfPrimitive.string,
        typeFailureError: {
          message: "Email must be a string!",
          errorCode: ErrorCode.internalError
        }
      },
      password: {
        primitiveType: kleen.kindOfPrimitive.string,
        typeFailureError: {
          message: "Password must be a string",
          errorCode: ErrorCode.internalError
        }
      }
    },
    restriction: (user: {email: string, password: string}) => {

      return new Promise<void>((resolve, reject) => {

        user.email = user.email.toLowerCase();

        return collection('users')
        .then((Users) => {
          return (Users.findOne({ email: user.email }) as Promise<User>);
        })
        .then((userInDB) => {
          if(!userInDB) {
            reject({
              message: "No account exists for that email address",
              errorCode: ErrorCode.noAccountExistsForEmail
            });
          }

          return userInDB;
        })
        .then((userInDB) => {
          if(!correctPassword(userInDB, user.password)) {
            reject({
              message: "Incorrect password for that email address",
              errorCode: ErrorCode.incorrectPasswordForEmail
            });
          }
          retrievedUser = userInDB; // save the user to outer block scope
          resolve();
        });
      });
    },
    typeFailureError: {
      message: "User object must have a email and password.",
      errorCode: ErrorCode.internalError
    }
  };

  kleen.validModel(userLoginStructure)({email, password})
  .then(() => {
    return next(null, retrievedUser);
  })
  .catch((err) => {
    // custom error
    if(err.errorCode) {
      return next(null, false, err);
    }
    // internal error
    return next(err);
  });
});


/**
 * Standard sign-up strategy, rejects with approprite error code if needed.
 */
export const signUpStrategy: Strategy = new Strategy({ usernameField }, (email, password, next) => {

  /**
   * The user signup structure.
   */
  const userSignUpStructure: kleen.objectSchema = {
    objectProperties: {
      email: {
        primitiveType: kleen.kindOfPrimitive.string,
        typeFailureError: {
          message: "Email must be a string",
          errorCode: ErrorCode.invalidEmail
        },
        restriction: (email: string) => {

          return new Promise<void>((resolve, reject) => {

            email = email.toLowerCase();

            if(!validEmail(email)) {
              reject({
                message: "Invalid email",
                errorCode: ErrorCode.invalidEmail
              });
              return;
            }

            return collection('users')
            .then((Users) => {
              return Users.findOne({ email });
            })
            .then((user) => {
              if(user) {
                reject({
                  message: "Email address already registered",
                  errorCode: ErrorCode.emailAddressAlreadyRegistered
                });
                return;
              }

              resolve();
              return;
            });
          });
        }
      },
      password: {
        primitiveType: kleen.kindOfPrimitive.string,
        typeFailureError: {
          message: "Password must be a string",
          errorCode: ErrorCode.invalidPassword
        },
        restriction: (password: string) => {
          if(!validPassword(password)) {
            return Promise.reject({
              message: 'Password not strong enough',
              errorCode: ErrorCode.invalidPassword
            });
          }
        }
      }
    },
    typeFailureError: {
      message: "User object must have an email and password",
      errorCode: ErrorCode.internalError
    }
  };

  return kleen.validModel(userSignUpStructure)({ email, password })
  .then(() => {
    return register(email, password);
  })
  .then((user) => {
    return next(null, user);
  })
  .catch((err) => {
    // custom error.
    if(err.errorCode) {
      return next(null, false, err);
    }
    // internal error
    return next(err);
  });
});

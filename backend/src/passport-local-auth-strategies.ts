/// Module for all `passport-local` authentication strategies.

import { compareSync, genSaltSync, hashSync } from 'bcryptjs';
import { Strategy } from 'passport-local';
import * as kleen from "kleen";

import { internalError } from './util';
import { collection } from './db';
import { validEmail, validPassword } from './validifier';
import { ErrorCode } from './types';
import { User, UserForLogin, UserForRegistration } from "./models/user.model";


/**
 * Passport default username field is "username", we use "email".
 */
const usernameField = "email";

/**
 * Check if a password is correct for a user.
 *
 * @param user User from database
 * @param password Password for user
 * @return boolean, true if correct
 */
const correctPassword = (user: User, password: string) => {
  return compareSync(password, user.password);
};

/**
 * Register a new user.
 *
 * @required Email does not exist, this function doesn't check that.
 */
const register = (user: UserForRegistration): Promise<User> => {
  const salt = genSaltSync(10);
  // Bcrypt user's password.
  user.password = hashSync(user.password, salt);

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
        typeFailureError: internalError("Email must be a string!")
      },
      password: {
        primitiveType: kleen.kindOfPrimitive.string,
        typeFailureError: internalError("Password must be a string")
      }
    },
    restriction: (user: UserForLogin) => {

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
            return;
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
    typeFailureError: internalError("User object must have just email and password.")
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
export const signUpStrategy: Strategy = new Strategy(
  { usernameField, passReqToCallback: true },
  (req, email, password, next) => {
    /**
     * The user signup schema, only handles the user-input side of the
     * information required.
     */
    const userSignUpStructure: kleen.objectSchema = {
      objectProperties: {
        name: {
          primitiveType: kleen.kindOfPrimitive.string,
          typeFailureError: {
            message: "Name must be a string!",
            errorCode: ErrorCode.invalidName
          },
          restriction: (name: string) => {
            if(name === "") {
              return Promise.reject({
                message: "Name cannot be empty!",
                errorCode: ErrorCode.invalidName
              });
            }
          }
        },
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
      typeFailureError: internalError("User object must have just email and password")
    };

    const newUser: UserForRegistration = {
      name: req.body.name,
      email,
      password
    };

    return kleen.validModel(userSignUpStructure)(newUser)
    .then(() => {
      // Set default new user fields and then register user.
      newUser.bio = "";
      return register(newUser);
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
  }
);

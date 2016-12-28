/// <reference path="../typings_manual/index.d.ts" />

import assert from 'assert';
import R from "ramda";

import { validPhone, validEmail, validPassword, validMongoID } from '../src/validifier';


describe('Validifier', function() {

  describe('#validPhone', function() {

    it('should return false if the email is undefined', function() {
      assert.equal(false, validPhone(undefined));
    });

    it('should return false if the email is null', function() {
      assert.equal(false, validPhone(null));
    });

    it('should return false if the phone number contains a char', function() {
      assert.equal(false, validPhone("604343a232"));
    });

    it('should return false if the phone number is 1 char', function() {
      assert.equal(false, validPhone("1"));
    });

    it('should return true if a valid phone number is passed', function() {
      const validPhoneNumbers = ["6049822922", "23222", "123456789012345"];

      R.map((validPhoneNumber) => {
        assert.equal(true, validPhone(validPhoneNumber));
      }, validPhoneNumbers);
    });

    it('should return false if a phone number is longer than 15 chars', function() {
      assert.equal(false, validPhone("1234567890123456"));
    });
  });

  describe('#validEmail', function() {

    it('should return false if the email is undefined', function() {
      assert.equal(false, validEmail(undefined));
    });

    it('should return false if the email is null', function() {
      assert.equal(false, validEmail(null));
    });

    it('should return false if the email has no @', function() {
      const invalidEmails = ["asdf", "asdf.gmail.com", "asdfATgmail.com"];

      R.map((email) => {
        assert.equal(false, validEmail(email));
      }, invalidEmails);
    });

    it('should return false if the email ends with an @', function() {
      const invalidEmail = "bla@";

      assert.equal(false, validEmail(invalidEmail));
    });

    it('should return false if the email starts with an @', function() {
      const invalidEmail = "@gmail.com";

      assert.equal(false, validEmail(invalidEmail));
    });

    it('should return true for valid emails', function() {
      const validEmails = ["bla@gmail.com", "bilbo@yahoo.ca", "what_what@b.ca"];

      R.map((email) => {
        assert.equal(true, validEmail(email));
      }, validEmails);
    });
  });

  describe('#validPassword', function() {

    it('should return false if the password is undefined', function() {
      assert.equal(false, validPassword(undefined));
    });

    it('should return false if the password is null', function() {
      assert.equal(false, validPassword(null));
    });

    it('should return false if the password is <= 6 chars', function() {
      assert.equal(false, validPassword("123456"));
    });
  });

  describe('#validMongoID', function() {

    it('should return false if the ID is undefined', function() {
      assert.equal(false, validMongoID(undefined));
    });

    it('should return false if the ID is null', function() {
      assert.equal(false, validMongoID(null));
    });

    it('should return false if the ID is not 24 hex chars', function() {
      const invalidMongoIDs = ["23", "12345678901234567890123-", "12345678901234567890123G"];

      R.map((invalidMongoID) => {
        assert.equal(false, validMongoID(invalidMongoID));
      }, invalidMongoIDs);
    });

    it('should return true if the ID is 24 hex chars ', function() {
      const validMongoIDs = ["123456789012345678901234", "12a456F890a2345d78901234"];

      R.map((aValidMongoID) => {
        assert.equal(true, validMongoID(aValidMongoID));
      }, validMongoIDs);
    });
  });
});

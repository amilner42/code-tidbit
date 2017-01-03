'use strict';

// Must require all scss.
require("./Styles/global.scss");
require("./Styles/mixins.scss");
require("./Styles/variables.scss");

require("./Components/Styles.scss");
require("./Components/Home/Styles.scss");
require("./Components/Welcome/Styles.scss");

require("./Elements/Editor.scss")

// Require index.html so it gets copied to dist
require('./index.html');

var Elm = require('./Main.elm');
var mountNode = document.getElementById('main');
var app = Elm.Main.embed(mountNode); // The third value on embed are the initial values for incomming ports into Elm
var modelKey = "model"; // The key for the model in localStorage.
var aceCodeEditor;

// Saves the model to local storage.
app.ports.saveModelToLocalStorage.subscribe(function(model) {
  localStorage.setItem(modelKey, JSON.stringify(model));
});

// Load the model from localStorage and send message to subscription over
// port.
app.ports.loadModelFromLocalStorage.subscribe(function() {
  // Send the item or a blank string if nothing there...elm doesn't like when
  // you send null through the port because we say it expects a string.
  app.ports.onLoadModelFromLocalStorage.send(localStorage.getItem(modelKey) || "")
});

// Creates the code edtior by embedding into the element with id `idName`.
app.ports.createCodeEditor.subscribe(function(idName) {
  aceCodeEditor = ace.edit(idName);
});

// If a code editor exists, set it's language to the given langLocation. Use
// helper provided in `Editor.elm` to turn a Language into a langLocation.
app.ports.setCodeEditorLanguage.subscribe(function(langLocation) {
  if(aceCodeEditor) {
    aceCodeEditor.getSession().setMode(langLocation);
  }
});

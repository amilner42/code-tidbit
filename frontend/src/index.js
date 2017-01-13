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
var aceCodeEditors = {}; // Dictionary, id names mapped to ace editors.


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

// Creates the code edtior by embedding into the element with the correct id.
//
// @refer Ports.elm
app.ports.createCodeEditor.subscribe(function(editorConfig) {
  setTimeout(() => {
    // We only create the editor if that DOM element exists.
    if(document.getElementById(editorConfig.id) !== null) {
      const aceCodeEditor = ace.edit(editorConfig.id);
      const editorSelection = aceCodeEditor.getSelection();

      // Set theme and language.
      aceCodeEditor.getSession().setMode(editorConfig.lang || "ace/mode/text");
      aceCodeEditor.setTheme(editorConfig.theme || "ace/theme/monokai");

      // Set the value of the editor the last saved value. `-1` here sets the
      // cursor to the first line...yes the API is undocumented...
      aceCodeEditor.setValue(editorConfig.value, -1);

      // Focus the editor.
      aceCodeEditor.focus();

      // Watch for selection changes.
      editorSelection.on("changeSelection", () => {
        // Directly from the ACE api.
        const aceSelectionRange = aceCodeEditor.getSelectionRange();

        // Set to match the elm port.
        const elmSelectedRange = {
          startRow : aceSelectionRange.start.row,
          startCol : aceSelectionRange.start.column,
          endRow : aceSelectionRange.end.row,
          endCol : aceSelectionRange.end.column
        };

        // Update the port with the new selection.
        app.ports.onCodeEditorSelectionUpdate.send({
          id: editorConfig.id,
          range: elmSelectedRange
        });
      });

      aceCodeEditor.on("change", (someObject) => {
        app.ports.onCodeEditorUpdate.send({
          id: editorConfig.id,
          value: aceCodeEditor.getValue()
        });
      });

      // We save the editor in case future interaction with the editor is required.
      aceCodeEditors[editorConfig.id] = aceCodeEditor;
    }
  }, 50);
});

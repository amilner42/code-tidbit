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

// Creates the code editor by embedding into the element with the correct id.
// The code editor must be wrapped in a div with id `code-editor-wrapper`.
//
// @refer Ports.elm
app.ports.createCodeEditor.subscribe(function(editorConfig) {
  setTimeout(() => {
    // We only create the editor if that DOM element exists.
    if(document.getElementById(editorConfig.id) !== null) {
      // Here because Elm doesn't always delete nodes when we need it
      // (because its virtual DOM is unaware of the editor and trying to
      // minimize changes to the DOM), we manually delete the last div and
      // put in a new div with the correct `id`. This ensures that every time
      // we create a new ace editor it is indeed a new editor.
      // TODO It may be possible to do this in Elm with Html.Keyed to force it
      //      to delete the old DOM node.
      const parentCodeWrapperDiv = document.getElementById("code-editor-wrapper");
      const codeEditorDiv = document.getElementById(editorConfig.id);
      const newBlankDiv = document.createElement("div");
      newBlankDiv.id = editorConfig.id;
      parentCodeWrapperDiv.replaceChild(newBlankDiv, codeEditorDiv);

      // If old editor exists, destroy it, this is a MUST, otherwise the event
      // listeners stay and get called multiple times.
      if(aceCodeEditors[editorConfig.id]) {
        aceCodeEditors[editorConfig.id].destroy();
      }

      // Create new editor.
      const aceCodeEditor = ace.edit(editorConfig.id);
      const editorSelection = aceCodeEditor.getSelection();

      // Set theme and language.
      aceCodeEditor.getSession().setMode(editorConfig.lang || "ace/mode/text");
      aceCodeEditor.setTheme(editorConfig.theme || "ace/theme/monokai");

      // Set the value of the editor the last saved value. `-1` here sets the
      // cursor to the first line...yes the API is undocumented...
      aceCodeEditor.setValue(editorConfig.value, -1);

      // If a range is passed, we need to highlight that part of the code.
      if(editorConfig.range) {

        // Range converted to ace format.
        const aceRange = {
          start: {
            row: editorConfig.range.startRow,
            column: editorConfig.range.startCol
          },
          end: {
            row: editorConfig.range.endRow,
            column: editorConfig.range.endCol
          }
        };

        aceCodeEditor.getSelection().setSelectionRange(aceRange, false);
      }

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

      // We save the editor in case future interaction with the editor is
      // required. It's also worth noting that we need to `.destroy()` the old
      // editor every time we create a new one so we also need to save the
      // editor here for that purpose.
      aceCodeEditors[editorConfig.id] = aceCodeEditor;
    }
  }, 50);
});

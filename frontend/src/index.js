'use strict';

// Must require all scss.
require("./Styles/global.scss");
require("./Styles/mixins.scss");
require("./Styles/variables.scss");

require("./Components/Styles.scss");
require("./Components/Home/Styles.scss");
require("./Components/Welcome/Styles.scss");

require("./Elements/Editor.scss")
require("./Elements/FileStructure.scss")
require("./Elements/Markdown.scss")

// Require index.html so it gets copied to dist
require('./index.html');
var AceRange = ace.require('ace/range').Range;

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

// Helper for getting elements scroll offset, @refer: https://jsfiddle.net/s61x7c4e/
function getElementY(querySelector) {
  var element = document.querySelector(querySelector);

  // If element not found, we don't want an error, we just want to not scroll.
  // This has been modified from the jsfiddle (they just errored).
  if(!element) {
    return window.pageYOffset;
  }

  return window.pageYOffset + element.getBoundingClientRect().top;
}

// For smooth scrolling, @refer: https://jsfiddle.net/s61x7c4e/
app.ports.doScrolling.subscribe(function(scrollConfig) {
  setTimeout(() => {
    var startingY = window.pageYOffset;
    var elementY = getElementY(scrollConfig.querySelector);
    // If element is close to page's bottom then window will scroll only to some position above the element.
    var targetY = document.body.scrollHeight - elementY < window.innerHeight ? document.body.scrollHeight - window.innerHeight : elementY;
    var diff = targetY - startingY;
    // Easing function: easeInOutCubic
    // From: https://gist.github.com/gre/1650294
    var easing = function (t) {
      return t<.5 ? 4*t*t*t : (t-1)*(2*t-2)*(2*t-2)+1
    };

    var start;

    if (!diff) {
      return;
    }

    // Bootstrap our animation - it will get called right before next frame shall be rendered.
    window.requestAnimationFrame(function step(timestamp) {
      if (!start) {
        start = timestamp
      }
      // Elapsed miliseconds since start of scrolling.
      var time = timestamp - start;
    // Get percent of completion in range [0, 1].
      var percent = Math.min(time / scrollConfig.duration, 1);
      // Apply the easing.
      // It can cause bad-looking slow frames in browser performance tool, so be careful.
      percent = easing(percent);

      window.scrollTo(0, startingY + diff * percent);

    // Proceed with animation as long as we wanted it to.
      if (time < scrollConfig.duration) {
        window.requestAnimationFrame(step)
      };
    });
  }, 0);
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
      // Due to bug in the editor, you have to call resize upon creation.
      aceCodeEditor.resize(true);
      const editorSelection = aceCodeEditor.getSelection();

      // Turns off the auto-linting, we may want to turn this on in the future
      // but because it's only for a few languages and it ends up being annoying
      // if you're just doing an incomplete snippet, probably not...
      aceCodeEditor.getSession().setUseWorker(false);

      // Set theme and language.
      aceCodeEditor.getSession().setMode(editorConfig.lang || "ace/mode/text");
      aceCodeEditor.setTheme(editorConfig.theme || "ace/theme/monokai");

      // Set the value of the editor the last saved value. `-1` here sets the
      // cursor to the first line...yes the API is undocumented...
      aceCodeEditor.setValue(editorConfig.value, -1);

      // If a range is passed, we need to highlight that part of the code.
      if(editorConfig.range) {

        // Range converted to ace format.
        const aceRange = new AceRange(
          editorConfig.range.startRow,
          editorConfig.range.startCol,
          editorConfig.range.endRow,
          editorConfig.range.endCol
        );

        // If it's readOnly we add a marker, that way it doesn't dissapear on a
        // new selection, if it's not readOnly then the user is creating it and
        // we just use selections so they can change what they wanna highlight.
        if(editorConfig.readOnly) {
          aceCodeEditor.session.addMarker(aceRange, "highlight-marker", "background", true);
        } else {
          aceCodeEditor.getSelection().setSelectionRange(aceRange, false);
        }

        // scrollToLine(Number line, Boolean center, Boolean animate, Function callback)
        aceCodeEditor.scrollToLine(editorConfig.range.endRow, true, true);
      }

      // Focus the editor.
      //   aceCodeEditor.focus();

      aceCodeEditor.setReadOnly(editorConfig.readOnly);

      // Watch for selection changes.
      editorSelection.on("changeSelection", () => {
        if(editorConfig.selectAllowed) {
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
        } else {
          aceCodeEditor.getSession().selection.clearSelection();
        }
      });

      aceCodeEditor.on("change", (someObject) => {
        // The action, "insert" or "remove", let's us know what happened because
        // the range always has the start row be the smaller of the two.
        const action = someObject.action;

        // Delta range from last change. Start row is always smaller than end
        // row as per usual with the ACE API.
        const deltaRange = {
          "startRow": someObject.start.row,
          "startCol": someObject.start.column,
          "endRow": someObject.end.row,
          "endCol": someObject.end.column
        };

        // New value of code editor.
        const value = aceCodeEditor.getValue();

        // Editor of current ID.
        const id = editorConfig.id;

        app.ports.onCodeEditorUpdate.send({ id, value, deltaRange, action });
      });

      // We save the editor in case future interaction with the editor is
      // required. It's also worth noting that we need to `.destroy()` the old
      // editor every time we create a new one so we also need to save the
      // editor here for that purpose.
      aceCodeEditors[editorConfig.id] = aceCodeEditor;
    }
  }, 100);
});

// Jumps to a specific line, both putting the cursor there and scrolling it
// into view.
app.ports.codeEditorJumpToLine.subscribe(function(jumpToLineConfig) {
  const aceCodeEditor = aceCodeEditors[jumpToLineConfig.id];

  if(aceCodeEditor) {
    aceCodeEditor.gotoLine(jumpToLineConfig.lineNumber, 0, true);
    aceCodeEditor.focus();
  }
});

'use strict';

// Must require all scss.
require("./Styles/global.scss");
require("./Styles/mixins.scss");
require("./Styles/variables.scss");

require("./Pages/Browse/Styles.scss");
require("./Pages/Create/Styles.scss");
require("./Pages/CreateBigbit/Styles.scss");
require("./Pages/CreateSnipbit/Styles.scss");
require("./Pages/DevelopStory/Styles.scss");
require("./Pages/NewStory/Styles.scss");
require("./Pages/Profile/Styles.scss");
require("./Pages/Styles.scss");
require("./Pages/ViewBigbit/Styles.scss");
require("./Pages/ViewSnipbit/Styles.scss");
require("./Pages/ViewStory/Styles.scss");
require("./Pages/Welcome/Styles.scss");

require("./Elements/ContentBox.scss");
require("./Elements/Editor.scss");
require("./Elements/FileStructure.scss");
require("./Elements/Markdown.scss");
require("./Elements/ProgressBar.scss");
require("./Elements/Tags.scss");

// Require index.html so it gets copied to dist
require('./index.html');
var AceRange = ace.require('ace/range').Range;

var Elm = require('./Main.elm');
var mountNode = document.getElementById('main');
var app = Elm.Main.embed(mountNode); // The third value on embed are the initial values for incomming ports into Elm
var modelKey = "model"; // The key for the model in localStorage.
var aceCodeEditors = {}; // Dictionary, id names mapped to ace editors.
var aceCodeEditorsUndoManager = {}; // Stores the undoManager for editors.

// Event handler for scrolling.
//
// Currently this event handles:
//  1. Adding/removing "sticky" class to "sub-bar" and adding/removing "hidden"
//     class to "sub-bar-ghost" depending on scroll position.
window.addEventListener('scroll', function(e) {
  const yPos = window.scrollY || 0;
  const globalHeaderHeight = 50;
  const subBar = document.querySelector(".sub-bar");
  const subBarGhost = document.querySelector(".sub-bar-ghost");

  // Element may not be on page.
  if(subBar && subBarGhost) {

    if(yPos > globalHeaderHeight) {
      subBar.classList.add("sticky");
      subBarGhost.classList.remove("hidden");
      return;
    }

    subBar.classList.remove("sticky");
    subBarGhost.classList.add("hidden");
    return;
  }
});

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
    var goalY = elementY + scrollConfig.extraScroll;
    var maxPossibleY = document.body.scrollHeight - window.innerHeight;
    var targetY = Math.min(goalY, maxPossibleY);
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
  }, 100);
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
      aceCodeEditor.renderer.setScrollMargin(0, 570, 0, 25);
      aceCodeEditor.renderer.setPrintMarginColumn(77); // Slightly under 80 becauase of scroll bar.
      aceCodeEditor.$blockScrolling = Infinity; // Prevents a default logging message.

      // Turns off the auto-linting, we may want to turn this on in the future
      // but because it's only for a few languages and it ends up being annoying
      // if you're just doing an incomplete snippet, probably not...
      aceCodeEditor.getSession().setUseWorker(false);

      // Set theme and language.
      aceCodeEditor.getSession().setMode(editorConfig.lang || "ace/mode/text");
      aceCodeEditor.setTheme(editorConfig.theme || "ace/theme/monokai");

      // Set the value of the editor the last saved value. `-1` here sets the
      // cursor to the first line...yes the API is undocumented...
      // This also resets the undo-manager.
      aceCodeEditor.session.setValue(editorConfig.value, -1);

      // We check if we have an undo manager saved for that editor, if we do,
      // we load it up so the user can save their undo-history even when they
      // switch frames.
      const lastUndoManager = aceCodeEditorsUndoManager[editorConfig.id];
      if(lastUndoManager
          && lastUndoManager.code === editorConfig.value
          && lastUndoManager.file === editorConfig.fileID ) {
        const newUndoManager = lastUndoManager.undoManager;
        newUndoManager.$doc = aceCodeEditor.session;
        aceCodeEditor.getSession().setUndoManager(newUndoManager);
      }

      // If a range is passed, we need to highlight that part of the code.
      if(editorConfig.range) {

        // Range converted to ace format.
        const aceRange = new AceRange(
          editorConfig.range.startRow,
          editorConfig.range.startCol,
          editorConfig.range.endRow,
          editorConfig.range.endCol
        );

        // Makes sure to compare relative to position of (0,0).
        const getPixelCoordinatesForPosition = (row, col) => {
          const originCoordinates = aceCodeEditor.renderer.textToScreenCoordinates(0, 0);
          const currentCoordinates = aceCodeEditor.renderer.textToScreenCoordinates(row, col);
          return [currentCoordinates.pageX - originCoordinates.pageX, currentCoordinates.pageY - originCoordinates.pageY ]
        }

        // Centers a specific range, contains logic for centering the range
        // intelligently.
        const centerRange = (startRow, startCol, endRow, endCol) => {

          const [startXCoordinate, startYCoordinate] = getPixelCoordinatesForPosition(startRow, startCol);
          const [endXCoordinate, endYCoordinate] = getPixelCoordinatesForPosition(endRow, endCol);
          const scrollWidth = aceCodeEditor.renderer.$size.scrollerWidth - 30; // -30 cause of scroll bar.

          const getXCoordinate = () => {
            return Math.max(0, (() => {
              const rangeWidth = endXCoordinate - startXCoordinate;

              // Handle single-row range-centering.
              if(startRow === endRow) {
                if(rangeWidth < scrollWidth) {
                  // If it's completely on-screen, just stay at the start.
                  if(endXCoordinate <= scrollWidth) {
                    return 0;
                  }

                  // Otherwise, center it's center.
                  return ((endXCoordinate + startXCoordinate) / 2) - (scrollWidth / 2);
                }

                // If it's a big range that starts anywhere in the first 1/2 of the
                // screen then just keep it at the start.
                if(startXCoordinate < (0.5 * scrollWidth)) {
                  return 0;
                }

                // Otherwise scroll to just a bit before the range.
                return startXCoordinate - 10;
              }

              // Handle multi-row range-centering.

              // If the start is insight at all, just keep it at the start.
              if(startXCoordinate < scrollWidth) {
                return 0;
              }

              // Otherwise scroll to just a bit before the range.
              return startXCoordinate - 10;
            })());
          };

          // Scroll vertical length, will attempt to center top-line vertically.
          aceCodeEditor.scrollToLine(startRow, true, true);
          // Scroll to horizontal coordinate.
          aceCodeEditor.renderer.scrollToX(getXCoordinate());
        };


        // If it's readOnly we add a marker, that way it doesn't dissapear on a
        // new selection, if it's not readOnly then the user is creating it and
        // we just use selections so they can change what they wanna highlight.
        if(editorConfig.readOnly) {
          aceCodeEditor.session.addMarker(aceRange, "highlight-marker", "background", true);
        } else {
          aceCodeEditor.getSelection().setSelectionRange(aceRange, false);
        }
        // Centers appropriately for the given range.
        centerRange(
          editorConfig.range.startRow,
          editorConfig.range.startCol,
          editorConfig.range.endRow,
          editorConfig.range.endCol
        );
      }

      // Focus the editor.
      //   aceCodeEditor.focus();

      aceCodeEditor.setReadOnly(editorConfig.readOnly);

      // Watch for selection changes.
      aceCodeEditor.getSelection().on("changeSelection", () => {
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

      aceCodeEditor.on("change", (delta) => {
        // The action, "insert" or "remove", let's us know what happened because
        // the range always has the start row be the smaller of the two.
        const action = delta.action;

        // Delta range from last change. Start row is always smaller than end
        // row as per usual with the ACE API.
        const deltaRange = {
          "startRow": delta.start.row,
          "startCol": delta.start.column,
          "endRow": delta.end.row,
          "endCol": delta.end.column
        };

        // New value of code editor.
        const value = aceCodeEditor.getValue();

        // Editor of current ID.
        const id = editorConfig.id;

        app.ports.onCodeEditorUpdate.send({ id, value, deltaRange, action });

        // Update our saved undo manager.
        aceCodeEditorsUndoManager[editorConfig.id] = {
          code: value,
          undoManager: aceCodeEditor.getSession().getUndoManager(),
          file: editorConfig.fileID
        };
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

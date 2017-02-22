port module Ports exposing (..)

import Json.Encode as Encode
import Models.Range exposing (Range)


{-| Saves the model to localstorage.
-}
port saveModelToLocalStorage : Encode.Value -> Cmd msg


{-| Loads the model from local storage.
-}
port loadModelFromLocalStorage : () -> Cmd msg


{-| Scroll to element.

@param querySelector For finding the element
@param duration Number of milliseconds for scroll to take.
-}
port doScrolling : { querySelector : String, duration : Int } -> Cmd msg


{-| Upon loading the model from local storage.
-}
port onLoadModelFromLocalStorage : (String -> msg) -> Sub msg


type alias CreateCodeEditorConfig =
    { id : String
    , lang : String
    , theme : String
    , value : String
    , range : Maybe Range
    , readOnly : Bool
    , selectAllowed : Bool
    }


{-| Finds the dom element with the given class name and replaces it with the
ace code editor.
-}
port createCodeEditor : CreateCodeEditorConfig -> Cmd msg


type alias CodeEditorJumpToLineConfig =
    { id : String
    , lineNumber : Int
    }


{-| For jumping (and scrolling) to a specific line in the code editor.
-}
port codeEditorJumpToLine : CodeEditorJumpToLineConfig -> Cmd msg


{-| Called when a code editor being used (with id `id`) has been updated.
-}
port onCodeEditorUpdate :
    ({ id : String, value : String, deltaRange : Range, action : String } -> msg)
    -> Sub msg


{-| Called when a code editor being used (with id `id`) has a new
selection, it will not be called if the selection has no range (the start
is the end).
-}
port onCodeEditorSelectionUpdate :
    ({ id : String, range : Range } -> msg)
    -> Sub msg

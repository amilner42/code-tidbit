port module Ports exposing (..)

import Json.Encode as Encode
import Models.Range exposing (Range)


{-| Saves the model to localstorage.
-}
port saveModelToLocalStorage : Encode.Value -> Cmd msg


{-| Loads the model from local storage.
-}
port loadModelFromLocalStorage : () -> Cmd msg


{-| Upon loading the model from local storage.
-}
port onLoadModelFromLocalStorage : (String -> msg) -> Sub msg


{-| Finds the dom element with the given class name and replaces it with the
ace code editor.
-}
port createCodeEditor :
    { id : String
    , lang : String
    , theme : String
    , value : String
    , range : Maybe Range
    }
    -> Cmd msg


{-| Called when a code editor being used (with id `id`) has been updated.
-}
port onCodeEditorUpdate :
    ({ id : String, value : String } -> msg)
    -> Sub msg


{-| Called when a code editor being used (with id `id`) has a new
selection, it will not be called if the selection has no range (the start
is the end).
-}
port onCodeEditorSelectionUpdate :
    ({ id : String, range : Range } -> msg)
    -> Sub msg

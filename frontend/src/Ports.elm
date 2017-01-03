port module Ports exposing (..)

import Json.Encode as Encode


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
port createCodeEditor : String -> Cmd msg


{-| Sets the language for the current editor.
-}
port setCodeEditorLanguage : String -> Cmd msg

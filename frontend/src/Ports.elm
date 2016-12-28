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
